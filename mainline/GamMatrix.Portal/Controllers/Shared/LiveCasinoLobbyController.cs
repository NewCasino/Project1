using System;
using System.Collections.Generic;
using System.Web;
using System.Web.Mvc;
using BLToolkit.DataAccess;
using CM.Content;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.State;
using CM.Web;
using GamMatrixAPI;
using GmCore;
using LiveCasino;

namespace GamMatrix.CMS.Controllers.Shared
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index" , ParameterUrl="{category}/")]
    /// <summary>
    ///LiveCasinoLobby Controller
    /// </summary>
    public class LiveCasinoLobbyController : AsyncControllerEx
    {
        [HttpGet]
        public ActionResult Index(string category="all")
        {
            this.ViewData["category"] = category;
            return View("Index");
        }

        [HttpGet]
        public ActionResult Games(string category)
        {
            this.ViewData["category"] = category;
            return View("Games");
        }

        [HttpGet]
        public ActionResult XPROLoader(string gameID, string limitSetID)
        {
            if (CustomProfileEx.Current.IsAuthenticated && CustomProfileEx.Current.IsInRole("Withdraw only"))
                return this.View("RestrictedCountry");

            string url = GameManager.GetLaunchUrl(gameID, limitSetID, MultilingualMgr.GetCurrentCulture());
            return this.Redirect(url);
        }

        [HttpGet]
        public ActionResult MicrogamingLoader()
        {
            if (CustomProfileEx.Current.IsAuthenticated && CustomProfileEx.Current.IsInRole("Withdraw only"))
                return this.View("RestrictedCountry");

            string url = GameManager.GetMicrogamingLiveDealerLobbyUrl(MultilingualMgr.GetCurrentCulture());
            return this.Redirect(url);
        }

        [HttpGet]
        public ActionResult LastWinners(VendorID vendorID)
        {
            if (vendorID == VendorID.XProGaming)
            {
                List<Winner> winners = GameManager.GetLastWinners();
                return this.View("XProGamingLastWinners", winners);
            }
            return this.Content("");
        }

        public JsonResult GetRecentWinners()
        {
            List<Winner> winners = null;

            try
            {
                winners = GameManager.GetLastWinners();
            }
            catch (Exception ex)
            {
                return Json(new { 
                    success = false, 
                    error = ex.Message
                }, JsonRequestBehavior.AllowGet);
            }

            return Json(new { 
                success = true,
                data = winners
            }, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Add the table id to favorite
        /// </summary>
        /// <param name="tableID"></param>
        /// <returns></returns>
        public JsonResult AddToFavorites(string tableID)
        {
            if (string.IsNullOrWhiteSpace(tableID))
                return this.Json(new { @success = true });

            long userID = 0;
            if (CustomProfile.Current.IsAuthenticated)
                userID = CustomProfile.Current.UserID;
            else
            {
                if (Request.Cookies[Settings.CLIENT_IDENTITY_COOKIE] != null)
                {
                    long.TryParse(Request.Cookies[Settings.CLIENT_IDENTITY_COOKIE].Value, out userID);
                }
                if (userID == 0)
                {
                    if (Request.Cookies[Settings.CLIENT_IDENTITY_COOKIE] == null)
                    {
                        userID = UniqueInt64.Generate() * -1;
                        HttpCookie cookie = new HttpCookie(Settings.CLIENT_IDENTITY_COOKIE, userID.ToString());
                        cookie.HttpOnly = false;
                        cookie.Secure = false;
                        cookie.Expires = DateTime.Now.AddYears(1);
                        if (!string.IsNullOrWhiteSpace(SiteManager.Current.SessionCookieDomain))
                            cookie.Domain = SiteManager.Current.SessionCookieDomain;
                        Response.Cookies.Add(cookie);
                    }
                }
            }

            try
            {
                SqlQuery<cmLiveCasinoFavoriteTable> query = new SqlQuery<cmLiveCasinoFavoriteTable>();
                cmLiveCasinoFavoriteTable favoriteTable = new cmLiveCasinoFavoriteTable()
                {
                    UserID = userID,
                    DomainID = SiteManager.Current.DomainID,
                    TableID = tableID,
                    Ins = DateTime.Now
                };
                query.Insert(favoriteTable);
            }
            catch // ignore dunplicate insert exception 
            {
            }

            return this.Json(new { @success = true }, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Remove a table from favorites
        /// </summary>
        /// <param name="tableID"></param>
        /// <returns></returns>
        public JsonResult RemoveFromFavorites(string tableID)
        {
            if (string.IsNullOrWhiteSpace(tableID))
                return this.Json(new { @success = true });


            long userID = 0;
            if (CustomProfile.Current.IsAuthenticated)
            {
                userID = CustomProfile.Current.UserID;
            }

            long clientIdentity = 0;
            if (Request.Cookies[Settings.CLIENT_IDENTITY_COOKIE] != null)
            {
                long.TryParse(Request.Cookies[Settings.CLIENT_IDENTITY_COOKIE].Value, out clientIdentity);
            }

            LiveCasinoFavoriteTableAccessor cfga = LiveCasinoFavoriteTableAccessor.CreateInstance<LiveCasinoFavoriteTableAccessor>();
            cfga.DeleteByUserID(SiteManager.Current.DomainID, userID, clientIdentity, tableID);
            return this.Json(new { @success = true }, JsonRequestBehavior.AllowGet);
        }
        
    }
}