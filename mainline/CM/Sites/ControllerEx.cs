using System;
using System.Linq;
using System.Reflection;
using System.Web.Mvc;
using System.Web.Routing;
using CM.Web;

namespace CM.Sites
{
    [CompressFilter]
    public class ControllerEx : Controller
    {
        public delegate ActionResult DynamicActionInvokedDelegate(string actionName);

        public bool EnableDynamicAction { get; set; }

        public virtual ActionResult OnDynamicActionInvoked(string actionName)
        {
            return null;
        }

        protected override void Initialize(RequestContext requestContext)
        {
            base.Initialize(requestContext);
            this.Url = new UrlHelper(requestContext, SiteManager.Current.GetRouteCollection());
        }

        public static Assembly GetControllerAssembly()
        {
            Assembly[] assemblies = AppDomain.CurrentDomain.GetAssemblies();
            Assembly found = assemblies.FirstOrDefault(a => a.GetName().Name.StartsWith("GamMatrix.CMS"));
            if (found == null)
                throw new Exception("Error, can't locate the App_Code Assembly.");
            return found;
        }

    }
}
