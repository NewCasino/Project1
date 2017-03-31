using System;
using System.Web.Mvc;
using CM.Sites;
using CM.State;
using CM.Web;

namespace GamMatrix.CMS.Controllers.System
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index")]
    public class SignInController : ControllerEx
    {
        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult Index()
        {
            if( Request.Url.ToString().IndexOf(".gammatrix.com", StringComparison.InvariantCultureIgnoreCase) > 0 )
            {
                if (!Request.IsHttps() &&
                    string.Equals( Request.HttpMethod, "GET", StringComparison.InvariantCultureIgnoreCase) &&
                    SiteManager.Current.HttpsPort > 0 )
                {
                    string url = string.Format("https://{0}{1}{2}"
                        , Request.Url.Host
                        , (SiteManager.Current.HttpsPort != 443) ? (":" + SiteManager.Current.HttpsPort.ToString()) : string.Empty
                        , Request.RawUrl
                        );
                    return Redirect(url);
                }
            }
            return View();
        }
        
        [HttpPost]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult Login()
        {
            try
            {
                string username = Request["username"];
                string password = Request["password"];
                string securityToken = Request["securityToken"];
                CustomProfile.LoginResult result = CustomProfile.Current.AsCustomProfile().Login(username, password, securityToken);

                return this.Json(new { @success = true, @result = Enum.GetName(result.GetType(), result) });
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message });
            }
        }


        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult Logout()
        {
            if (CustomProfile.Current.IsAuthenticated)
                CustomProfile.Current.Logoff();

            return this.Redirect("/");
        }

    }// class
}// namespace
