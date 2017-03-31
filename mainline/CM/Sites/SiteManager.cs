using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Web;
using System.Web.Caching;
using System.Web.Hosting;
using System.Web.Mvc;
using System.Web.Routing;
using System.Configuration;

using BLToolkit.DataAccess;
using CM.db;
using CM.db.Accessor;

namespace CM.Sites
{
    /// <summary>
    /// Site manager
    /// </summary>
    public static class SiteManager
    {
        /// <summary>
        /// class keeps site and host
        /// </summary>
        [Serializable]
        internal sealed class SiteAndHost
        {
            public cmSite Site { get; set; }
            public cmHost Host { get; set; }
        }

        /// <summary>
        /// Cache file for all site
        /// </summary>
        private const string ALL_SITES_CACHE_FILE = "~/App_Data/sites_cache.dat";

        /// <summary>
        /// Cache file for all hostnames
        /// </summary>
        private const string ALL_HOSTS_CACHE_FILE = "~/App_Data/hosts_cache.dat";

        /// <summary>
        /// Cache file for hostname to site dictionary
        /// </summary>
        private const string HOST_SITE_MAP_CACHE_FILE = "~/App_Data/hosts_sites_cache.dat";

        private static ConcurrentDictionary<string, SiteRouteInfo> s_DistinctName2DomainRouteInfo
            = new ConcurrentDictionary<string, SiteRouteInfo>(StringComparer.InvariantCultureIgnoreCase);

        private static readonly object s_UpdateSiteHostCacheLock = new object();

        public static bool ReloadSiteHostCache()
        {
            return InternalReloadSiteHostCache();
        }

        private static bool InternalReloadSiteHostCache()
        {
            bool success = false;
            if (Monitor.TryEnter(s_UpdateSiteHostCacheLock))
            {
                try
                {
                    SiteAccessor da = DataAccessor.CreateInstance<SiteAccessor>();
                    string filePath = HostingEnvironment.MapPath(ALL_SITES_CACHE_FILE);
                    List<cmSite> sites = da.GetAll();
                    if (sites.Count > 0)
                    {
                        ObjectHelper.BinarySerialize<List<cmSite>>(sites, filePath);
                        HttpRuntime.Cache.Insert(ALL_SITES_CACHE_FILE
                            , sites
                            , new CacheDependency(filePath)
                            , Cache.NoAbsoluteExpiration
                            , Cache.NoSlidingExpiration
                            , CacheItemPriority.NotRemovable
                            , null
                            );
                    }

                    HostAccessor ha = DataAccessor.CreateInstance<HostAccessor>();
                    filePath = HostingEnvironment.MapPath(ALL_HOSTS_CACHE_FILE);
                    
                    List<cmHost> hosts = ha.GetAll();
                    if(!string.IsNullOrWhiteSpace(ConfigurationManager.AppSettings["Init.Debug.Sites"]))
                    {
                        //only loads the sites specificed from web.config & template sites, to speed the loading for debug
                        hosts = hosts.Where(h=> GetRootTemplateSites().Exists(s=>s.ID == h.SiteID) || GetDebugSites().Contains(h.SiteID)).ToList();
                    }
                    if (hosts.Count > 0)
                    {
                        ObjectHelper.BinarySerialize<List<cmHost>>(hosts, filePath);
                        HttpRuntime.Cache.Insert(ALL_HOSTS_CACHE_FILE
                            , hosts
                            , new CacheDependency(filePath)
                            , Cache.NoAbsoluteExpiration
                            , Cache.NoSlidingExpiration
                            , CacheItemPriority.NotRemovable
                            , null
                            );
                    }

                    
                    Dictionary<string, SiteAndHost> dictionary = new Dictionary<string, SiteAndHost>(StringComparer.InvariantCultureIgnoreCase);
                    foreach (cmHost host in hosts)
                    {
                        cmSite site = sites.FirstOrDefault(s => s.ID == host.SiteID);
                        if (site != null)
                        {
                            dictionary[host.HostName] = new SiteAndHost()
                            {
                                Site = site,
                                Host = host,
                            };
                        }
                    }
                    if (dictionary.Count > 0)
                    {
                        filePath = HostingEnvironment.MapPath(HOST_SITE_MAP_CACHE_FILE);
                        ObjectHelper.BinarySerialize<Dictionary<string, SiteAndHost>>(dictionary, filePath);
                        HttpRuntime.Cache.Insert(HOST_SITE_MAP_CACHE_FILE
                            , dictionary
                            , new CacheDependency(filePath)
                            , Cache.NoAbsoluteExpiration
                            , Cache.NoSlidingExpiration
                            , CacheItemPriority.NotRemovable
                            , null
                            );
                    }

                    success = true;
                }
                catch (Exception ex)
                {
                    Logger.Exception(ex);
                }
                finally
                {
                    Monitor.Exit(s_UpdateSiteHostCacheLock);
                }
            } 

            return success;
        }


