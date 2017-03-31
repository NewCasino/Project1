using System.Web.Mvc;
using CM.Sites;
using CM.Web;

namespace GamMatrix.CMS.Controllers.MobileShared
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index")]    
    public class MobileSecurePageController : ControllerEx
    {
        
        [HttpGet]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        public ActionResult Index()
        {            
            return View("Index");
        }
    }
}
