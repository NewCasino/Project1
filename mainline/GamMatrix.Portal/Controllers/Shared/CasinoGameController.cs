using System.Collections.Generic;
using System.Web;
using System.Web.Mvc;
using CasinoEngine;
using CM.Content;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.State;
using CM.Web;

namespace GamMatrix.CMS.Controllers.Shared
{
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{gameID}")]
    public class CasinoGameController : ControllerEx
    {
        [HttpGet]
        [MasterPageViewData(Name = "CurrentPageClass", Value = "CasinoLobby")]
        public ActionResult Index(string gameID, bool? realMoney)
        {
            Dictionary<string, Game> games = CasinoEngineClient.GetGames();
            Game game = null;
            if (!games.TryGetValue(gameID, out game))
                throw new HttpException(404, "Game not found");

            if (!realMoney.HasValue)
            {
                bool isUserEmailVerified = true;
                if (CustomProfile.Current.IsAuthenticated)
                {                    
                    if (!CustomProfile.Current.IsEmailVerified)
                    {
                        UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                        cmUser user = ua.GetByID(CustomProfile.Current.UserID);
                        if (user.IsEmailVerified)
                            CustomProfile.Current.IsEmailVerified = true;
                        else
                            isUserEmailVerified = false;
                    }
                }
                realMoney = CustomProfile.Current.IsAuthenticated && isUserEmailVerified;
            }
            if (realMoney.Value && !game.IsRealMoneyModeEnabled)
                realMoney = false;
            if (realMoney.Value && CustomProfile.Current.IsInRole("Incomplete Profile"))
            {
                return this.Redirect("/IncompleteProfile");
            }
            this.ViewData["realMoney"] = realMoney.Value;

            return this.View("Index", game);
        }

        [HttpGet]
        [MasterPageViewData(Name = "CurrentPageClass", Value = "CasinoGame")]
        public ActionResult Info(string gameID, bool? realMoney)
        {
            Dictionary<string, Game> games = CasinoEngineClient.GetGames();
            Game game = null;
            if (!games.TryGetValue(gameID, out game))
                throw new HttpException(404, "Game not found");

            if (!realMoney.HasValue)
            {
                bool isUserEmailVerified = true;
                if (CustomProfile.Current.IsAuthenticated)
                {
                    if (!CustomProfile.Current.IsEmailVerified)
                    {
                        UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                        cmUser user = ua.GetByID(CustomProfile.Current.UserID);
                        if (user.IsEmailVerified)
                            CustomProfile.Current.IsEmailVerified = true;
                        else
                            isUserEmailVerified = false;
                    }
                }
                realMoney = CustomProfile.Current.IsAuthenticated && isUserEmailVerified;
            }
            if (realMoney.Value && !game.IsRealMoneyModeEnabled)
                realMoney = false;
            if (realMoney.Value && CustomProfile.Current.IsInRole("Incomplete Profile"))
            {
                return this.Redirect("/IncompleteProfile");
            }
            this.ViewData["realMoney"] = realMoney.Value;

            return this.View("Info", game);
        }

        [HttpGet]
        public ActionResult Play(string gameID, bool? realMoney)
        {
            Dictionary<string, Game> games = CasinoEngineClient.GetGames();
            Game game = null;
            if (!games.TryGetValue(gameID, out game))
                throw new HttpException(404, "Game not found");

            if (!realMoney.HasValue)
                realMoney = CustomProfile.Current.IsAuthenticated;

            if (realMoney.Value && !game.IsRealMoneyModeEnabled)
                realMoney = false;

            var lobbyUrl = string.Format("{0}://{1}/Casino/", Request.Url.Scheme, Request.Url.Host);
            var cashieurl = string.Format("{0}://{1}/deposit", Request.Url.Scheme, Request.Url.Host);

            if (realMoney.Value)
            {
                if (CustomProfile.Current.IsInRole("Incomplete Profile"))
                {
                    return this.Redirect("/IncompleteProfile");
                }
                string url = string.Format("{0}?_sid={1}&language={2}&casinolobbyurl={3}&cashierurl={4}"
                    , game.Url
                    , HttpUtility.UrlEncode(CustomProfile.Current.SessionID)
                    , MultilingualMgr.GetCurrentCulture().ToLowerInvariant()
                     , HttpUtility.UrlEncode(lobbyUrl)
                    , HttpUtility.UrlEncode(cashieurl)
                    );
                return this.Redirect(url);
            }
            else
            {
                string url = string.Format("{0}?language={1}&casinolobbyurl={2}&cashierurl={3}"
                       , game.Url 
                       , MultilingualMgr.GetCurrentCulture().ToLowerInvariant()
                        , HttpUtility.UrlEncode(lobbyUrl)
                    , HttpUtility.UrlEncode(cashieurl)
                       );
                return this.Redirect(url);
            }
        }

        [HttpGet]
        public ActionResult Rule(string gameID)
        {
            Dictionary<string, Game> games = CasinoEngineClient.GetGames();
            Game game = null;
            if (!games.TryGetValue(gameID, out game))
                throw new HttpException(404, "Game not found");

            if (!string.IsNullOrWhiteSpace(game.HelpUrl))
            {
                string helpUrl = game.HelpUrl;
                if (HttpContext.Items["GM_Language"] != null)
                {
                    helpUrl = string.Format("{0}{1}{2}", helpUrl, helpUrl.IndexOf("?") > 0 ? "&language=" : "?language=", Server.UrlEncode(HttpContext.Items["GM_Language"].ToString()));
                }
                return this.Redirect(helpUrl);
            }
            return this.Content("<html><head></head><body><script>self.close()</script></body></html>");
        }
    }
}
