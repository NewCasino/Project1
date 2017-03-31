using System.Threading;
using System.Web.Mvc;
using CM.Sites;
using CM.Web;

namespace GamMatrix.CMS.Controllers.System
{

    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index" )]
    public class TutorialController : ControllerEx
    {

        [HttpGet]
        public ActionResult Index(string distinctName)
        {
            return View("Index");
        }

        [HttpGet]
        public ActionResult ShowView(string viewName)
        {
            return View(viewName);
        }

        [HttpPost]
        public JsonResult ValidateUsername(string username)
        {
            Thread.Sleep(3000);
            return this.Json(new
            {
                @value = username,
                @success = string.Compare(username, "sa", true) == 0,
                @error = "Username is alredy exist.(Please try 'sa')"
            });
        }
    }
}
