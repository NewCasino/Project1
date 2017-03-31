using System;
using System.Web;
using System.Web.Caching;

public static class CurrentUserSession
{
    public static string SESSION_COOKIE_NAME = "ceSession";
    public static string USER_SESSION_COOKIE_NAME = "gmcoresid";

    public static string SessionID
    {
        get
        {
            if (HttpContext.Current == null)
                throw new Exception();

            HttpCookie cookie = HttpContext.Current.Request.Cookies[SESSION_COOKIE_NAME];
            if (cookie != null && !string.IsNullOrWhiteSpace(cookie.Value))
                return cookie.Value;

            string sessionID = HttpContext.Current.Items[SESSION_COOKIE_NAME] as string;
            if (!string.IsNullOrWhiteSpace(sessionID))
                return sessionID;

            cookie = new HttpCookie(SESSION_COOKIE_NAME, Guid.NewGuid().ToString());
            cookie.HttpOnly = true;
            HttpContext.Current.Response.Cookies.Add(cookie);
            HttpContext.Current.Items[SESSION_COOKIE_NAME] = cookie.Value;
            return cookie.Value;
        }
    }

    public static string UserSessionID
    {
        get
        {
            if (HttpContext.Current == null)
                throw new Exception();

            HttpCookie cookie = HttpContext.Current.Request.Cookies[USER_SESSION_COOKIE_NAME];
            if (cookie != null && !string.IsNullOrWhiteSpace(cookie.Value))
                return cookie.Value;
            
            return string.Empty;
        }
    }

    public static bool IsSystemUser
    {
        get { return Constant.SystemDomainID == CurrentUserSession.UserDomainID; }
    }

    /// <summary>
    /// IsAuthenticated
    /// </summary>
    public static bool IsAuthenticated
    {
        get
        {
            string cacheKey = string.Format( "{0}_IsAuthenticated", SessionID);
            try
            {
                return (bool)HttpRuntime.Cache[cacheKey];
            }
            catch
            {
                return false;
            }
        }
        set
        {
            string cacheKey = string.Format("{0}_IsAuthenticated", SessionID);
            HttpRuntime.Cache.Insert(cacheKey, value, null, Cache.NoAbsoluteExpiration, TimeSpan.FromMinutes(40));
        }
    }

    /// <summary>
    /// User ID
    /// </summary>
    public static long UserID
    {
        get
        {
            string cacheKey = string.Format("{0}_UserID", SessionID);
            try
            {
                return (long)HttpRuntime.Cache[cacheKey];
            }
            catch
            {
                return 0L;
            }
        }
        set
        {
            string cacheKey = string.Format("{0}_UserID", SessionID);
            HttpRuntime.Cache.Insert(cacheKey, value, null, Cache.NoAbsoluteExpiration, TimeSpan.FromMinutes(40));
        }
    }


    /// <summary>
    /// Roles
    /// </summary>
    public static string [] Roles
    {
        get
        {
            string cacheKey = string.Format("{0}_Roles", SessionID);
            return (HttpRuntime.Cache[cacheKey] as string[]) ?? (new string[0]);
        }
        set
        {
            string cacheKey = string.Format("{0}_Roles", SessionID);
            HttpRuntime.Cache.Insert(cacheKey, value, null, Cache.NoAbsoluteExpiration, TimeSpan.FromMinutes(40));
        }
    }


    /// <summary>
    /// IsSuperUser
    /// </summary>
    public static bool IsSuperUser
    {
        get
        {
            string cacheKey = string.Format("{0}_IsSuperUser", SessionID);
            try
            {
                return (bool)HttpRuntime.Cache[cacheKey];
            }
            catch
            {
                return false;
            }
        }
        set
        {
            string cacheKey = string.Format("{0}_IsSuperUser", SessionID);
            HttpRuntime.Cache.Insert(cacheKey, value, null, Cache.NoAbsoluteExpiration, TimeSpan.FromMinutes(40));
        }
    }


    /// <summary>
    /// ShowInactiveDomains
    /// </summary>
    public static bool ShowInactiveDomains
    {
        get
        {
            string cacheKey = string.Format("{0}_ShowInactiveDomains", SessionID);
            try
            {
                return (bool)HttpRuntime.Cache[cacheKey];
            }
            catch
            {
                return false;
            }
        }
        set
        {
            string cacheKey = string.Format("{0}_ShowInactiveDomains", SessionID);
            HttpRuntime.Cache.Insert(cacheKey, value, null, Cache.NoAbsoluteExpiration, TimeSpan.FromMinutes(40));
        }
    }


    /// <summary>
    /// UserDomainID
    /// </summary>
    public static long UserDomainID
    {
        get
        {
            string cacheKey = string.Format("{0}_UserDomainID", SessionID);
            try
            {
                return (long)HttpRuntime.Cache[cacheKey];
            }
            catch
            {
                return 0L;
            }
        }
        set
        {
            string cacheKey = string.Format("{0}_UserDomainID", SessionID);
            HttpRuntime.Cache.Insert(cacheKey, value, null, Cache.NoAbsoluteExpiration, TimeSpan.FromMinutes(40));
        }
    }
}
