using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Caching;

namespace CmsSanityCheck.Misc
{
    using DB.Accessor;
    using Model;

    public static class SiteManager
    {
        private static string _cacheKey = "sites.all";

        public static List<SiteAndHost> GetAll(Service service)
        {
            string cacheKey = string.Format("sites.all.{0}", service.Name);
            var siteAndHosts = (List<SiteAndHost>)MemoryCache.Default[cacheKey];
            if (siteAndHosts != null)
                return siteAndHosts;

            var cmSites = SiteAccessor.GetAll(service);
            var cmHosts = HostAccessor.GetAll(service);

            siteAndHosts = cmSites.Select(cmSite => new SiteAndHost()
                {
                    SiteID = cmSite.SiteID, 
                    DomainID = cmSite.DomainID, 
                    DisplayName = cmSite.DisplayName, 
                    HostNames = cmHosts.Where(h => h.SiteID == cmSite.SiteID).Select(h => h.HostName).ToList()
                }).ToList();
            siteAndHosts = siteAndHosts.Where(sh => sh.HostNames.Any()).OrderBy(sh => sh.DomainID).ToList();
            MemoryCache.Default.Add(new CacheItem(cacheKey, siteAndHosts), new CacheItemPolicy()
            {
                AbsoluteExpiration = DateTime.Now.AddHours(1)
            });
            return siteAndHosts;
        }
    }
}
