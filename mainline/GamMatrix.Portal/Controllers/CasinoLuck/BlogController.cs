using System.Web.Mvc;
using CM.Sites;
using CM.Web;

namespace GamMatrix.CMS.Controllers.CasinoLuck
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{parameter}/{subparameter1}/{subparameter2}/{subparameter3}")]
    public class BlogController : ControllerEx
    {
        public BlogController()
        {
            base.EnableDynamicAction = true;
        }

        public override ActionResult OnDynamicActionInvoked(string actionName)
        {
            this.ViewData["actionName"] = actionName;
            this.ViewData["parameter"] = ControllerContext.RouteData.Values["parameter"];
            this.ViewData["subparameter1"] = ControllerContext.RouteData.Values["subparameter1"];
            this.ViewData["subparameter2"] = ControllerContext.RouteData.Values["subparameter2"];
            this.ViewData["subparameter3"] = ControllerContext.RouteData.Values["subparameter3"];
            return this.View("Index");
        }
    }
}
