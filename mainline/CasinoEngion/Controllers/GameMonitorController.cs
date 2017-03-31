using System.Web.Mvc;

namespace CasinoEngine.Controllers
{
    [SystemAuthorize]
    public class GameMonitorController : Controller
    {
        [HttpGet]
        public ActionResult Index()
        {
            return View();
        }

    }
}
