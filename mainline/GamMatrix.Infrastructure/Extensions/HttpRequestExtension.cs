using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

public enum TerminalType
{
    PC,
    iPad,
    iPhone,
    Android,
    WindowsPhone,
}

/// <summary>
///RequestExtension
/// </summary>
public static class HttpRequestExtension
{
    public static string GetRealUserAddress(this HttpRequest request)
    {
        if (request != null)
        {
            string ip = request.Headers["X-Real-IP"].DefaultIfNullOrEmpty(request.Headers["X-Forwarded-For"]);
            if (!string.IsNullOrEmpty(ip))
            {
                return ip.Split(',')[0].Trim();
            }
            return request.UserHostAddress;
        }
        return string.Empty;
    }

    public static string GetRealUserAddress(this HttpRequestBase request)
    {
        return GetRealUserAddress(HttpContext.Current.Request);
    }

    public static string GetLanguage(this HttpRequestBase request)
    {
        return HttpContext.Current.Items["GM_Language"] == null ? null : HttpContext.Current.Items["GM_Language"].ToString();
    }

    public static string GetLanguage(this HttpContext context)
    {
        return context.Items["GM_Language"] == null ? null : context.Items["GM_Language"].ToString();
    }

    public static bool IsHttps(this HttpRequest request)
    {
        bool isHttps = string.Equals(request.Headers["Front-End-Https"], "On", StringComparison.InvariantCultureIgnoreCase); 
        if( !isHttps )
            isHttps = string.Equals(request.Url.Scheme, "https", StringComparison.InvariantCultureIgnoreCase);
        return isHttps; 
    }

    public static bool IsHttps(this HttpRequestBase request)
    {
        return IsHttps(HttpContext.Current.Request);
    }

    public static string GetUrlScheme(this HttpRequest request)
    {
        return IsHttps(request) ? "https" : "http";
    }

    public static bool IsAjaxRequest(this HttpRequest request)
    {
        return ((request["X-Requested-With"] == "XMLHttpRequest") || ((request.Headers != null) && (request.Headers["X-Requested-With"] == "XMLHttpRequest")));
    }

    public static TerminalType GetTerminalType(this HttpRequest request)
    {
        string userAgent = request.UserAgent;
        if (string.IsNullOrEmpty(userAgent))
            return TerminalType.PC;

        userAgent = userAgent.ToUpperInvariant();

        if (userAgent.IndexOf("Windows Phone", StringComparison.InvariantCultureIgnoreCase) >= 0)
            return TerminalType.WindowsPhone;

        if (userAgent.IndexOf("iPad", StringComparison.InvariantCultureIgnoreCase) >= 0)
            return TerminalType.iPad;

        if (userAgent.IndexOf("iPhone", StringComparison.InvariantCultureIgnoreCase) >= 0)
            return TerminalType.iPhone;

        if (userAgent.IndexOf("Android", StringComparison.InvariantCultureIgnoreCase) >= 0)
            return TerminalType.Android;

     

        return TerminalType.PC;
    }

    public static bool IsPost(this HttpRequestBase request)
    {
        return string.Equals(request.HttpMethod, "POST", StringComparison.InvariantCultureIgnoreCase);
    }

    public static bool IsGet(this HttpRequestBase request)
    {
        return string.Equals(request.HttpMethod, "GET", StringComparison.InvariantCultureIgnoreCase);
    }

    public static bool IsHead(this HttpRequestBase request)
    {
        return string.Equals(request.HttpMethod, "HEAD", StringComparison.InvariantCultureIgnoreCase);
    }
}
