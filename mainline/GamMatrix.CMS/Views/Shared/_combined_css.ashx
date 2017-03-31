<%@ WebHandler Language="C#" Class="_combined_css" %>

using System;
using System.IO;
using System.IO.Compression;
using System.Text;
using System.Text.RegularExpressions;
using System.Collections.Generic;
using System.Web;
using System.Web.Caching;
using System.Globalization;
using Yahoo.Yui.Compressor;


using CM.Sites;

public class _combined_css : IHttpHandler {

    internal sealed class CssReplacer
    {
        public string AbsolutePath { get; set; }
        public string RelativePath { get; set; }
        public HttpContext HttpContext { get; set; }
        public List<string> DependedFiles { get; set; }
        internal string OnImportMatch(Match m)
        {
            if (m.Groups.Count == 0 || m.Groups["path"] == null)
                return string.Empty;
            
            string path = m.Groups["path"].Value;
            if (path.StartsWith("/"))
            {
                return ParseCss(this.HttpContext.Server.MapPath(path)
                    , path
                    , this.HttpContext
                    , this.DependedFiles
                    );
            }
            else
            {
                path = path.Replace("\\", "/");
                return ParseCss( this.ResolvePath(Path.GetDirectoryName(this.AbsolutePath), path)
                    , this.ResolvePath(VirtualPathUtility.GetDirectory(this.RelativePath), path)
                    , this.HttpContext
                    , this.DependedFiles
                    );
            }
        }

        internal string OnImageMatch(Match m)
        {
            if (m.Groups.Count == 0 || m.Groups["path"] == null)
                return string.Empty;

            string path = m.Groups["path"].Value;
            if (path.StartsWith("/") ||
                path.StartsWith("http://") ||
                path.StartsWith("https://") )
            {
                return m.Value;
            }

            if (string.IsNullOrWhiteSpace(path))
                return string.Empty;

            path = ResolvePath(VirtualPathUtility.GetDirectory(this.RelativePath), path);

            return string.Format("url(\"{0}\")", path);
        }

        private string ResolvePath(string absolutePath, string relativePath)
        {
            try
            {
                bool isFilePath = !absolutePath.StartsWith("/");
                if (relativePath.StartsWith("./"))
                {
                    relativePath = relativePath.Substring("./".Length);
                    return this.ResolvePath(absolutePath, relativePath);
                }
                else if (relativePath.StartsWith("../"))
                {
                    relativePath = relativePath.Substring("../".Length);
                    if (isFilePath)
                        return this.ResolvePath(Path.GetDirectoryName(absolutePath), relativePath);
                    else
                        return this.ResolvePath(VirtualPathUtility.GetDirectory(absolutePath), relativePath);
                }
                else
                {
                    if (isFilePath)
                        return Path.Combine(absolutePath, relativePath);
                    return
                        VirtualPathUtility.Combine(absolutePath, relativePath);
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return string.Empty;
            }
        }
    }

    private static bool SupportGZipCompression(HttpRequest request)
    {
        string acceptEncoding = request.Headers["Accept-Encoding"];
        if (!string.IsNullOrEmpty(acceptEncoding) && acceptEncoding.Contains("gzip") )
            return true;
        return false;
    }
    
    public void ProcessRequest (HttpContext context) {
        context.Response.ContentType = "text/css";
        context.Response.Cache.SetExpires(DateTime.Now.AddDays(7));
        context.Response.Cache.SetMaxAge(TimeSpan.FromDays(7));
        context.Response.Cache.SetCacheability(HttpCacheability.Public);
        context.Response.Cache.AppendCacheExtension("must-revalidate, proxy-revalidate");

        string themeName = context.Request["Theme"];
        bool isRightToLeft = (HttpContext.Current.Items["IsRightToLeft"] as bool?) == true;
        if (string.IsNullOrEmpty(themeName))
        {
            themeName = string.Format("{0}{1}", SiteManager.Current.DefaultTheme
                , isRightToLeft ? "_rtl" : string.Empty
                );
        }

        if (Settings.CSS_EnableCompression)
        {
            bool compress = SupportGZipCompression(context.Request);
            byte[] buffer = GetCombinedContent(themeName, isRightToLeft, compress, context);
            context.Response.OutputStream.Write(buffer, 0, buffer.Length);
            context.Response.AppendHeader("Content-Length", buffer.Length.ToString());
            context.Response.AppendHeader("Etag", string.Format( "\"{0}{1}\"", DateTime.Now.DayOfYear, buffer.Length.ToString()));
            context.Response.AppendHeader("Vary", "Accept-Encoding");

            if (compress)
                context.Response.AppendHeader("Content-Encoding", "gzip");
        }
        else
        {
            string content = string.Format(@"@import url(""/App_Themes/Generic/global{0}.css"");
@import url(""/App_Themes/{1}/_import.css"");"
                , isRightToLeft ? "_rtl" : string.Empty
                , themeName
                );
            context.Response.Write(content);
            context.Response.AppendHeader("Content-Length", content.Length.ToString());
        }        

    }

