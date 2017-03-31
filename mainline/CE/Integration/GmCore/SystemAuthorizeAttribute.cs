using System;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.Mvc;
using GamMatrixAPI;

[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, Inherited = true, AllowMultiple = false)]
public sealed class SystemAuthorizeAttribute : AuthorizeAttribute
{
    public override void OnAuthorization(AuthorizationContext filterContext)
    {
        if (filterContext == null)
            throw new ArgumentNullException("filterContext");

        HttpRequestBase request = filterContext.RequestContext.HttpContext.Request;
        string sessionID = request.QueryString["session_id"];
        if ( string.Equals( request.HttpMethod, "GET", StringComparison.OrdinalIgnoreCase) &&
                !filterContext.RequestContext.HttpContext.Request.IsAjaxRequest() )
        {
            HttpCookie cookie = filterContext.RequestContext.HttpContext.Request.Cookies["gmcoresid"];
            if (!string.IsNullOrWhiteSpace(sessionID) ||
                (cookie != null && !string.IsNullOrEmpty(cookie.Value) && !CurrentUserSession.IsAuthenticated))
            {
                if (string.IsNullOrWhiteSpace(sessionID))
                    sessionID = cookie.Value;
                    
                using (GamMatrixClient client = new GamMatrixClient())
                {
                    ReplyResponse replyResp = client.IsLoggedIn(new IsLoggedInRequest() { SESSION_ID = sessionID });
                    IsLoggedInRequest resp = replyResp.Reply as IsLoggedInRequest;
                    if (replyResp.Success &&
                        resp != null &&
                        resp.IsLoggedIn &&
                        null != resp.UserProfile.RolesByName.FirstOrDefault( r => string.Equals( r, "Casino Engine Manager", StringComparison.InvariantCultureIgnoreCase) ) )
                    {
                        CurrentUserSession.IsAuthenticated = true;
                        CurrentUserSession.IsSuperUser = resp.UserProfile.IsSuperUser;
                        CurrentUserSession.Roles = resp.UserProfile.RolesByName.ToArray();
                        CurrentUserSession.UserDomainID = resp.UserProfile.DomainID;
                        CurrentUserSession.UserID = resp.UserProfile.UserRec.ID;

                        if (!string.IsNullOrWhiteSpace(request.QueryString["d_si"]))
                        {
                            bool showInactiveDomains = string.Equals(request.QueryString["d_si"], "1", StringComparison.InvariantCulture);
                            CurrentUserSession.ShowInactiveDomains = showInactiveDomains;
                        }

                        cookie = new HttpCookie("gmcoresid", sessionID);
                        cookie.HttpOnly = true;
                        filterContext.RequestContext.HttpContext.Response.Cookies.Add(cookie);
                        filterContext.Result = new RedirectResult(FilterUrlQueryString(request).ToString());
                        return;
                    }
                    else
                    {
                        cookie = new HttpCookie("gmcoresid", string.Empty);
                        cookie.HttpOnly = true;
                        filterContext.RequestContext.HttpContext.Response.Cookies.Add(cookie);
                    }
                }
            }
        }

        if (!CurrentUserSession.IsAuthenticated)
        {
            filterContext.Result = new ContentResult() { Content = @"Access Denied.", ContentType = "text/html" };
            return;
        }


        // 
        long currentDomainID = 0;
        if (long.TryParse(filterContext.RouteData.Values["domainID"] as string, out currentDomainID) &&
            currentDomainID > 0 &&
            CurrentUserSession.UserDomainID == Constant.SystemDomainID )
        {
            DomainManager.CurrentDomainID = currentDomainID;
        }
        else
        {
            DomainManager.CurrentDomainID = CurrentUserSession.UserDomainID;
        }
    }

    private string FilterUrlQueryString(HttpRequestBase request)
    {
        StringBuilder url = new StringBuilder();
        url.Append(request.Path);
        url.Append("?");
        foreach (string key in request.QueryString.Keys)
        {
            if (string.Equals(key, "session_id", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(key, "d_id", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(key, "all_d", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(key, "d_si", StringComparison.OrdinalIgnoreCase))
            {
                continue;
            }

            url.AppendFormat("{0}={1}&", HttpUtility.UrlEncode(key), HttpUtility.UrlEncode(request.QueryString[key]));
        }
        if (url[url.Length - 1] == '&' ||
            url[url.Length - 1] == '?')
        {
            url.Remove(url.Length - 1, 1);
        }
        return url.ToString();
    }

    private void SetCachePolicy(AuthorizationContext filterContext)
    {
        // ** IMPORTANT **
        // Since we're performing authorization at the action level, the authorization code runs
        // after the output caching module. In the worst case this could allow an authorized user
        // to cause the page to be cached, then an unauthorized user would later be served the
        // cached page. We work around this by telling proxies not to cache the sensitive page,
        // then we hook our custom authorization code into the caching mechanism so that we have
        // the final say on whether a page should be served from the cache.
        HttpCachePolicyBase cachePolicy = filterContext.HttpContext.Response.Cache;
        cachePolicy.SetProxyMaxAge(new TimeSpan(0));
        cachePolicy.AddValidationCallback(CacheValidateHandler, null /* data */);
    }

    private void CacheValidateHandler(HttpContext context, object data, ref HttpValidationStatus validationStatus)
    {
        validationStatus = OnCacheAuthorization(new HttpContextWrapper(context));
    }
}

    
