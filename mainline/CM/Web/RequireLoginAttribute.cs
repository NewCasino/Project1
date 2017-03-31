using System;
using System.Web;
using System.Web.Mvc;
using CM.State;

namespace CM.Web
{
    [AttributeUsage(AttributeTargets.Method | AttributeTargets.Class, Inherited = true, AllowMultiple = false)]
    public class RequireLoginAttribute : FilterAttribute, IAuthorizationFilter
    {
        public virtual void OnAuthorization(AuthorizationContext filterContext)
        {
            if (filterContext == null)
            {
                throw new ArgumentNullException("filterContext");
            }

            if (!CustomProfile.Current.IsAuthenticated)
            {
                string url = string.Format("/Login/?redirect={0}"
                    , HttpUtility.UrlEncode(filterContext.HttpContext.Request.RawUrl)
                    );
                filterContext.Result = new RedirectResult(url);
            }
        }

    }
}
