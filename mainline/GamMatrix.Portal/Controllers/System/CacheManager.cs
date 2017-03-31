using System;
using System.Collections.Specialized;
using System.Configuration;
using System.IO;
using System.Net;
using System.Text;
using System.Web.Mvc;
using System.Web.Routing;
using CM.Content;
using CM.db;
using CM.Sites;
using CM.State;
using CasinoEngine;

namespace GamMatrix.CMS.Controllers.System
{
    /// <summary>
    /// Summary description for CacheManager
    /// </summary>
    public static class CacheManager
    {
        public enum CacheType
        {
            DomainCache = 0,
            CasinoGameCache = 1,
            MetadataCache = 2,
            CasinoGameCategoryCache = 3,
            PageTemplatePathCache = 4,
            RouteInfoCache = 5,
            CasinoEngineCache = 6,
        };


        /// <summary>
        /// 
        /// </summary>
        /// <returns>pair Server - success or failed</returns>
        internal static string ReloadCache(this cmSite site
            , RequestContext requestContext
            , CacheType cacheType
            )
        {
            StringBuilder sb = new StringBuilder();
            NameValueCollection servers = ConfigurationManager.GetSection("servers") as NameValueCollection;
            if (servers == null || servers.Count == 0)
                throw new Exception("Error, can not find the server configration.");

            UrlHelper urlHelper = new UrlHelper(requestContext, SiteManager.Current.GetRouteCollection());
            foreach (string serverName in servers.Keys)
            {
                try
                {
                    string url = string.Format("http://{0}{1}"
                        , servers[serverName]
                        , urlHelper.RouteUrl("Dashboard", new {  @_sid = CustomProfile.Current.SessionID, @action = "ReloadLocalCache", @distinctName = (site ?? SiteManager.Current).DistinctName, @cacheType = cacheType })
                        );
                    
                    HttpWebRequest request = HttpWebRequest.Create(url) as HttpWebRequest;
                    request.KeepAlive = false;
                    request.Method = "POST";
                    request.ProtocolVersion = Version.Parse("1.0");
                    request.ContentLength = 0;                    
                    request.AutomaticDecompression = DecompressionMethods.GZip | DecompressionMethods.Deflate;
                    request.CookieContainer = new CookieContainer();
                    request.CookieContainer.Add(new Uri(url), new Cookie(SiteManager.Current.SessionCookieName, CustomProfile.Current.SessionID));
                    request.Accept = "text/plain";
                    HttpWebResponse response = request.GetResponse() as HttpWebResponse;
                    string respText = null;
                    using (Stream stream = response.GetResponseStream())
                    {
                        using (StreamReader sr = new StreamReader(stream))
                        {
                            respText = sr.ReadToEnd();
                        }
                    }
                    response.Close();

                    Logger.Information("Cache", "ReloadCache {0} [{1}]", respText, url);

                    if( !string.Equals(respText, "OK", StringComparison.InvariantCultureIgnoreCase) )
                        sb.AppendFormat("\n[{0}] : {1}", serverName, respText);
                }
                catch (Exception ex)
                {
                    sb.AppendFormat("\n[{0}] : {1}", serverName, ex.Message);
                    Logger.Exception(ex);
                }
            }

            return sb.ToString();
        }


        public static void ReloadLocalCache(this cmSite site, CacheManager.CacheType cacheType, byte[] buffer)
        {
            switch (cacheType)
            {
                case CacheManager.CacheType.DomainCache:
                    SiteManager.ReloadSiteHostCache();
                    break;

                case CacheManager.CacheType.CasinoGameCache:
                    Casino.GameManager.ClearCache(site);
                    break;

                case CacheManager.CacheType.MetadataCache:
                    Metadata.ClearCache(site);
                    break;

                case CacheManager.CacheType.CasinoGameCategoryCache:
                    Casino.GameManager.ClearCategoryCache(site);
                    break;

                case CacheManager.CacheType.PageTemplatePathCache:
                    CM.Web.ViewPageEx.ClearMasterPageCache(site);
                    break;

                case CacheManager.CacheType.RouteInfoCache:
                    {
                        SiteRouteInfo route = SiteManager.GetSiteRouteInfo(site.DistinctName);
                        route.Load(buffer);
                    }
                    break;

                case CacheManager.CacheType.CasinoEngineCache:
                    CasinoEngineClient.ClearGamesCache(site.ID);
                    break;

            }
        }



        public static bool ReloadRouteTable(this cmSite site, RequestContext requestContext)
        {
            SiteRouteInfo route = SiteManager.GetSiteRouteInfo(site.DistinctName);
            if (route == null)
                return false;

            route.LoadConfigration();

            byte [] buffer;
            using( FileStream fs = new FileStream( route.GetCacheFilePath()
                , FileMode.Open
                , FileAccess.Read
                , FileShare.ReadWrite | FileShare.Delete) )
            {
                buffer = new byte[fs.Length];
                fs.Read( buffer, 0, buffer.Length);
                fs.Close();
            }
            StringBuilder sb = new StringBuilder();
            NameValueCollection servers = ConfigurationManager.GetSection("servers") as NameValueCollection;
            if (servers == null || servers.Count == 0)
                throw new Exception("Error, can not find the server configration.");

            UrlHelper urlHelper = new UrlHelper(requestContext, SiteManager.Current.GetRouteCollection());
            foreach (string serverName in servers.Keys)
            {
                try
                {
                    string url = string.Format("http://{0}{1}"
                        , servers[serverName]
                        , urlHelper.RouteUrl("Dashboard", new { @_sid = CustomProfile.Current.SessionID, @action = "ReloadLocalCache", @distinctName = site.DistinctName, @cacheType = CacheType.RouteInfoCache })
                        );

                    HttpWebRequest request = HttpWebRequest.Create(url) as HttpWebRequest;
                    request.KeepAlive = false;
                    request.Method = "POST";
                    request.ProtocolVersion = Version.Parse("1.0");
                    request.ContentLength = buffer.Length;
                    request.AutomaticDecompression = DecompressionMethods.GZip | DecompressionMethods.Deflate;
                    request.CookieContainer = new CookieContainer();
                    request.CookieContainer.Add(new Uri(url), new Cookie(SiteManager.Current.SessionCookieName, CustomProfile.Current.SessionID));
                    request.Accept = "text/plain";
                    using( Stream stream = request.GetRequestStream() )
                    {
                        stream.Write( buffer, 0, buffer.Length);
                    }

                    HttpWebResponse response = request.GetResponse() as HttpWebResponse;
                    string respText = null;
                    using (Stream stream = response.GetResponseStream())
                    {
                        using (StreamReader sr = new StreamReader(stream))
                        {
                            respText = sr.ReadToEnd();
                        }
                    }
                    response.Close();

                    Logger.Information("Cache", "ReloadCache {0} [{1}]", respText, url);

                    if (!string.Equals(respText, "OK", StringComparison.InvariantCultureIgnoreCase))
                        sb.AppendFormat("\n[{0}] : {1}", serverName, respText);
                }
                catch (Exception ex)
                {
                    sb.AppendFormat("\n[{0}] : {1}", serverName, ex.Message);
                    Logger.Exception(ex);
                    return false;
                }
            }

            return false;
        }

        
    }
}