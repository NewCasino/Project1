using System.Collections.Generic;
using System.Web;
using System.Web.Mvc;
using CasinoEngine;

using CM.Sites;
using CM.State;
using CM.Web;

namespace GamMatrix.CMS.Controllers.MobileShared
{
	[MasterPageViewData(Name = "CurrentSectionMarkup", Value = "CasinoGameSection")]
	[ControllerExtraInfo(DefaultAction = "Play", ParameterUrl = "{gameID}")]
	public class MobileCasinoGameController : ControllerEx
	{
		[MasterPageViewData(Name = "CurrentSectionMarkup", Value = "GamePlayPage")]
		public ViewResult Play(string gameID)
		{
			if (CustomProfile.Current.IsInRole("Withdraw only"))
				return View("RestrictedCountry");

			return View("Play", GetGame(gameID));
		}

		public ActionResult DirectPlay(string gameID, bool realMoney = false)
		{

            var lobbyUrl = string.Format("{0}://{1}/Casino/Lobby", Request.IsHttps() ? "https" : "http", Request.Url.Host);
            var cashieurl = string.Format("{0}://{1}/deposit", Request.IsHttps() ? "https" : "http" , Request.Url.Host);
            string gameUrl = string.Format("{0}?language={1}&casinolobbyurl={2}&cashierurl={3}"
                , GetGame(gameID).Url
                , CM.Content.MultilingualMgr.GetCurrentCulture()
                , HttpUtility.UrlEncode(lobbyUrl)
                , HttpUtility.UrlEncode(cashieurl)
                );
            
			if (!realMoney)
				return Redirect(gameUrl);
			else if (!CustomProfile.Current.IsAuthenticated)
				return Redirect(Url.RouteUrl("Login", new { @action = "Index" }));
			else
				return Redirect(gameUrl + "&_sid=" + CustomProfile.Current.SessionID);
		}	

		private Game GetGame(string gameID)
		{
			Dictionary<string, Game> games = CasinoEngineClient.GetGames();
			Game game = null;

			if (gameID == null || !games.TryGetValue(gameID, out game))
				throw new HttpException(404, "");

			return game;
		}
	}
}