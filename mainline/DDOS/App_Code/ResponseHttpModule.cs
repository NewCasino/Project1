using System;
using System.Collections.Generic;
using System.Web.Hosting;
using System.Linq;
using System.Web;
using System.IO;

/// <summary>
/// Summary description for ResponseHttpModule
/// </summary>
public class ResponseHttpModule : IHttpModule
{

    public void Dispose()
    {

    }

    public void Init(HttpApplication context)
    {
        context.BeginRequest += context_BeginRequest;

    }

    void context_BeginRequest(object sender, EventArgs e)
    {
        var context = HttpContext.Current;
        var response = context.Response;
        var request = context.Request;

        var url = request.Url.AbsolutePath;
        var extName = Path.GetExtension(url);
        if (!string.IsNullOrEmpty(extName))
        {
            if (PageExts.Count(p => p.Equals(extName, StringComparison.InvariantCultureIgnoreCase)) == 0)
                return;
            else
            {
                if (!url.Equals("/default.htm", StringComparison.InvariantCultureIgnoreCase))
                    return;
            }
        }

        var distinctName = request.QueryString["name"];
        if (!string.IsNullOrEmpty(distinctName))
        {
            distinctName = HttpUtility.UrlDecode(distinctName);
        }
        else
        {
            if (request.QueryString["supportemail"].Equals("support@everygame.com", StringComparison.InvariantCultureIgnoreCase))
            {
                distinctName = "Everygame";
            }
        }

        string html = string.Empty;

        var path = RouteFile(distinctName, request.QueryString["lang"]);
        if (string.IsNullOrEmpty(path))
        {
            response.Write("no template");
            response.End();
        }
        context.RewritePath(path);

    }

    private static string[] RouteFileNames = new[] {
        "default{0}.htm",
        "default{0}.html",
        "default{0}.aspx"
    };
    private static string[] PageExts = new[] { 
        ".htm",
        ".html",
        ".aspx"
    };
    private static string[] RouteDirectorys = new[]{
        "Sites/{0}",
        "{0}"
    };

    private string RouteFile(string distinctName, string lang = null)
    {
        var rootPath = HostingEnvironment.MapPath("~/");

        Func<string> resolvePath = () =>
        {
            Func<string, string> resolveDistinct = (suffix) =>
            {
                foreach (var dir in RouteDirectorys)
                {
                    foreach (var file in RouteFileNames)
                    {
                        var p = Path.Combine(rootPath, string.Format(dir, distinctName), string.Format(file, suffix));
                        if (File.Exists(p))
                        {
                            return Path.Combine(string.Format(dir, distinctName), string.Format(file, suffix));
                        }
                    }
                }
                return string.Empty;
            };
            Func<string, string> resolveDefault = (suffix) =>
            {
                foreach (var file in RouteFileNames)
                {
                    var p = Path.Combine(rootPath, string.Format(file, suffix));

                    if (File.Exists(p))
                    {
                        return string.Format(file, suffix);

                    }
                }
                return string.Empty;
            };

            var path = string.Empty;
            var suffix2 = string.Empty;
            if (string.IsNullOrEmpty(lang) || lang.Equals("en", StringComparison.InvariantCultureIgnoreCase))
            { }
            else
                suffix2 = "-" + lang;

            if (!string.IsNullOrEmpty(distinctName))
            {
                path = resolveDistinct(suffix2);
                if (string.IsNullOrEmpty(path))
                    path = resolveDistinct(string.Empty);
            }

            if (string.IsNullOrEmpty(path))
                path = resolveDefault(suffix2);

            if (string.IsNullOrEmpty(path))
                path = resolveDefault(string.Empty);

            return path;
        };

        return resolvePath();
    }


}