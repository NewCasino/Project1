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
    public sealed class SiteHostMapping
    {
        public static Dictionary<string, string> Get(string distinctName, bool useCache = true)
        {
            string filePath = string.Format("~/Views/{0}/.config/SiteHostMapping", distinctName);
            filePath = HostingEnvironment.MapPath(filePath);
            Dictionary<string, string> cached = HttpRuntime.Cache[filePath] as Dictionary<string, string>;
            if (useCache && cached != null)
                return cached;

            cached = ObjectHelper.BinaryDeserialize<Dictionary<string, string>>(filePath, new Dictionary<string, string>());

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

        public static void Save(cmSite site, Dictionary<string, string> hostMapping)
        {
            string filePath = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/SiteHostMapping", site.DistinctName));

            string relativePath = "/.config/site_host_mapping.setting";
            string name = "Host Mapping";

            Revisions.BackupIfNotExists(site, filePath, relativePath, name);

            ObjectHelper.BinarySerialize<Dictionary<string, string>>(hostMapping, filePath);

            Revisions.Backup(site, filePath, relativePath, name);
        }
    }
}
