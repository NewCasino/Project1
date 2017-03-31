using System;
using System.Web;
using System.Web.Mvc;
using Casino;
using CM.Sites;
using CM.State;
using CM.Web;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Controllers.Shared
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{gameID}")]
    public class CasinoLoaderController : ControllerEx
    {
        [HttpGet]
        public ActionResult NetEntGame(string gameID)
        {
            if (CustomProfileEx.Current.IsAuthenticated && CustomProfileEx.Current.IsInRole("Withdraw only"))
                return this.View("RestrictedCountry");

            Game game = (new GameID(VendorID.NetEnt, gameID)).GetGame();
            if (game == null)
                throw new HttpException(404, "Game not found.");

            return this.View("GameLoader", game);
        }

        [HttpGet]
        public ActionResult NetEnt(string gameID, bool? realMoney, bool? disableAudio, bool? maintainAspectRatio, string ticketId)
        {
            if (CustomProfileEx.Current.IsAuthenticated && CustomProfileEx.Current.IsInRole("Withdraw only"))
                return this.View("RestrictedCountry");

            Game game = (new GameID(VendorID.NetEnt, gameID)).GetGame();
            if (game == null)
                throw new Exception("Game not found.");

            this.ViewData["ticketId"] = ticketId;
            this.ViewData["disableAudio"] = disableAudio != null && disableAudio.Value;
            this.ViewData["gameID"] = gameID;
            this.ViewData["maintainAspectRatio"] = !maintainAspectRatio.HasValue || maintainAspectRatio.Value;
            this.ViewData["realMoney"] = CustomProfile.Current.IsAuthenticated && realMoney != null && realMoney.Value;

            if ((bool)this.ViewData["realMoney"] == false && !string.IsNullOrWhiteSpace(ticketId))
            {
                throw new UnauthorizedAccessException("Ticket-based tournament requires login.");
            }

            return this.View("NetEntLoader", game);
        }

        [HttpGet]
        public ActionResult Microgaming(string gameID, bool? realMoney)
        {
            if (CustomProfileEx.Current.IsAuthenticated && CustomProfileEx.Current.IsInRole("Withdraw only"))
                return this.View("RestrictedCountry");

            Game game = (new GameID(VendorID.Microgaming, gameID)).GetGame();
            if (game == null)
                throw new HttpException(404, "Game not found.");

            this.ViewData["gameID"] = gameID;
            this.ViewData["realMoney"] = CustomProfile.Current.IsAuthenticated && realMoney != null && realMoney.Value;
            return this.View("MicrogamingLoader", game);
        }


        [HttpGet]
        public ActionResult CTXM(string gameID, bool? realMoney)
        {
            if (CustomProfileEx.Current.IsAuthenticated && CustomProfileEx.Current.IsInRole("Withdraw only"))
                return this.View("RestrictedCountry");

            Game game = (new GameID(VendorID.CTXM, gameID)).GetGame();
            if (game == null)
                throw new HttpException(404, "Game not found.");

            this.ViewData["gameID"] = gameID;
            this.ViewData["realMoney"] = CustomProfile.Current.IsAuthenticated && realMoney != null && realMoney.Value;
            return this.View("CTXMLoader", game);
        }  
    }
}
