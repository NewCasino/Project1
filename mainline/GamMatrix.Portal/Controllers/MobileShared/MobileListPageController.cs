using System;
using System.Web.Mvc;
using CM.Sites;
using CM.Web;

namespace GamMatrix.CMS.Controllers.MobileShared
{
    [HandleError]
	[ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{parameter}")]
    public class MobileListPageController : ControllerEx
    {
        public MobileListPageController()
        {
            base.EnableDynamicAction = true;
        }

        public override ActionResult OnDynamicActionInvoked(string actionName)
        {
			if (!string.IsNullOrEmpty(actionName) && !string.Equals(actionName, "index", StringComparison.OrdinalIgnoreCase))
			{
				this.ViewData["Category"] = actionName;
				this.ViewData["SubCategory"] = ControllerContext.RouteData.Values["parameter"];
				return this.View("Content");
			}
            //this.ViewData["parameter"] = ControllerContext.RouteData.Values["parameter"];
			return this.View("Index");
        }
    }
}
