using System.Web.Mvc;
using CM.Sites;
using CM.Web;

namespace GamMatrix.CMS.Controllers.Thrills
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{parameter}")]
    public class ClassicThrillsPageController : ControllerEx
    {
 
        public ClassicThrillsPageController()
        {
            base.EnableDynamicAction = true;
        }
        public override ActionResult OnDynamicActionInvoked(string actionName)
        {
            this.ViewData["actionName"] = actionName;
            this.ViewData["parameter"] = ControllerContext.RouteData.Values["parameter"];
            return this.View("Index");
        }
    }
}