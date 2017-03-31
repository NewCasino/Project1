using System;
using System.Web;

namespace CM.Web
{
    public static class CustomAntiForgery
    {
        private static readonly CustomAntiForgeryWorker _worker = new CustomAntiForgeryWorker();
        public static HtmlString GetHtml()
        {
            if (HttpContext.Current == null)
            {
                throw new ArgumentException(CustomAntiForgeryResources.HttpContextUnavailable);
            }
            string salt = null;
            string domain = null;
            string path = null;
            return CustomAntiForgery.GetHtml(new HttpContextWrapper(HttpContext.Current), salt, domain, path);
        }
        public static HtmlString GetHtml(HttpContextBase httpContext, string salt, string domain, string path)
        {
            if (httpContext == null)
            {
                throw new ArgumentNullException("httpContext");
            }
            return CustomAntiForgery._worker.GetHtml(httpContext, salt, domain, path);
        }
        public static void Validate()
        {
            if (HttpContext.Current == null)
            {
                throw new ArgumentException(CustomAntiForgeryResources.HttpContextUnavailable);
            }
            string salt = null;
            CustomAntiForgery.Validate(new HttpContextWrapper(HttpContext.Current), salt);
        }
        public static void Validate(HttpContextBase httpContext, string salt)
        {
            if (httpContext == null)
            {
                throw new ArgumentNullException("httpContext");
            }
            CustomAntiForgery._worker.Validate(httpContext, salt);
        }
    }
}
