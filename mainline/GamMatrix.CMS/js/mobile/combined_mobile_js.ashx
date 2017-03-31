<%@ WebHandler Language="C#" Class="combined_mobile_js" %>

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

public class combined_mobile_js : IHttpHandler
{
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
        byte[] processed = null;

		lock (typeof(combined_mobile_js))
        {
            string[] files = new string[]
			{
				"~/js/mobile/plugins/jquery-1.10.2.min.js",
				"~/js/mobile/plugins/jquery.cookie.js",
				"~/js/mobile/plugins/jquery.validate.min.js",
                "~/js/mobile/plugins/jquery.touchSwipe.min.js",
				"~/js/mobile/plugins/jquery.touchwipe.min.js",
				"~/js/mobile/plugins/detectmobilebrowser.js",
				"~/js/mobile/plugins/overthrow.js",
				"~/js/mobile/plugins/swipe.min.js",
				"~/js/mobile/plugins/jquery.string.js",
                        
				"~/js/mobile/jquery.template.js",
				"~/js/mobile/jquery.validation.js",
				"~/js/mobile/init.js",
				"~/js/mobile/main.js",
				"~/js/mobile/slider.js",
                
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
                , true
                , true
                , true
                , 1024
                );

            processed = Encoding.UTF8.GetBytes(script);

            if (compress)
            {
                using (MemoryStream ms = new MemoryStream())
                {
                    using (GZipStream stream = new GZipStream(ms, CompressionMode.Compress))
                    {
                        byte[] buffer = processed;
                        stream.Write(buffer, 0, buffer.Length);
                        stream.Flush();
                        stream.Close();
                    }

                    processed = ms.ToArray();
                }
            }
        }

        return processed;
    }
}