using System.Web;
using System.Web.Mvc;
using Bingo;
using CM.Content;
using CM.Sites;
using CM.State;
using CM.Web;
using GmCore;

namespace GamMatrix.CMS.Controllers.Shared
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Loader", ParameterUrl = "{roomID}")]
    /// <summary>
    ///BingoLoaderController
    /// </summary>
    public class BingoLoaderController: ControllerEx
    {
        [HttpGet]
        public ActionResult Loader(string roomID)
        {
            if (CustomProfileEx.Current.IsAuthenticated && CustomProfileEx.Current.IsInRole("Withdraw only"))
                return this.View("RestrictedCountry");

            string url = Settings.Bingo_GameLoadBaseUrl;

            url = string.Format(url,
                roomID,
                HttpUtility.UrlEncode(BingoManager.GetSessionID()),
                MultilingualMgr.GetCurrentCulture().Truncate(2).ToUpper(),
                HttpUtility.UrlEncode(this.Url.RouteUrlEx("Deposit", new { @action="Index"}))
                );
            if (CustomProfile.Current.IsAuthenticated)
                url = string.Format("{0}&mid={1}", url, HttpUtility.UrlEncode(CustomProfile.Current.SessionID) );
            return new RedirectResult(url);
        }
    }
}