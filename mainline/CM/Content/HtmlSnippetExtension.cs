using System;
using System.Globalization;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Mvc;
using CM.Web;

namespace CM.Content
{
    public static class HtmlSnippetExtension
    {
        private static Regex controlPathRegex = new Regex(@"^((\~?)\/Views\/[\w\-_]+)(?<path>\/.+?)([^\/]+)$"
                            , RegexOptions.Compiled | RegexOptions.IgnoreCase | RegexOptions.CultureInvariant
                            );
        private static string ResolveViewControlPath(ViewUserControlEx viewControl, string path)
        {
            string cacheKey = string.Format(CultureInfo.InvariantCulture
                    , "HtmlSnippetExtension.ResolveViewControlPath.{0}.{1}"
                    , viewControl.ViewData["__current_view_path"] as string
                    , path
                    );
            string cachedPath = HttpRuntime.Cache[cacheKey] as string;
            if (cachedPath != null)
                return cachedPath;

            if (!path.EndsWith(".snippet", StringComparison.InvariantCultureIgnoreCase))
                path += ".snippet";

            if (!path.StartsWith("/", StringComparison.InvariantCulture))
            {
                Match match = controlPathRegex.Match(viewControl.ViewData["__current_view_path"] as string);
                if (match.Success)
                {
                    path = match.Groups["path"].Value + path;
                }
            }

            HttpRuntime.Cache[cacheKey] = path;

            return path;
        }

        private static Regex pagePathRegex = new Regex(@"^((\~?)\/Views\/[\w\-_]+)(?<path>\/.+)"
                            , RegexOptions.Compiled | RegexOptions.IgnoreCase | RegexOptions.CultureInvariant
                            );
        private static string ResolveViewPagePath(ViewPage viewPage, string path)
        {
            string cacheKey = string.Format(CultureInfo.InvariantCulture
                    , "HtmlSnippetExtension.ResolveViewPagePath.{0}"
                    , viewPage.ViewData["__current_view_path"] as string
                    );
            string cachedPath = HttpRuntime.Cache[cacheKey] as string;
            if (cachedPath != null)
                return cachedPath;

            if (!path.EndsWith(".snippet", StringComparison.InvariantCultureIgnoreCase))
                path += ".snippet";

            if (!path.StartsWith("/", StringComparison.InvariantCulture))
            {
                Match match = pagePathRegex.Match(viewPage.ViewData["__current_view_path"] as string);
                if (match.Success)
                {
                    path = match.Groups["path"].Value + path;
                }
            }

            HttpRuntime.Cache[cacheKey] = path;

            return path;
        }

        private static Regex masterPagePathRegex = new Regex(@"^(\/Views\/[\w\-_]+)(?<path>\/.+?)([^\/]+)$"
                    , RegexOptions.Compiled);

        private static string ResolveViewMasterPagePath(ViewMasterPage viewMasterPage, string path)
        {
            string cacheKey = string.Format(CultureInfo.InvariantCulture
                    , "HtmlSnippetExtension.ResolveViewMasterPagePath.{0}"
                    , viewMasterPage.AppRelativeVirtualPath
                    );
            string cachedPath = HttpRuntime.Cache[cacheKey] as string;
            if (cachedPath != null)
                return cachedPath;

            if (!path.EndsWith(".snippet", StringComparison.InvariantCultureIgnoreCase))
                path += ".snippet";

            if (!path.StartsWith("/", StringComparison.InvariantCulture))
            {
                string appRelativeVirtualPath = viewMasterPage.AppRelativeVirtualPath.TrimStart('~');
                Match match = masterPagePathRegex.Match(appRelativeVirtualPath);
                if (match.Success)
                    appRelativeVirtualPath = match.Groups["path"].Value;
                path = appRelativeVirtualPath + path;
            }

            HttpRuntime.Cache[cacheKey] = path;

            return path;
        }

        public static string ClientTemplate(this ViewPage viewPage, string path, string id, object config = null)
        {
            string output = string.Format( CultureInfo.InvariantCulture
                , "<script type=\"text/html\" id=\"{0}\">\n{1}\n</script>"
                , id.SafeHtmlEncode()
                , HtmlSnippet.Get(null, null, ResolveViewPagePath(viewPage, path), config)
                );
            return output;
        }

        public static string PopulateTemplate(this ViewPage viewPage, string path, object data = null, object config = null)
        {
            path = ResolveViewPagePath(viewPage, path);
            return HtmlSnippet.Populate(null, null, path, data, config); ;
        }


        public static string ClientTemplate(this ViewMasterPage viewMasterPage, string path, string id, object config = null)
        {
            string output = string.Format(CultureInfo.InvariantCulture
                , "<script type=\"text/html\" id=\"{0}\">\n{1}\n</script>"
                , id.SafeHtmlEncode()
                , HtmlSnippet.Get(null, null, ResolveViewMasterPagePath(viewMasterPage, path), config)
                );
            return output;
        }

        public static string PopulateTemplate(this ViewMasterPage viewMasterPage, string path, object data = null, object config = null)
        {
            path = ResolveViewMasterPagePath(viewMasterPage, path);
            return HtmlSnippet.Populate(null, null, path, data, config); ;
        }

        public static string ClientTemplate(this ViewUserControlEx viewControl, string path, string id, object config = null)
        {
            string output = string.Format(CultureInfo.InvariantCulture
                , "<script type=\"text/html\" id=\"{0}\">\n{1}\n</script>"
                , id.SafeHtmlEncode()
                , HtmlSnippet.Get(null, null, ResolveViewControlPath(viewControl, path), config)
                );
            return output;
        }

        public static string PopulateTemplate(this ViewUserControlEx viewControl, string path, object data = null, object config = null)
        {
            path = ResolveViewControlPath(viewControl, path);
            return HtmlSnippet.Populate(null, null, path, data, config); ;
        }

        public static string PopulateTemplateWithJson(this ViewUserControlEx viewControl, string path, string json = "null", object config = null)
        {
            path = ResolveViewControlPath(viewControl, path);
            return HtmlSnippet.Populate(null, null, path, json, config, true); ;
        }
    }
}
