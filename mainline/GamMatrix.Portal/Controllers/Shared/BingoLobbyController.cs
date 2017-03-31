using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using Bingo;
using CM.Sites;
using CM.Web;
using GamMatrixAPI;

namespace GamMatrix.CMS.Controllers.Shared
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Home")]
    /// <summary>
    ///BingoController 的摘要说明
    /// </summary>
    public class BingoLobbyController : ControllerEx
    {
        [HttpGet]
        public ActionResult Home()
        {
            return View("Home");
        }

        [HttpGet]
        public ActionResult RoomsWidget(string ScrollBarStyle = "arrows")
        {            
            this.ViewData["ScrollBarStyle"] = ScrollBarStyle;
            return View("RoomsWidget",this.ViewData);
        }

        [HttpGet]
        public ActionResult Rooms(bool? IsFunMode, string ScrollBarStyle = "arrows")
        {
            List<BingoRoom> list = BingoManager.GetRooms();
            if (IsFunMode.HasValue)
            {
                list = list.Where(p => p.playMoneyField == IsFunMode).ToList();
            }
            this.ViewData["ScrollBarStyle"] = ScrollBarStyle;
            this.ViewData["Model"] = IsFunMode.HasValue ? IsFunMode.Value ? "fun" : "rela" : "all";
            return View("Rooms",list);
        }


        [HttpGet]
        public ActionResult JackpotRotator(int count = 2)
        {
            List<JackpotInfo> list = new List<JackpotInfo>();
            
            if(count>0)
                list = BingoManager.GetJackpotsRanking(count);
            else
                list = BingoManager.GetJackpots();

            return View("JackpotRotator", list);
        }


        [HttpGet]
        public ActionResult LastWinners(int showCount = 2, int slideConut = 1)
        {
            List<Winner> list = BingoManager.GetTopWinners();
            this.ViewData["ShowCount"] = showCount;
            this.ViewData["SlideConut"] = slideConut;
            return View("LastWinners", list);
        }

        [HttpGet]
        public ActionResult FreePlayWinners(int showCount = 5, int slideConut = 1)
        {
            List<Winner> list = BingoManager.GetFreePlayWinners();            
            this.ViewData["ShowCount"] = showCount;
            this.ViewData["SlideConut"] = slideConut;
            return View("FreePlayWinnersWidget", list);
        }

        [HttpGet]
        public ActionResult RecentDailyFreePlayWinners(int days = 7)
        {
            List<Winner> winners = BingoManager.GetHistoryFreePlayWinners(days);
            this.ViewData["days"] = days;
            return View("RecentDailyFreePlayWinnersWidget", winners);
        }
    }
}