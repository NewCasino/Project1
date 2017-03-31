using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using CM.Sites;
using CM.State;
using CM.Web;

namespace GamMatrix.CMS.Controllers.Shared
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index")]
    public class CasinoJackpotsController : AsyncControllerEx
    {
        [HttpGet]
        [MasterPageViewData(Name = "CurrentPageClass", Value = "CasinoJackpots")]
        public ActionResult Index()
        {
            IPLocation ipLocation = IPLocation.GetByIP(Request.GetRealUserAddress());
            List<CasinoEngine.JackpotInfo> jackpots = new List<CasinoEngine.JackpotInfo>();

            var allJackpots = CasinoEngine.GameMgr.GetOriginalJackpotsData().OrderByDescending(j => j.Amount["EUR"]).ToList();
            foreach (CasinoEngine.JackpotInfo jackpot in allJackpots)
            {
                if (jackpot.Games != null)
                {
                    for (int i = jackpot.Games.Count - 1; i >= 0; i--)
                    {
                        if (!jackpot.Games[i].IsAvailable)
                        {
                            jackpot.Games.RemoveAt(i);
                            continue;
                        }
                    }
                }

                jackpots.Add(jackpot);
            }

            return this.View(jackpots);
        }
    }
}
