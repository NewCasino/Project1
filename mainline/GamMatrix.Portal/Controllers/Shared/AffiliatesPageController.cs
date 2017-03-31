using System.Web.Mvc;
using CM.Sites;
using CM.Web;

namespace GamMatrix.CMS.Controllers.Shared
{
    [HandleError]
    [ValidateInput(false)]
    [ControllerExtraInfo(DefaultAction = "Index")]
    [MasterPageViewData(Name = "AccountPanelUrl", Value = "/Affiliates/Home/LoginForm")]
    public class AffiliatesPageController : ControllerEx
    {
        
        public ActionResult Index()
        {            
            return View("Index");
        }

        public ActionResult LoginForm()
        {
            return View("LoginForm");
        }
    }
}
