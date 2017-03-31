using System.Web.Mvc;
using CM.Sites;
using CM.Web;

namespace GamMatrix.CMS.Controllers.CaribicCasino
{
    [HandleError]
    [ValidateInput(false)]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{parameter}/{subparameter1}/{subparameter2}/{subparameter3}/{subparameter4}/{subparameter5}")]
    public class BlogContentController : ControllerEx
    {
        public BlogContentController()
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
            this.ViewData["subparameter4"] = ControllerContext.RouteData.Values["subparameter4"];
            this.ViewData["subparameter5"] = ControllerContext.RouteData.Values["subparameter5"];
            return this.View("Index");
        }
    }
}
