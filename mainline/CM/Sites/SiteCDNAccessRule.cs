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
    public sealed class SiteCDNAccessRule
    {
        public Dictionary<string, string> IPAddresses { get; private set; }

        public SiteCDNAccessRule()
        {
            this.IPAddresses = new Dictionary<string, string>(StringComparer.InvariantCulture);
        }

        public static SiteCDNAccessRule Get(cmSite site, bool useCache = true)
        {
            string filePath = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/SiteCDNAccessRule", site.DistinctName));
            SiteCDNAccessRule cached = HttpRuntime.Cache[filePath] as SiteCDNAccessRule;
            if (useCache && cached != null)
                return cached;

            cached = ObjectHelper.BinaryDeserialize<SiteCDNAccessRule>(filePath, new SiteCDNAccessRule());

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

        public void Save(cmSite site, SiteCDNAccessRule rule)
        {
            string filePath = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/SiteCDNAccessRule", site.DistinctName));

            string relativePath = "/.config/site_cdn_access_rule.setting";
            string name = "CDN Access Control";

            Revisions.BackupIfNotExists(site, filePath, relativePath, name);

            ObjectHelper.BinarySerialize<SiteCDNAccessRule>(rule, filePath);

            Revisions.Backup(site, filePath, relativePath, name);
        }
    }
}