    private static byte[] GetCombinedContent(string themeName, bool isRightToLeft, bool compress, HttpContext context)
    {
        string cacheKey = string.Format("css_combined_content_{0}_{1}_{2}"
            , themeName
            , isRightToLeft
            , compress ? "compressed" : "raw"
            );
        byte[] cache = HttpRuntime.Cache[cacheKey] as byte[];
        if (cache != null)
            return cache;

        List<string> files = new List<string>();
        List<string> dependedFiles = new List<string>();
        
        StringBuilder sb = new StringBuilder();
        string relativePath = string.Format("/App_Themes/Generic/global{0}.css"
            , isRightToLeft ? "_rtl" : string.Empty
            );
        string absolutePath = context.Server.MapPath(relativePath);
        sb.AppendLine(ParseCss(absolutePath, relativePath, context, dependedFiles));
        
        relativePath = string.Format("/App_Themes/{0}/_import.css", themeName);
        absolutePath = context.Server.MapPath(relativePath);
        sb.AppendLine(ParseCss(absolutePath, relativePath, context, dependedFiles));

        // minify the css
        string css = CssCompressor.Compress(sb.ToString());

        cache = Encoding.UTF8.GetBytes(css);

        if (compress)
        {
            using (MemoryStream ms = new MemoryStream())
            {
                using (GZipStream stream = new GZipStream(ms, CompressionMode.Compress))
                {
                    byte[] buffer = cache;
                    stream.Write(buffer, 0, buffer.Length);
                    stream.Flush();
                    stream.Close();
                }

                cache = ms.ToArray();
            }
        }
        HttpRuntime.Cache.Insert(cacheKey
                , cache
                , new CacheDependency(dependedFiles.ToArray())
                , DateTime.Now.AddHours(5)
                , Cache.NoSlidingExpiration
                );
        return cache;
    }

    private static string ParseCss(string absolutePath, string relativePath, HttpContext context, List<string> dependedFiles)
    {
        if (!File.Exists(absolutePath))
            return string.Empty;
        dependedFiles.Add(absolutePath);
        string content = null;
        using (StreamReader sr = new StreamReader(absolutePath))
        {
            content = sr.ReadToEnd();
            sr.Close();
        }

        CssReplacer replacer = new CssReplacer() { AbsolutePath = absolutePath
            , RelativePath = relativePath
            , DependedFiles = dependedFiles
            , HttpContext = context
        };
        content = Regex.Replace(content, @"url(\s*)\((\s*)(?<quot>(\""|\')?)(?<path>[^\""\'\)]*)\k<quot>(\s*)\)"
            , replacer.OnImageMatch
            , RegexOptions.ECMAScript | RegexOptions.IgnoreCase | RegexOptions.Multiline | RegexOptions.Compiled | RegexOptions.CultureInvariant
            );
        
        content = Regex.Replace(content, @"\@import(\s+)url(\s*)\((\s*)(?<quot>(\""|\')?)(?<path>[^\""\']*)\k<quot>(\s*)\)(\s*)(\;?)"
            , replacer.OnImportMatch
            , RegexOptions.ECMAScript | RegexOptions.IgnoreCase | RegexOptions.Multiline | RegexOptions.Compiled | RegexOptions.CultureInvariant
            );
        return content;
    }
 
    public bool IsReusable {
        get {
            return false;
        }
    }

}