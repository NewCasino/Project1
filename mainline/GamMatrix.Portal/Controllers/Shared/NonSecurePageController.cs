using System.Web.Mvc;
using CM.Sites;
using CM.Web;

namespace GamMatrix.CMS.Controllers.Shared
{
    [HandleError]
    [ValidateInput(false)]
    [ControllerExtraInfo(DefaultAction = "Index")]
    public class NonSecurePageController : ControllerEx
    {
        
        public ActionResult Index()
        {            
            return View("Index");
        }
    }
}
