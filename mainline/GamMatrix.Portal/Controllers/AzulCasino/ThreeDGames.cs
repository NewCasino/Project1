using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using CasinoEngine;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.State;
using CM.Web;
using Finance;
using GmCore;

namespace GamMatrix.CMS.Controllers.AzulCasino
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{category}")]
    public class ThreeDGamesController : AsyncControllerEx
    {
        [HttpGet]
        [MasterPageViewData(Name = "CurrentPageClass", Value = "CasinoHall")]
        [CompressFilter]
        public ActionResult Index(string category)
        {
            this.ViewData["CurrentCategory"] = category;
            return this.View("Index");
        }


        [CompressFilter]
        public ContentResult GameData(int maxNumOfNewGame, int maxNumOfPopularGame, bool? includeDesc)
        {
            string js;
            try
            {
                if (!includeDesc.HasValue)
                    includeDesc = false;
                js = GameMgr.GetAllGamesJson(maxNumOfNewGame, maxNumOfPopularGame, includeDesc.HasValue);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                js = string.Format("{{ \"success\" : false, \"error\" : \"{0}\" }}", GmException.TryGetFriendlyErrorMsg(ex));
            }
            return this.Content(js, "application/json");
        }

        public ActionResult Popup(string gameid, bool realMoney)
        {
            if (realMoney && CustomProfile.Current.IsInRole("Incomplete Profile"))
            {
                return SkipToIncompleteProfile();
            }
            Dictionary<string, Game> games = CasinoEngineClient.GetGames();
            Game game = null;
            if (!games.TryGetValue(gameid, out game))
                throw new HttpException(404, "Game not found");
            this.ViewData["RealMoney"] = realMoney;
            return this.View("GameOpenerWidget/Popup", game);
        }

        public ActionResult Inline(string gameid, bool realMoney)
        {
            if (realMoney && CustomProfile.Current.IsInRole("Incomplete Profile"))
            {
                return SkipToIncompleteProfile();
            }
            Dictionary<string, Game> games = CasinoEngineClient.GetGames();
            Game game = null;
            if (!games.TryGetValue(gameid, out game))
                throw new HttpException(404, "Game not found");
            this.ViewData["RealMoney"] = realMoney;
            return this.View("GameOpenerWidget/Inline", game);
        }
        private ActionResult SkipToIncompleteProfile()
        {
            return this.Content("<html><head></head><body><script>var self=window;if(self!==window.parent){self=window.parent;}self.location='/IncompleteProfile';</script></body></html>");
        }

        public ActionResult IncentiveMessage()
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return this.View("GameNavWidget/AnonymousIncentiveMessage");

            return this.Content(string.Empty);
        }

        public ActionResult JackpotWidget(string currency)
        {
            this.ViewData["Currency"] = currency.DefaultIfNullOrEmpty("EUR");
            return this.View("JackpotWidget/Main", GetJackpotData(currency));
        }

        [HttpGet]
        public JsonResult GetJackpotJson(string currency)
        {
            try
            {
                return this.Json(new { success = true, @data = GetJackpotData(currency) }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message }, JsonRequestBehavior.AllowGet);
            }
        }

        private object GetJackpotData(string currency)
        {
            if (string.IsNullOrWhiteSpace(currency))
                currency = "EUR";

            Func<JackpotGame, bool> fun = (JackpotGame g) =>
            {
                if (CustomProfile.Current.IsAuthenticated)
                    return g.Game.IsRealMoneyModeEnabled;
                else
                    return g.Game.IsAnonymousFunModeEnabled;
            };

            decimal decMinValue = MoneyHelper.TransformCurrency("EUR", currency, Settings.MinJackpotValue);
            List<JackpotGame> games = GameMgr.GetJackpotGames().FindAll(game =>
            {
                if (game.JackpotInfo.Amount[currency] >= decMinValue)
                    return true;
                return false;
            });
            return games.Select(game =>
                     new
                     {
                         V = game.JackpotInfo.VendorID.ToString(),
                         S = game.Game.Slug.DefaultIfNullOrEmpty(game.Game.ID),
                         E = fun(game),
                         M = CustomProfile.Current.IsAuthenticated,
                         L = game.Game.LogoUrl,
                         A = string.Format(CultureInfo.InvariantCulture, "{0} {1:N0}", MoneyHelper.GetCurrencySymbol(currency), game.JackpotInfo.Amount[currency]),
                         G = game.Game.ShortName
                     }
            ).ToArray();

        }


        [HttpGet]
        public ActionResult Dialog(string returnUrl)
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return this.Redirect(string.Format(CultureInfo.InvariantCulture, "/Login/Dialog?refUrl={0}", HttpUtility.UrlEncode(returnUrl)));

            if (!CustomProfile.Current.IsEmailVerified)
            {
                UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                cmUser user = ua.GetByID(CustomProfile.Current.UserID);
                if (!user.IsEmailVerified)
                    return View("/Casino/Hall/Dialog/EmailNotVerified");
                else if (!CustomProfile.Current.IsEmailVerified)
                    CustomProfile.Current.IsEmailVerified = true;
            }

            return this.Content("X");
        }

        [HttpGet]
        public ViewResult SimilarGames(string gameID, bool? realMoney)
        {
            if (!realMoney.HasValue)
                realMoney = CustomProfile.Current.IsAuthenticated;
            this.ViewData["GameID"] = gameID;
            this.ViewData["RealMoney"] = realMoney.Value;
            return this.View("SimilarGameWidget/Main");
        }


        [HttpGet]
        public ContentResult GetSimilarGames(string gameID, int maxCount)
        {
            string js;
            try
            {
                js = string.Format(CultureInfo.InvariantCulture
                    , "{{ \"success\" : true, \"games\" : {0} }}"
                    , GameMgr.GetSimilarGameJson(gameID, ref maxCount)
                    );
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                js = string.Format(CultureInfo.InvariantCulture
                    , "{{ \"success\" : false, \"error\" : \"{0}\" }}"
                    , GmException.TryGetFriendlyErrorMsg(ex)
                    );
            }
            return this.Content(js, "application/json");
        }
    }
}
