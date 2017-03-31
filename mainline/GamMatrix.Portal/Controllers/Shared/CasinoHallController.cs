using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.Mvc;
using CasinoEngine;
using CM.Content;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.State;
using CM.Web;
using Finance;
using GmCore;

namespace GamMatrix.CMS.Controllers.Shared
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{category}")]
    public class CasinoHallController : AsyncControllerEx
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
                js = GameMgr.GetAllGamesJson(maxNumOfNewGame, maxNumOfPopularGame, includeDesc.Value);
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
            return this.View("/Casino/Hall/GameOpenerWidget/Popup", game);
        }

        public ActionResult MultiPopup(string gameid, bool realMoney)
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
            return this.View("/Casino/Hall/GameMultiOpenerWidget/Popup", game);
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public JsonResult GetGameData(string gameid, bool realMoney)
        {
            if (realMoney && CustomProfile.Current.IsInRole("Incomplete Profile"))
            {
                return Json(new { Success = false, Message = "Incomplete Profile" });
            }

            Dictionary<string, Game> games = CasinoEngineClient.GetGames();

            Game game = null;

            if (!games.TryGetValue(gameid, out game))
                return Json(new { Success = false, Message = "Game not found" });

            StringBuilder url = new StringBuilder();
            url.AppendFormat(CultureInfo.InvariantCulture, "{0}?funMode={1}", game.Url, !realMoney);

            var profile = ControllerContext.HttpContext.Profile.AsCustomProfile();

            if (profile.IsAuthenticated)
                url.AppendFormat(CultureInfo.InvariantCulture, "&_sid={0}", profile.SessionID);
            url.AppendFormat(CultureInfo.InvariantCulture, "&language={0}", MultilingualMgr.GetCurrentCulture());

            CasinoFavoriteGameAccessor cfga = CasinoFavoriteGameAccessor.CreateInstance<CasinoFavoriteGameAccessor>();
            long clientIdentity = 0;
            if (Request.Cookies[Settings.CLIENT_IDENTITY_COOKIE] != null)
            {
                long.TryParse(Request.Cookies[Settings.CLIENT_IDENTITY_COOKIE].Value, out clientIdentity);
            }
            bool isFavorite = cfga.IsFavoriteGame(SiteManager.Current.DomainID, profile.UserID, clientIdentity, game.ID);
            string tc = Metadata.Get("/Casino/Hall/GameOpenerWidget/_GameFrame_snippet.License_" + game.VendorID.ToString());
            string tc_default = Metadata.Get("/Casino/Hall/GameOpenerWidget/_GameFrame_snippet.License_Default");
            string tc_License = game.LicenseType.Substring(0, 1).ToUpper() + game.LicenseType.Substring(1, game.LicenseType.Length - 1);
            string tcTxt = !string.IsNullOrEmpty(tc) ? string.Format(tc, tc_License) : string.Format(tc_default, tc_License);

            var data = new
            {
                ID = game.ID,
                ElementID = string.Format(CultureInfo.InvariantCulture, "_{0}", Guid.NewGuid().ToString("N").Truncate(6)),
                Name = game.Name,
                Width = game.Width,
                Height = game.Height,
                License = game.LicenseType.ToString().ToLowerInvariant(),
                Url = url.ToString(),
                IsFavorite = isFavorite,
                RealMoney = realMoney,
                VendorID = game.VendorID.ToString(),
                TCTxt = tcTxt,
                Slug = game.Slug,
                HasHelpUrl = !string.IsNullOrWhiteSpace(game.HelpUrl),
                ContentProvider = game.ContentProvider
            };

            return Json(new { Success = true, Data = data });
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
            return this.View("/Casino/Hall/GameOpenerWidget/Inline", game);
        }
        private ActionResult SkipToIncompleteProfile()
        {
            return this.Content("<html><head></head><body><script>var self=window;if(self!==window.parent){self=window.parent;}self.location='/IncompleteProfile';</script></body></html>");
        }

        public ActionResult IncentiveMessage()
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return this.View("/Casino/Hall/GameNavWidget/AnonymousIncentiveMessage");

            return this.Content(string.Empty);
        }

        public ActionResult JackpotWidget(string currency)
        {
            this.ViewData["Currency"] = currency.DefaultIfNullOrEmpty("EUR");
            return this.View("/Casino/Hall/JackpotWidget/Main", GetJackpotData(currency));
        }

        [HttpGet]
        public ContentResult JackpotSum()
        {
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
            string currency = "EUR";
            if (CustomProfile.Current.IsAuthenticated && !string.IsNullOrEmpty(CustomProfile.Current.UserCurrency))
                currency = CustomProfile.Current.UserCurrency;
            decimal totalAmount = jackpots.Where(j => j.Games.Count > 0).Sum(j => j.Amount[currency]);

            return this.Content(string.Format("{{\"Symbol\":\"{0}\",\"Amount\":\"{1}\"}}", Metadata.Get(string.Format("Metadata/Currency/{0}.Symbol", currency).DefaultIfNullOrEmpty(currency)), string.Format("{0:n2}", totalAmount)), "application/json");
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
                if (!game.Game.Platforms.Contains(Platform.PC))
                    return false;
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
                         C = MoneyHelper.GetCurrencySymbol(currency),
                         A2 = game.JackpotInfo.Amount[currency],
                         G = game.Game.ShortName
                     }
            ).ToArray();

        }

        public JsonResult GetUserRecommendedGamesJson()
        {
            try
            {
                var games = CasinoEngineClient.GetUserRecommendedGames(Platform.PC);
                return this.Json(new
                {
                    success = true,
                    @data = ConvertGames(games)
                }
                , JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message }, JsonRequestBehavior.AllowGet);
            }
        }

        public JsonResult GetGameRecommendedGamesJson(string ids)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(ids))
                {
                    return this.Json(new { @success = false, @error = "game ids is null" }, JsonRequestBehavior.AllowGet);
                }

                ids = HttpUtility.UrlDecode(ids);

                var games = CasinoEngineClient.GetGameRecommendedGames(Platform.PC, ids.SplitToList(","));
                return this.Json(new
                {
                    success = true,
                    @data = ConvertGames(games)
                }
                , JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message }, JsonRequestBehavior.AllowGet);
            }
        }

        public JsonResult GetPopularityGamesInCountry(int? countryId)
        {
            if (countryId == null)
            {
                if (CustomProfile.Current.IsAuthenticated)
                {
                    countryId = CustomProfile.Current.UserCountryID;
                }
                else
                {
                    countryId = CustomProfile.Current.IpCountryID;
                }
            }
            try
            {

                var games = CasinoEngineClient.GetPopularityGamesInCountry(Platform.PC, countryId.Value);
                return this.Json(new
                {
                    success = true,
                    @data = ConvertGames(games)
                }
                , JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message }, JsonRequestBehavior.AllowGet);
            }

        }


        private dynamic ConvertGames(IEnumerable<Game> games)
        {
            return games.Select(game => new
            {
                @ID = game.ID
,
                @P = Math.Min(game.Popularity, 9007199254740991)
,
                @V = (int)game.VendorID
,
                @G = game.ShortName.SafeJavascriptStringEncode()
,
                @I = game.ThumbnailUrl.SafeJavascriptStringEncode()
,
                @F = (CustomProfile.Current.IsAuthenticated ? game.IsFunModeEnabled : game.IsAnonymousFunModeEnabled) ? "1" : "0"
,
                @R = (CustomProfile.Current.IsAuthenticated && game.IsRealMoneyModeEnabled) ? "1" : "0"
,
                @S = game.Slug.DefaultIfNullOrEmpty(game.ID.ToString()).SafeJavascriptStringEncode()
,
                @N = game.IsNewGame ? "1" : "0"
,
                @T = "0"
,
                @H = "0"
,
                @O = game.FPP >= 1.00M ? "1" : "0"
,
                @D = string.IsNullOrWhiteSpace(game.HelpUrl) ? "0" : "1"
,
                @L = game.LogoUrl.SafeJavascriptStringEncode()
,
                @CP = game.ContentProvider.SafeJavascriptStringEncode()

            }).ToArray();
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
            return this.View("/Casino/Hall/SimilarGameWidget/Main");
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
