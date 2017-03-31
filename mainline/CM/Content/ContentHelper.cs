using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Caching;
using System.Web.Hosting;
using System.Web.Mvc;
using CM.db;
using CM.Sites;
using CM.Web;
using GamMatrix.Infrastructure;

namespace CM.Content
{
    public static class ContentHelper
    {
        private static Regex matchImgRegex = new Regex(@"\<(\s*)img(\s+)([^\>]*)\>", RegexOptions.Compiled | RegexOptions.Multiline | RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);
        private static Regex matchImgWithSrcRegex = new Regex(@"\<(\s*)img(\s+)([^\>]*?)src(\s*)\=(\s*)(?<quot>(\""|\'))(?<src>.+?)\k<quot>([^\>]*)\>", RegexOptions.Compiled | RegexOptions.Multiline | RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);
        public static string ParseFirstImageSrc(string html)
        {
            Match match = matchImgRegex.Match(html);
            if (match.Success)
            {
                Match secondaryMatch = matchImgWithSrcRegex.Match(html, match.Index);
                if (secondaryMatch.Success)
                    return secondaryMatch.Groups["src"].Value;
            }
            return null;
        }

        /// <summary>
        /// Get file content from  static file
        /// </summary>
        /// <param name="viewMasterPage"></param>
        /// <param name="path"></param>
        /// <returns></returns>
        public static string GetFileContent(this ViewMasterPageEx viewMasterPage, string path)
        {
            return GetFileContent(viewMasterPage.AppRelativeVirtualPath, path);
            
        }


        /// <summary>
        /// Get file content from static file
        /// </summary>
        /// <param name="viewMasterPage"></param>
        /// <param name="path"></param>
        /// <returns></returns>
        public static string GetFileContent(this ViewMasterPage viewMasterPage, string path)
        {
            return GetFileContent(viewMasterPage.AppRelativeVirtualPath, path);

        }

        /// <summary>
        /// Get file content from static file
        /// </summary>
        /// <param name="viewPage"></param>
        /// <param name="path"></param>
        /// <returns></returns>
        public static string GetFileContent(this ViewPageEx viewPage, string path)
        {
            return GetFileContent( viewPage.ViewData["__current_view_path"] as string, path);
        }

        /// <summary>
        /// Get file content from static file
        /// </summary>
        /// <param name="viewPage"></param>
        /// <param name="path"></param>
        /// <returns></returns>
        public static string GetFileContent(this ViewPage viewPage, string path)
        {
            return GetFileContent(viewPage.ViewData["__current_view_path"] as string, path);
        }

        /// <summary>
        /// Get file content from static file
        /// </summary>
        /// <param name="viewPage"></param>
        /// <param name="path"></param>
        /// <returns></returns>
        public static string GetFileContent(this ViewUserControlEx viewPage, string path)
        {
            return GetFileContent( viewPage.ViewData["__current_view_path"] as string, path);
        }

        /// <summary>
        /// Get file content from static file
        /// </summary>
        /// <param name="viewPage"></param>
        /// <param name="path"></param>
        /// <returns></returns>
        public static string GetFileContent(this ViewUserControl viewPage, string path)
        {
            return GetFileContent(viewPage.ViewData["__current_view_path"] as string, path);
        }

        private static Regex pathRegex = new Regex(@"^((?<quot>(\\|\/))Views(\k<quot>)[\w\-_]+)(?<path>.*)"
                         , RegexOptions.Compiled | RegexOptions.IgnoreCase | RegexOptions.CultureInvariant
                         );
        private static string GetFileContent(string appRelativeVirtualPath, string path)
        {
            try
            {
                appRelativeVirtualPath = VirtualPathUtility.GetDirectory(appRelativeVirtualPath.TrimStart('~'));

                Match match = pathRegex.Match(appRelativeVirtualPath);
                if (match.Success)
                {
                    appRelativeVirtualPath = match.Groups["path"].Value;
                }

                if (!path.StartsWith("/"))
                    path = VirtualPathUtility.Combine(appRelativeVirtualPath, path);


                cmSite site = SiteManager.Current;
                string cachePath = string.Format("ContentHelper.GetFileContent.{0}.{1}"
                    , site.DistinctName
                    , path
                    );

                string content = HttpRuntime.Cache[cachePath] as string;
                if (content != null)
                    return content;

                List<string> dependedFiles = new List<string>();

                string filePath = HostingEnvironment.MapPath(
                    string.Format("~/Views/{0}/{1}", site.DistinctName, (path ?? string.Empty).TrimStart('/'))
                    );
                dependedFiles.Add(filePath);
                content = WinFileIO.ReadWithoutLock(filePath);
                if ((content == null) && (!string.IsNullOrWhiteSpace(site.TemplateDomainDistinctName)))
                {
                    filePath = HostingEnvironment.MapPath(
                        string.Format("~/Views/{0}/{1}", site.TemplateDomainDistinctName, (path ?? string.Empty).TrimStart('/'))
                    );
                    dependedFiles.Add(filePath);
                    content = WinFileIO.ReadWithoutLock(filePath);
                }

                if (content == null)
                    content = string.Empty;

                HttpRuntime.Cache.Insert(cachePath
                    , content
                    , new CacheDependencyEx(dependedFiles.ToArray(), false)
                    , Cache.NoAbsoluteExpiration
                    , Cache.NoSlidingExpiration
                    );
                return content;
            }
            catch
            {
                return string.Empty;
            }
        }
    }
}
