using System;
using System.Globalization;
using System.Web;
using System.Web.Mvc;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.State;
using CM.Web;

namespace GamMatrix.CMS.Controllers.Shared
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{parameter}")]
    public class TermsConditionsController : ControllerEx
    {
        public TermsConditionsController()
        {
            base.EnableDynamicAction = true;
        }

        public override ActionResult OnDynamicActionInvoked(string actionName)
        {
            try
            {
                this.ViewData["actionName"] = actionName;
                this.ViewData["parameter"] = ControllerContext.RouteData.Values["parameter"];
                if ( actionName == null ) return this.View("Index");
                if ( actionName.Equals("accept", StringComparison.InvariantCultureIgnoreCase) && 
                    ControllerContext.RouteData.Values["parameter"] != null && 
                    !string.IsNullOrEmpty(ControllerContext.RouteData.Values["parameter"].ToString()))
                {
                    return this.Accept(this.ViewData["parameter"].ToString());
                }
                else
                {
                    switch (actionName.ToLowerInvariant())
                    {
                        case "popup":
                            return this.PopUp();
                        case "reject":
                            return this.Reject();
                        default:
                            return this.View("Index");
                    }
                }
            }
            catch (Exception ex)
            {
                this.ViewData["ErrorMsg"] = ex.ToString();
                return this.View("Error");
            }

        }

        public enum PopupType
        {
            MustAcceptTC,
            MustAcceptTCWithMajorChange,
            MinorChange
        }

        [HttpGet]
        public ActionResult PopUp()
        {
            try
            {
                if (CustomProfile.Current.IsAuthenticated )
                {
                    string code = CustomProfile.Current.SessionID.GetHashCode().ToString(CultureInfo.InvariantCulture);
                    if (Request.Cookies[Settings.TC_ACCEPTED_COOKIE] == null ||
                        !string.Equals(Request.Cookies[Settings.TC_ACCEPTED_COOKIE].Value, code, StringComparison.InvariantCultureIgnoreCase))
                    {
                        UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                        cmUser user = ua.GetByID(CustomProfile.Current.UserID);

                        if (user.IsTCAcceptRequired.HasFlag(TermsConditionsChange.Major))
                        {
                            this.ViewData["PopupType"] = PopupType.MustAcceptTCWithMajorChange.ToString();
                        }
                        else if (!user.IsGeneralTCAccepted)
                        {
                            this.ViewData["PopupType"] = PopupType.MustAcceptTC.ToString();
                        }
                        else if (user.IsTCAcceptRequired.HasFlag(TermsConditionsChange.Minor))
                        {
                            this.ViewData["PopupType"] = PopupType.MinorChange.ToString();
                        }
                        else
                        {
                            SetTCCookies();
                            return new EmptyResult();
                        }
                        return this.View("TCPopUp");
                    }
                }
                return new EmptyResult();
            }
            catch (Exception ex)
            {
                this.ViewData["ErrorMsg"] = ex.ToString();
                return this.View("Error");
            }
        }


        private void SetTCCookies()
        {
            string code =  CustomProfile.Current.SessionID.GetHashCode().ToString(CultureInfo.InvariantCulture);
            HttpCookie cookie = new HttpCookie(Settings.TC_ACCEPTED_COOKIE, code);
            cookie.HttpOnly = true;
            cookie.Secure = false;
            cookie.Expires = DateTime.Now.AddMinutes(30);
            Response.Cookies.Add(cookie);
        }


        [HttpGet]
        public JsonResult Accept(string parameter)
        {
            try
            {
                TermsConditionsChange flag = TermsConditionsChange.No;
                int flagNum = 0;
                bool t = int.TryParse(parameter, out flagNum);
                switch (flagNum)
                {
                    case 1:
                        flag = TermsConditionsChange.Major;
                        break;
                    case 2:
                        flag = TermsConditionsChange.Minor;
                        break;
                    default:
                        flag = TermsConditionsChange.No;
                        break;
                }
                UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                ua.ClearTermsConditionsFlag(CustomProfile.Current.UserID, flag);
                SetTCCookies();
                return this.Json(new { @success = true, @error = string.Empty }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                return this.Json(new { @success = false, @error = ex.ToString() }, JsonRequestBehavior.AllowGet);
            }
        }

        [HttpGet]
        public JsonResult Reject()
        {
            try
            {
                OddsMatrix.OddsMatrixProxy.Logoff();
                CustomProfile.Current.AsCustomProfile().Logoff();
                return this.Json(new { @success = true, @error = string.Empty }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.ToString() }, JsonRequestBehavior.AllowGet);
            }
        }


    }
}
