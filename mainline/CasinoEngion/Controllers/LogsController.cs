using System.Web.Mvc;

namespace CasinoEngine.Controllers
{
    [SystemAuthorize]
    public class LogsController : Controller
    {
        [HttpGet]
        public ActionResult Index()
        {
            return View();
        }

    }
}
