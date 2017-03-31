using System;
using System.Collections.Generic;
using System.Web;
using System.Web.Caching;
using System.Web.Hosting;
using CM.Content;
using CM.db;
using GamMatrix.Infrastructure;

namespace CM.Sites
{
    [Serializable] 
    public sealed class SiteRestrictDomainRule
    {
        public bool IsDomainRestrictedMode { get; set; }
        public string MainDomainName { get; set; }
        public List<string> EnabledDomainList { get; set; }
        public List<string> DisabledDomainList { get; set; }

        public static SiteRestrictDomainRule Get(string distinctName, bool useCache = true)
        {
            string filePath = string.Format("~/Views/{0}/.config/SiteDomainRule", distinctName);
            filePath = HostingEnvironment.MapPath(filePath );
            SiteRestrictDomainRule cached = HttpRuntime.Cache[filePath] as SiteRestrictDomainRule;
            if (useCache && cached != null)
                return cached;

            cached = ObjectHelper.BinaryDeserialize<SiteRestrictDomainRule>(filePath, new SiteRestrictDomainRule());

            HttpRuntime.Cache.Insert(filePath
                , cached
                , new CacheDependencyEx(new string[] { filePath }, false)
                , Cache.NoAbsoluteExpiration
                , Cache.NoSlidingExpiration
                , CacheItemPriority.NotRemovable
                , null
                );
            return cached;

        }
        public void Save(cmSite site, SiteRestrictDomainRule rule)
        {
            string filePath = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/SiteDomainRule", site.DistinctName));

            string relativePath = "/.config/site_domain_access_rule.setting";
            string name = "Domain Access Control";

            Revisions.BackupIfNotExists(site, filePath, relativePath, name);

            ObjectHelper.BinarySerialize<SiteRestrictDomainRule>(rule, filePath);

            Revisions.Backup(site, filePath, relativePath, name);
        }
    }
}
