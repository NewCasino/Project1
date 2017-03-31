using System;
using System.Web;
using System.Web.Mvc;

namespace CM.Web
{
    using CM.Helpers;

    [AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, AllowMultiple = false, Inherited = true)]
    public class ValidateAntiForgeryTokenAttribute1 : Attribute
    {
        private string _salt;
        public string Salt
        {
            get
            {
                return _salt ?? String.Empty;
            }
            set
            {
                _salt = value;
            }
        }

        public void OnAuthorization(AuthorizationContext filterContext)
        {
            if (filterContext == null)
            {
                throw new ArgumentNullException("filterContext");
            }

            AntiForgery.Validate(this.Salt);
        } 
    }
}
