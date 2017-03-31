using System;
using System.Collections.Generic;
using System.Globalization;
using System.Web;
using System.Web.Caching;
using System.Web.Hosting;
using CM.Content;
using CM.db;
using GamMatrix.Infrastructure;

namespace CM.Sites
{
    public static class UrlRuleExtension
    {
        public static Dictionary<string, string> GetUrlRewriteRules(this cmSite site)
        {
            string cacheKey = string.Format(CultureInfo.InvariantCulture
                , "~/Views/{0}/.config/url_rewrite.setting"
                , site.DistinctName
                );
            Dictionary<string, string> rules = HttpRuntime.Cache[cacheKey] as Dictionary<string, string>;
            if (rules != null)
                return rules;

            rules = ObjectHelper.XmlDeserialize<Dictionary<string, string>>( HostingEnvironment.MapPath(cacheKey), null);
            if (rules == null)
            {
                rules = new Dictionary<string, string>(StringComparer.InvariantCultureIgnoreCase);
                rules["/Poker/"] = "/Poker/Home";
                rules["/Sports/"] = "/Sports/Home";
                rules["/Casino/"] = "/Casino/Home";
                rules["/Bingo/"] = "/Bingo/Home";
                rules["/Poker/"] = "/Poker/Home";
                rules["/LiveCasino/"] = "/LiveCasino/Home";
                rules["/Affiliates/"] = "/Affiliates/Home";
            }

            HttpRuntime.Cache.Insert(cacheKey
                , rules
                , new CacheDependencyEx(new string [] { cacheKey }, true)
                , Cache.NoAbsoluteExpiration
                , Cache.NoSlidingExpiration
                , CacheItemPriority.NotRemovable
                , null
                );
            return rules;
        }

        public static void SaveUrlRewriteRules(this cmSite site, Dictionary<string, string> rules)
        {
            string cacheKey = string.Format(CultureInfo.InvariantCulture
                , "~/Views/{0}/.config/url_rewrite.setting"
                , site.DistinctName
                );
            string path = HostingEnvironment.MapPath(cacheKey);

            HttpRuntime.Cache.Remove(cacheKey);

            string relativePath = "/.config/url_rewrite.setting";
            string name = "Url Rewritting";

            Revisions.BackupIfNotExists(site, path, relativePath, name);

            ObjectHelper.XmlSerialize<Dictionary<string, string>>(rules, path);

            Revisions.Backup(site, path, relativePath, name);
        }


        public static Dictionary<string, string> GetHttpRedirectionRules(this cmSite site)
        {
            string cacheKey = string.Format(CultureInfo.InvariantCulture
                , "~/Views/{0}/.config/http_redirection.setting"
                , site.DistinctName
                );
            Dictionary<string, string> rules = HttpRuntime.Cache[cacheKey] as Dictionary<string, string>;
            if (rules != null)
                return rules;

            rules = ObjectHelper.XmlDeserialize<Dictionary<string, string>>(HostingEnvironment.MapPath(cacheKey), null);
            if (rules == null)
                rules = new Dictionary<string, string>(StringComparer.InvariantCultureIgnoreCase);

            HttpRuntime.Cache.Insert(cacheKey
                , rules
                , new CacheDependencyEx(new string[] { cacheKey }, true)
                , Cache.NoAbsoluteExpiration
                , Cache.NoSlidingExpiration
                , CacheItemPriority.NotRemovable
                , null
                );
            return rules;
        }

        public static void SaveHttpRedirectionRules(this cmSite site, Dictionary<string, string> rules)
        {
            string cacheKey = string.Format(CultureInfo.InvariantCulture
                , "~/Views/{0}/.config/http_redirection.setting"
                , site.DistinctName
                );
            string path = HostingEnvironment.MapPath(cacheKey);

            HttpRuntime.Cache.Remove(cacheKey);

            string relativePath = "/.config/http_redirection.setting";
            string name = "HTTP 301 Redirection";

            Revisions.BackupIfNotExists(site, path, relativePath, name);
            
            ObjectHelper.XmlSerialize<Dictionary<string, string>>(rules, path);

            Revisions.Backup(site, path, relativePath, name);
        }
    }
}