        /// <summary>
        /// Get the domain by hostname
        /// </summary>
        /// <param name="hostName"></param>
        /// <returns></returns>
        internal static SiteAndHost GetByHostName(string hostName)
        {
            Dictionary<string, SiteAndHost> dictionary
                = HttpRuntime.Cache[HOST_SITE_MAP_CACHE_FILE] as Dictionary<string, SiteAndHost>;

            if (dictionary == null)
            {
                string filePath = HostingEnvironment.MapPath(HOST_SITE_MAP_CACHE_FILE);
                dictionary = ObjectHelper.BinaryDeserialize<Dictionary<string, SiteAndHost>>(filePath
                    , new Dictionary<string, SiteAndHost>()
                    );
            }

            SiteAndHost found = null;
            dictionary.TryGetValue(hostName, out found);
            return found;
        }

        /// <summary>
        ///  get the current site
        /// </summary>
        public static cmSite Current
        {
            get
            {
                return HttpContext.Current.Items["__current_domain"] as cmSite;
            }
            internal set
            {
                HttpContext.Current.Items["__current_domain"] = value;
            }
        }


        /// <summary>
        /// Returns all the domains
        /// </summary>
        /// <returns>Domains as List of cmSite</returns>
        public static List<cmSite> GetSites()
        {
            List<cmSite> sites = HttpRuntime.Cache[ALL_SITES_CACHE_FILE] as List<cmSite>;
            if( sites != null)
                return sites;

            string filePath = HostingEnvironment.MapPath(ALL_SITES_CACHE_FILE);
            sites = ObjectHelper.BinaryDeserialize<List<cmSite>>(filePath
                    , new List<cmSite>()
                    );
            HttpRuntime.Cache.Insert(ALL_SITES_CACHE_FILE
                        , sites
                        , new CacheDependency(filePath)
                        , Cache.NoAbsoluteExpiration
                        , Cache.NoSlidingExpiration
                        , CacheItemPriority.NotRemovable
                        , null
                        );
            return sites;
        }

        public static List<cmSite> GetRootTemplateSites()
        {

            return GetSites().Where(s => IsSiteRootTemplate(s.DistinctName)).ToList();
        }

        public static bool IsSiteRootTemplate(string distinctName)
        {
            return distinctName.Equals("Shared", StringComparison.InvariantCultureIgnoreCase) ||
                distinctName.Equals("MobileShared", StringComparison.InvariantCultureIgnoreCase);
        }

        /// <summary>
        /// Get the site by distinct name
        /// </summary>
        /// <param name="distinctName">distinct name of the site</param>
        /// <returns>Returns cmSite found by the name</returns>
        public static cmSite GetSiteByDistinctName(string distinctName)
        {
            return GetSites().FirstOrDefault(d => d.DistinctName == distinctName);
        }

