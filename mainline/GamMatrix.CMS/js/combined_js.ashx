<%@ WebHandler Language="C#" Class="combined_js" %>

using System;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Web;
using System.Web.Caching;
using System.Text;
using System.Collections;
using System.Collections.Generic;
using Yahoo.Yui.Compressor;

public class combined_js : IHttpHandler {

    private static bool SupportGZipCompression(HttpRequest request)
    {
        string acceptEncoding = request.Headers["Accept-Encoding"];
        if (!string.IsNullOrEmpty(acceptEncoding) &&
             (acceptEncoding.Contains("gzip") || acceptEncoding.Contains("deflate")))
            return true;
        return false;
    }
    
    public void ProcessRequest (HttpContext context) {

        context.Response.ContentType = "text/javascript";
        context.Response.Cache.SetExpires(DateTime.Now.AddDays(7));
        context.Response.Cache.SetMaxAge(TimeSpan.FromDays(7));
        context.Response.Cache.SetCacheability(HttpCacheability.Public);
        context.Response.Cache.AppendCacheExtension("must-revalidate, proxy-revalidate");

        bool compress = SupportGZipCompression(context.Request);
        byte[] buffer = GetCombinedContent(compress, context);
        context.Response.OutputStream.Write(buffer, 0, buffer.Length);
        context.Response.AppendHeader("Content-Length", buffer.Length.ToString());
        context.Response.AppendHeader("Etag", string.Format( "\"{0}{1}\"", DateTime.Now.DayOfYear, buffer.Length.ToString()));
        context.Response.AppendHeader("Vary", "Accept-Encoding");

        if (compress)
            context.Response.AppendHeader("Content-Encoding", "gzip");

        context.Response.End();
    }

 
    public bool IsReusable {
        get {
            return true;
        }
    }


    private static byte[] GetCombinedContent( bool compress, HttpContext context)
    {
        string cacheKey = string.Format( "javascript_combined_content_{0}", compress ? "compressed" : "raw");
        byte[] cache = HttpRuntime.Cache[cacheKey] as byte[];
        if (cache != null)
            return cache;

        lock (typeof(combined_js))
        {
            cache = HttpRuntime.Cache[cacheKey] as byte[];
            if (cache != null)
                return cache;

            string[] files = new string[]
                    {
                        "~/js/jquery/jquery-1.7.1.min.js",
                        "~/js/jquery/jquery.template.js",
                        "~/js/jquery/jquery.string.js",
                        "~/js/jquery/jquery.form.min.js",
                        "~/js/jquery/jquery.validate.min.js",
                        "~/js/jquery/jquery.metadata.js",
                        "~/js/jquery/jquery.simplemodal-1.4.1.js",
                        "~/js/jquery/jquery.simplemodal.extension.js",
                        "~/js/jquery/jquery.browser.mobile.js",
                        "~/js/jquery/jquery.cookie.js",
                        "~/js/jquery/jquery.getimagedata.js",
                        "~/js/inputfield.js",
                        "~/js/respond.min.js",
                        "~/js/modernizr.custom.70231.js",
                        "~/js/swfobject.js",
                        "~/js/localStorage.js",
                        "~/js/plugin.js",
                        "~/js/browser-select.js",
                        "~/js/concurrent.thread.js",
                        "~/js/intro.js",
                        "~/js/date.js",
                        "~/js/grayscale.js",
                    };
            List<string> pathes = files.Select(f => context.Server.MapPath(f)).ToList();

            StringBuilder sb = new StringBuilder();
            foreach (string file in pathes)
            {
                using (StreamReader sr = new StreamReader(file, Encoding.UTF8))
                {
                    sb.AppendFormat("\n{0}\n;", sr.ReadToEnd());
                }
            }
            
            // minify the javascript
            string script = JavaScriptCompressor.Compress(sb.ToString()
                , false
                , false
                , true
                , true
                , 1024
                );

            cache = Encoding.UTF8.GetBytes(script);

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
                , new CacheDependency(pathes.ToArray())
                , DateTime.Now.AddHours(1)
                , Cache.NoSlidingExpiration
                );
        }

        return cache;
    }


}