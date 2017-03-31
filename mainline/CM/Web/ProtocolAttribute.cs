using System;
using System.Web.Mvc;
using CM.Sites;

namespace CM.Web
{
    [AttributeUsage(AttributeTargets.Method | AttributeTargets.Class, Inherited = true, AllowMultiple = false)]
    public class ProtocolAttribute : FilterAttribute, IAuthorizationFilter
    {
        public enum ProtocolAction
        {
            RequireHttp,
            RequireHttps,
        }

        public ProtocolAction Action { get; set; }

        public virtual void OnAuthorization(AuthorizationContext filterContext)
        {
            if (filterContext == null)
            {
                throw new ArgumentNullException("filterContext");
            }

            if (string.Equals(filterContext.HttpContext.Request.HttpMethod, "GET", StringComparison.OrdinalIgnoreCase) &&
                !filterContext.HttpContext.Request.IsAjaxRequest() )
            {
                if (this.Action == ProtocolAction.RequireHttp && filterContext.HttpContext.Request.IsHttps())
                {
                    string url = string.Format( "http://{0}{1}{2}"
                        , filterContext.HttpContext.Request.Url.Host
                        , (SiteManager.Current.HttpPort != 80) ? (":" + SiteManager.Current.HttpPort.ToString()) : string.Empty
                        , filterContext.HttpContext.Request.RawUrl
                        );
                    filterContext.Result = new RedirectResult(url);
                }
                else if (this.Action == ProtocolAction.RequireHttps &&
                        !filterContext.HttpContext.Request.IsHttps() &&
                        SiteManager.Current.HttpsPort > 0 )
                {
                    string url = string.Format( "https://{0}{1}{2}"
                        , filterContext.HttpContext.Request.Url.Host
                        , (SiteManager.Current.HttpsPort != 443) ? (":" + SiteManager.Current.HttpsPort.ToString()) : string.Empty
                        , filterContext.HttpContext.Request.RawUrl
                        );
                    filterContext.Result = new RedirectResult(url);
                }
            }
        }

    }
}