        /// <summary>
        /// Returns all the host names
        /// </summary>
        /// <returns>returns all hosts</returns>
        public static List<cmHost> GetHosts()
        {
            List<cmHost> hosts = HttpRuntime.Cache[ALL_HOSTS_CACHE_FILE] as List<cmHost>;
            if (hosts != null)
                return hosts;

            string filePath = HostingEnvironment.MapPath(ALL_HOSTS_CACHE_FILE);
            hosts = ObjectHelper.BinaryDeserialize<List<cmHost>>(filePath
                    , new List<cmHost>()
                    );

            HttpRuntime.Cache.Insert(ALL_HOSTS_CACHE_FILE
                        , hosts
                        , new CacheDependency(filePath)
                        , Cache.NoAbsoluteExpiration
                        , Cache.NoSlidingExpiration
                        , CacheItemPriority.NotRemovable
                        , null
                        );

            return hosts;
        }


        private static void LoadSiteRouteInfo(object state)
        {
            SiteRouteInfo siteRouteInfo = state as SiteRouteInfo;
            siteRouteInfo.LoadConfigration();
        }

        /// <summary>
        /// This method is called when the app pool starts
        /// </summary>
        public static void InitialLoadConfiguration()
        {
            InternalReloadSiteHostCache();

            List<cmSite> sites = null;
            SiteRouteInfo siteRouteInfo = null;

            bool preloadRoot = ConfigurationManager.AppSettings["Init.PreloadRootTemplateSiteRouteInfo"].DefaultIfNullOrWhiteSpace("false").Equals("true", StringComparison.InvariantCultureIgnoreCase);
            if (preloadRoot)
            {
                // Load Root Template Sites' RouteInfo
                sites = GetRootTemplateSites();
                {
                    foreach (cmSite site in sites)
                    {
                        siteRouteInfo = new SiteRouteInfo(site);
                        LoadSiteRouteInfo(siteRouteInfo);
                    }
                }
                sites = GetSites().Where(s => !sites.Exists(rs => rs.ID == s.ID)).ToList();
            }
            else
            {
                sites = GetSites();
            }

            if (!string.IsNullOrWhiteSpace(ConfigurationManager.AppSettings["Init.Debug.Sites"]))
            {
                //only loads the sites specificed from web.config & template sites, to speed the loading for debug
                sites = GetSites().Where(s => GetRootTemplateSites().Exists(ts=>ts.ID == s.ID) || GetDebugSites().Contains(s.ID)).ToList();
            }

            foreach (cmSite site in sites)
            {
                siteRouteInfo = new SiteRouteInfo(site);
                s_DistinctName2DomainRouteInfo[site.DistinctName] = siteRouteInfo;

                BackgroundThreadPool.QueueUserWorkItem("InitialLoadConfiguration", new WaitCallback(LoadSiteRouteInfo), siteRouteInfo, true);
            }
        }

        /// <summary>
        /// Get the route info by site distinct name
        /// </summary>
        /// <param name="distinctName"></param>
        /// <returns></returns>
        public static SiteRouteInfo GetSiteRouteInfo(string distinctName)
        {
            SiteRouteInfo info;
            if (s_DistinctName2DomainRouteInfo.TryGetValue(distinctName, out info))
                return info;

            return null;
        }



        /// <summary>
        /// Extension method, reload configuration for special 
        /// </summary>
        /// <param name="site">site</param>
        /// <returns>SiteRouteInfo of this site</returns>
        public static SiteRouteInfo ReloadConfigration(this cmSite site)
        {
            // initialize DomainRouteInfo
            SiteRouteInfo siteRouteInfo = null;
            if (!s_DistinctName2DomainRouteInfo.TryGetValue(site.DistinctName, out siteRouteInfo))
            {
                siteRouteInfo = new SiteRouteInfo(site);
                s_DistinctName2DomainRouteInfo[site.DistinctName] = siteRouteInfo;
            }
            siteRouteInfo.LoadConfigration();
            return siteRouteInfo;
        }

        /// <summary>
        /// Extension method, returns route collection for special site
        /// </summary>
        /// <param name="domain">site</param>
        /// <returns>RouteCollection</returns>
        public static RouteCollection GetRouteCollection(this cmSite domain)
        {
            SiteRouteInfo domainRouteInfo;
            if (s_DistinctName2DomainRouteInfo.TryGetValue(domain.DistinctName, out domainRouteInfo))
                return domainRouteInfo.RouteCollection;

            return null;
        }


