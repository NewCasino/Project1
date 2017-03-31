using System.Web.Mvc;
using CM.Sites;
using CM.Web;

namespace GamMatrix.CMS.Controllers.MobileShared
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index")]    
    public class MobileGenericPageController : ControllerEx
    {
        
        [HttpGet]
        public ActionResult Index()
        {            
            return View("Index");
        }
    }
}
