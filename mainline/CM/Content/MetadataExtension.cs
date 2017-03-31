using System.Globalization;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Mvc;
using CM.Web;

namespace CM.Content
{
    public static class MetadataExtension
    {
        public static string GetMetadata(this ViewPage viewPage, string path, string entryName)
        {
            return GetMetadata(viewPage, string.Format( CultureInfo.InvariantCulture
                , "{0}{1}", path.TrimEnd('/')
                , entryName
                ));
        }

        /// <summary>
        /// Get the metadata
        /// </summary>
        /// <param name="viewPage"></param>
        /// <param name="path"></param>
        /// <returns></returns>
        public static string GetMetadata(this ViewPage viewPage, string path)
        {
            return GetMetadataEx(viewPage, path);
        }

        private static Regex hiddenPathRegex = new Regex(@"^(\.[\w\-_]+)$", RegexOptions.Compiled);
        private static Regex pathRegex = new Regex(@"^((\~?)\/Views\/[\w\-_]+)(?<path>\/.+)"
                        , RegexOptions.Compiled | RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);

        public static string GetMetadataEx(this ViewPage viewPage, string path, params object[] args)
        {
            string cacheKey = string.Format("MetadataExtension.ViewPage.{0}.{1}"
                , viewPage.ViewData["__current_view_path"]
                , path
                );
            string cachedPath = HttpRuntime.Cache[cacheKey] as string;
            if (cachedPath != null)
                path = cachedPath;
            else
            {
                if (viewPage.ViewData["__current_view_path"] != null && hiddenPathRegex.IsMatch(path))
                {
                    Match match = pathRegex.Match(viewPage.ViewData["__current_view_path"] as string);
                    if (match.Success)
                    {
                        string metadataPath = Regex.Replace(match.Groups["path"].Value ?? string.Empty
                            , @"(\/[^\/]+)$"
                            , delegate(Match m) { return string.Format("/_{0}", Regex.Replace(m.ToString().TrimStart('/'), @"[^\w\-_]", "_", RegexOptions.Compiled)); }
                            , RegexOptions.Compiled);

                        path = metadataPath + path;
                    }
                }
                HttpRuntime.Cache[cacheKey] = path;
            }

            string content = Metadata.Get(path);
            if (args != null && args.Length > 0)
            {
                try
                {
                    content = string.Format(content, args);
                }
                catch
                {
                }
            }
            return content;
        }

        public static string GetMetadata(this ViewMasterPage viewPage, string path, string entryName)
        {
            return GetMetadata(viewPage, string.Format("{0}{1}", path.TrimEnd('/'), entryName));
        }

        private static Regex virtualPathRegex = new Regex(@"^(\/Views\/[\w\-_]+)(?<path>\/.+)", RegexOptions.Compiled);

        public static string GetMetadata(this ViewMasterPage viewMasterPage, string path)
        {
            string cacheKey = string.Format("MetadataExtension.ViewMasterPage.{0}.{1}"
                , viewMasterPage.AppRelativeVirtualPath
                , path
                );
            string cachedPath = HttpRuntime.Cache[cacheKey] as string;
            if (cachedPath != null)
                path = cachedPath;
            else
            {
                if (hiddenPathRegex.IsMatch(path))
                {
                    string appRelativeVirtualPath = viewMasterPage.AppRelativeVirtualPath.TrimStart('~');
                    Match match = virtualPathRegex.Match(appRelativeVirtualPath);
                    if (match.Success)
                        appRelativeVirtualPath = match.Groups["path"].Value;
                    string metadataPath = Regex.Replace(appRelativeVirtualPath
                        , @"(\/[^\/]+)$"
                        , delegate(Match m) { return string.Format("/_{0}", Regex.Replace(m.ToString().TrimStart('/'), @"[^\w\-_]", "_", RegexOptions.Compiled)); }
                        , RegexOptions.Compiled
                        );

                    path = metadataPath + path;
                }
                HttpRuntime.Cache[cacheKey] = path;
            }

            return Metadata.Get(path);
        }

        public static string GetMetadata(this ViewUserControlEx viewPage, string path, string entryName)
        {
            return GetMetadata(viewPage, string.Format("{0}{1}", path.TrimEnd('/'), entryName));
        }

        public static string GetMetadata(this ViewUserControlEx viewUserControlEx, string path)
        {
            return GetMetadataEx(viewUserControlEx, path);
        }

        public static string GetMetadataEx(this ViewUserControlEx viewUserControlEx, string path, params object[] args)
        {
            string cacheKey = string.Format("MetadataExtension.ViewUserControlEx.{0}.{1}"
                , viewUserControlEx.ViewData["__current_view_path"]
                , path
                );
            string cachedPath = HttpRuntime.Cache[cacheKey] as string;
            if (cachedPath != null)
                path = cachedPath;
            else
            {
                if (viewUserControlEx.ViewData["__current_view_path"] != null && hiddenPathRegex.IsMatch(path))
                {
                    Match match = pathRegex.Match(viewUserControlEx.ViewData["__current_view_path"] as string);
                    if (match.Success)
                    {
                        string metadataPath = Regex.Replace(match.Groups["path"].Value
                            , @"(\/[^\/]+)$"
                            , delegate(Match m) { return string.Format("/_{0}", Regex.Replace(m.ToString().TrimStart('/'), @"[^\w\-_]", "_", RegexOptions.Compiled)); }
                            , RegexOptions.Compiled);

                        path = metadataPath + path;
                    }
                }
                HttpRuntime.Cache[cacheKey] = path;
            }

            string content = Metadata.Get(path);
            if (args != null && args.Length > 0)
            {
                try
                {
                    content = string.Format( CultureInfo.InvariantCulture, content, args);
                }
                catch
                {
                }
            }
            return content;
        }
    }
}
