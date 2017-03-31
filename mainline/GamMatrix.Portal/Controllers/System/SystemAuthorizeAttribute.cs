using System;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using CM.Sites;
using CM.State;

namespace GamMatrix.CMS.Controllers.System
{
    /// <summary>
    /// The AuthorizeAttribute for system
    /// </summary>
    [AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, Inherited = true, AllowMultiple = false)]
    public sealed class SystemAuthorizeAttribute : AuthorizeAttribute
    {
        public override void OnAuthorization(AuthorizationContext filterContext)
        {
            if (filterContext == null )
            {
                throw new ArgumentNullException("filterContext");
            }

            if (!CustomProfile.Current.IsAuthenticated)
            {
                // If this is an error in AJAX request, throw exception 
                /*
                 (filterContext.HttpContext.Request.AcceptTypes != null && 
                    filterContext.HttpContext.Request.AcceptTypes.FirstOrDefault(t => string.Compare(t, "application/xml", true) == 0) != null) || 
                 */
                if (filterContext.HttpContext.Request.Url.ToString().IndexOf(@"/CasinoGameMgt/SaveTableCategoryXml/") > 0 ||
                     filterContext.HttpContext.Request.Url.ToString().IndexOf(@"/CasinoGameMgt/SaveGameCategoryXml/") > 0)
                {
                    filterContext.Result = new ContentResult() { Content = "Your session is timed out, please login!", ContentType = "text/plain" };
                    return;
                } 
                if (  filterContext.HttpContext.Request.AcceptTypes != null &&
                    filterContext.HttpContext.Request.AcceptTypes.FirstOrDefault(t => string.Compare(t, "application/json", true) == 0) != null )
                    throw new UnauthorizedAccessException("Your session is timed out, please login!"); 

                UrlHelper urlHelper = new UrlHelper(filterContext.RequestContext, SiteManager.Current.GetRouteCollection());
                string url = urlHelper.RouteUrl( "SignIn", new { @action="Index", @returnUrl=filterContext.HttpContext.Request.RawUrl});

                string html = string.Format( @"<!DOCTYPE html PUBLIC ""-//W3C//DTD XHTML 1.0 Transitional//EN"" ""http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"">
<html xmlns=""http://www.w3.org/1999/xhtml"">
    <head>
        <meta http-equiv=""Cache-Control"" content=""no-cache"" />
        <meta http-equiv=""Pragma"" content=""no-cache"" />
        <meta http-equiv=""Expires"" content=""0"" />
        <meta http-equiv=""Refresh"" content=""3;url={0}"" />
    </head>
    <body>
        <script language=""javascript"" type=""text/javascript"">
        try{{
            top.location.replace('{1}');
        }}catch(e){{}}
        top.location = '{1}';
        </script>
    </body>
</html>"
                    , url.SafeHtmlEncode()
                    , url.SafeJavascriptStringEncode()
                    );
                filterContext.Result = new ContentResult() { Content = html, ContentType = "text/html" };
                return;
            }

            if (CustomProfile.Current.IsInRole(this.Roles.Split(',')))
            {
                bool isSystemDomain = SiteManager.GetSites().Exists(d => d.DomainID == CustomProfile.Current.DomainID &&
                    string.Equals( d.DistinctName, "System", StringComparison.OrdinalIgnoreCase) );

                if( isSystemDomain && CustomProfile.Current.IsInRole("CMS System Admin") )
                {
                    SetCachePolicy(filterContext);
                    return;
                }

                string distinctName = filterContext.RequestContext.RouteData.Values["distinctName"] as string;
                if (string.IsNullOrEmpty(distinctName))
                {
                    SetCachePolicy(filterContext);
                    return;
                }

                distinctName = distinctName.DefaultDecrypt(null, true);
                bool isInDomain = SiteManager.GetSites().Exists(s => string.Equals(s.DistinctName, distinctName, StringComparison.OrdinalIgnoreCase)
                    && s.DomainID == CustomProfile.Current.DomainID);
                if (isInDomain)
                {
                    SetCachePolicy(filterContext);
                    return;
                }
            }

            filterContext.Result = new ContentResult() 
            {
                Content = string.Format("You are not allowed to access. required roles = [{0}]; my roles = [{1}]."
                , string.Join( "|", this.Roles)
                , CustomProfile.Current.RoleString)
                , ContentType = "text/plain" 
            };
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
}