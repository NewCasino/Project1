using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.Hosting;
using BLToolkit.DataAccess;
using CM.Content;
using CM.db.Accessor;
using GamMatrix.Infrastructure;

namespace CM.Sites
{
    [Serializable]
    public class DDOSRedirectorSetting
    {
        public string DomainName { get; set; }
        public int DomainID { get; set; }
        public bool Flag { get; set; }
    }
    public class DDOSRedirector
    {
        private static string _FilePath = HostingEnvironment.MapPath("~/Views/System/.config/MaintenanceSetting.dat");
        private static string _CacheKey = "MaintenancePage_Setting";

        public static void Save(List<int> domainIDs)
        {
            if (domainIDs != null)
            {
                ObjectHelper.BinarySerialize<List<int>>(domainIDs, _FilePath);
            }
        }

        public static bool Get(int domainID)
        {
            List<int> lstDomain = HttpRuntime.Cache[_CacheKey] as List<int>;
            if (lstDomain == null)
            {
                lstDomain = PopulateData();
            }

            if (lstDomain != null)
            {
                return lstDomain.Exists(d => d == domainID);
            }
            return false;
        }

        public static bool Handle(int domainID)
        {
            try
            {
                if (Get(domainID))
                {
                    if (!string.IsNullOrWhiteSpace(ConfigurationManager.AppSettings["DDOSAttack.Redirection.Url"]))
                    {
                        var lang = SiteManager.Current.GetCurrentLanguage();
                        HttpContext.Current.Response.StatusCode = 302;
                        HttpContext.Current.Response.AddHeader("Location",
                            string.Format("{0}?supportemail={1}&name={2}&lang={3}"
                                ,ConfigurationManager.AppSettings["DDOSAttack.Redirection.Url"]
                                , HttpUtility.UrlEncode(Metadata.Get("/Metadata/Settings.Email_SupportAddress", SiteManager.Current.DefaultCulture))
                                , HttpUtility.UrlEncode(SiteManager.Current.DistinctName)
                                , lang != null ? lang.LanguageCode : SiteManager.Current.DefaultCulture
                                ));
                        return true;
                    }
                }
                return false;
            }
            catch (Exception ex){
                Logger.Exception(ex);
                return false;
            }
        }

        public static List<DDOSRedirectorSetting> GetAll()
        {
            SiteAccessor ua = DataAccessor.CreateInstance<SiteAccessor>();
            List<DDOSRedirectorSetting> lstDomain = new List<DDOSRedirectorSetting>();

            Dictionary<int, string> dicDomain = ua.GetActiveDomains();
            List<int> lstSelectedDomain = HttpRuntime.Cache[_CacheKey] as List<int>;
            if (lstSelectedDomain==null)
                lstSelectedDomain = PopulateData();

            foreach (int k in dicDomain.Keys)
            {
                if (string.Compare("System", dicDomain[k], true) == 0)
                    continue;
                bool flag = false;
                if (lstSelectedDomain != null && lstSelectedDomain.Contains<int>(k))
                    flag = true;
                lstDomain.Add(new DDOSRedirectorSetting() { DomainName = dicDomain[k], DomainID = k, Flag = flag });
            }
            return lstDomain.OrderBy(d => d.DomainName).ToList();
        }

        private static List<int> PopulateData()
        {
            List<int> lstDomains = null;
            if (File.Exists(_FilePath))
            {
                lstDomains = ObjectHelper.BinaryDeserialize<List<int>>(_FilePath, new List<int>()) as List<int>;

                HttpRuntime.Cache.Insert(
                    _CacheKey,
                    lstDomains,
                    GetCacheDependency());
            }
            return lstDomains;
        }


        private static CacheDependencyEx GetCacheDependency()
        {
            return new CacheDependencyEx(new string[] { _FilePath }, false);
        }
    }
}
