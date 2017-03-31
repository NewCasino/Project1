using System;
using System.Web;
using System.Web.Mvc;
using System.Web.Mvc.Resources;

namespace CM.Web
{
    [AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, AllowMultiple = false, Inherited = true)]
    public sealed class CustomValidateAntiForgeryTokenAttribute : FilterAttribute, IAuthorizationFilter
    {
            private string _salt;
            public string Salt
            {
                get
                {
                    return this._salt ?? CustomAntiForgeryConfig.Salt;
                }
                set
                {
                    this._salt = value;
                }
            }
            internal Action<HttpContextBase, string> ValidateAction
            {
                get;
                private set;
            }
            public CustomValidateAntiForgeryTokenAttribute()
                : this(new Action<HttpContextBase, string>(CustomAntiForgery.Validate))
            {
            }

            internal CustomValidateAntiForgeryTokenAttribute(Action<HttpContextBase, string> validateAction)
            {
                this.ValidateAction = validateAction;
            }

            public void OnAuthorization(AuthorizationContext filterContext)
            {
                if (!CustomAntiForgeryConfig.Enabled)
                    return;

                if (filterContext == null)
                {
                    if (CustomAntiForgeryConfig.DebugMode)
                    {
                        CM.Web.AntiForgery.Custom.Logger.Exception(new ArgumentNullException("filterContext"));
                        return;
                    }
                    else
                    {
                        throw new ArgumentNullException("filterContext");
                    }                    
                }
                if (!filterContext.HttpContext.Request.IsPost())
                {
                    return;
                }
                this.ValidateAction(filterContext.HttpContext, this.Salt);
            }
    }
}