        /// <summary>
        /// Extension method, returns controller type for special route
        /// </summary>
        /// <param name="domain">site</param>
        /// <param name="routeBase">route</param>
        /// <returns>controller type</returns>
        public static Type GetControllerTypeByRoute(this cmSite domain, RouteBase routeBase)
        {
            SiteRouteInfo domainRouteInfo = null;
            if (s_DistinctName2DomainRouteInfo.TryGetValue(domain.DistinctName, out domainRouteInfo))
            {
                Route route = routeBase as Route;
                if( route != null )
                {
                    SiteRouteInfo.RouteExtraInfo routeExtraInfo = null;
                    if (domainRouteInfo.RouteExtraInfos.TryGetValue(route.DataTokens["RouteName"] as string, out routeExtraInfo))
                        return routeExtraInfo.ControllerType;
                }
            }
            return null;
        }

        /// <summary>
        /// Extension method, returns url for special route
        /// </summary>
        /// <param name="domain">site</param>
        /// <param name="routeBase">route</param>
        /// <returns>the url of the route</returns>
        public static string GetUrlByRoute(this cmSite domain, RouteBase routeBase)
        {
            SiteRouteInfo domainRouteInfo = null;
            if (!s_DistinctName2DomainRouteInfo.TryGetValue(domain.DistinctName, out domainRouteInfo))
            {
                return null;
            }

            Route route = routeBase as Route;
            if (route != null)
            {
                SiteRouteInfo.RouteExtraInfo routeExtraInfo = null;
                if (domainRouteInfo.RouteExtraInfos.TryGetValue(route.DataTokens["RouteName"] as string, out routeExtraInfo))
                    return routeExtraInfo.Url;
            }
            return null;
        }

		/// <summary>
		/// Returns the current site's absolute url
		/// </summary>
		/// <param name="urlHelper">UrlHelper extension method</param>
		/// <param name="language">the desired language</param>
		/// <returns></returns>
		public static string GetAbsoluteBaseUrl(this UrlHelper urlHelper, string language = null)
		{
			if (string.IsNullOrWhiteSpace(language))
				language = HttpContext.Current.GetLanguage();

			string url;
			if (SiteManager.Current.HttpsPort > 0)
			{
				url = string.Format("https://{0}:{1}/{2}"
					, HttpContext.Current.Request.Url.Host
					, SiteManager.Current.HttpsPort
					, language
					);
			}
			else
			{
				url = string.Format("http://{0}:{1}/{2}"
					, HttpContext.Current.Request.Url.Host
					, SiteManager.Current.HttpPort
					, language
					);
			}

			return url;
		}

        /// <summary>
        /// Extension method, return the url of route with abosulute path
        /// </summary>
        /// <param name="urlHelper">UrlHelper</param>
        /// <param name="routeName">route</param>
        /// <param name="routeValues">route values</param>
        /// <param name="language">language</param>
        /// <returns>the url</returns>
        public static string RouteUrlEx(this UrlHelper urlHelper, string routeName, object routeValues, string language = null)
        {
            return string.Format("{0}{1}"
				, GetAbsoluteBaseUrl(urlHelper, language)
                , urlHelper.RouteUrl(routeName, routeValues)
                );
        }

        public static string AbsoluteUrl(this UrlHelper urlHelper, string path, string language = null)
        {
			return string.Format("{0}{1}"
				, GetAbsoluteBaseUrl(urlHelper, language)
				, path
				);
        }

        private static int[] GetDebugSites()
        {
            if(!string.IsNullOrWhiteSpace(ConfigurationManager.AppSettings["Init.Debug.Sites"]))
            {
                return Array.ConvertAll<string,int>(ConfigurationManager.AppSettings["Init.Debug.Sites"].Split(new char[]{','}, StringSplitOptions.RemoveEmptyEntries), s=>int.Parse(s));
            }
            return null;
        }
    }
}
