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
    public sealed class SiteAccessRule
    {
        public bool IsWhitelistMode { get; set; }
        public Dictionary<string, string> IPAddresses { get; private set; }
        public string BlockedMessage { get; set; }
        public enum FilterType
        {
            Exclude,
            Include,
        }
        public FilterType CountriesFilterType { get; set; }
        public List<int> CountriesList { get; set; }

        public enum AccessModeType
        {
            NotSet,
            SoftLaunch,
            Whitelist,
            Blacklist,
        }
        public AccessModeType AccessMode { get; set; }
        public int SoftLaunchNumber { get; set; }


        public SiteAccessRule()
        {
            this.IPAddresses = new Dictionary<string, string>(StringComparer.InvariantCulture);
            this.CountriesFilterType = FilterType.Exclude;
        }

        public static SiteAccessRule Get(cmSite site, bool useCache = true)
        {

            string filePath = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/SiteAccessRule", site.DistinctName));
            SiteAccessRule cached = HttpRuntime.Cache[filePath] as SiteAccessRule;
            if (useCache && cached != null)
                return cached;

            cached = ObjectHelper.BinaryDeserialize<SiteAccessRule>(filePath, new SiteAccessRule());

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

        public void Save(cmSite site, SiteAccessRule rule, bool logChanges = true)
        {
            string filePath = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/SiteAccessRule", site.DistinctName));
            SiteAccessRule cached = HttpRuntime.Cache[filePath] as SiteAccessRule;

            string relativePath = "/.config/site_access_rule.setting";
            string name = "Access Control";

            cached = rule;
            HttpRuntime.Cache.Insert(filePath
            , cached
            , new CacheDependencyEx(new string[] { filePath }, false)
            , Cache.NoAbsoluteExpiration
            , Cache.NoSlidingExpiration
            , CacheItemPriority.NotRemovable
            , null
            );

            if (logChanges)
                Revisions.BackupIfNotExists(site, filePath, relativePath, name);

            ObjectHelper.BinarySerialize<SiteAccessRule>(rule, filePath);

            if (logChanges)
                Revisions.Backup(site, filePath, relativePath, name);
        }
    }
}
