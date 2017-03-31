using BLToolkit.DataAccess;
using CM.Content;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.State;
using CM.Web;
using GamMatrix.CMS.Integration.OAuth;
using GamMatrixAPI;
using GmCore;
using OAuth;
using System;
using System.Web;
using System.Collections.Generic;
using System.Web.Mvc;
using System.Web.Mvc.Async;
using System.Text;
using TwoFactorAuth;
/// <summary>
/// Summary description for SessionController
/// </summary>
namespace GamMatrix.CMS.Controllers.Shared
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "SignIn")]
    public class SessionController : AsyncControllerEx
    {
        public ActionResult Index()
        {
            return this.View("Index");
        }

        public ActionResult Dialog()
        {
            return this.View("Dialog");
        }

        public ActionResult Page()
        {
            return this.View("Page");
        }

        public virtual ActionResult DKLoginPopup()
        {
            return this.View("DKLoginPopup");
        }

        public virtual ActionResult LoginSuccessDeal()
        {
            return this.PartialView("LoginSuccessDeal");
        }
        
        protected CustomProfile.LoginResult InternalSignIn(string username, string password, string securityToken, string captcha, string iovationBlackBox, string secondFactorAuthCode, bool? trustedDevice, string authType, out long userID, out SecondFactorAuthSetupCode outSecondFactorAuthSetupCode, out string phoneNumber)
        {
            userID = 0;
            cmUser user = null;

            SecondFactorAuthType secondFactorAuthType = SecondFactorAuthType.None;
            if (Settings.Session.SecondFactorAuthenticationEnabled)
            {
                if (!string.IsNullOrEmpty(authType)) 
                {
                    secondFactorAuthType = (SecondFactorAuthType)Enum.Parse(typeof(SecondFactorAuthType), authType, true);
                } else 
                {
                    secondFactorAuthType = SecondFactorAuthType.GoogleAuthenticator;
                }
                
                /*if (hasSmartPhone.HasValue)
                {
                    if (hasSmartPhone.Value)
                        secondFactorAuthType = SecondFactorAuthType.GoogleAuthenticator;
                    else
                        secondFactorAuthType = SecondFactorAuthType.GeneralAuthCode;
                }*/
            }

            CustomProfile.LoginResult result = CustomProfile.Current.AsCustomProfile().Login(username, password, securityToken, captcha, secondFactorAuthCode, secondFactorAuthType, false, out user, out outSecondFactorAuthSetupCode, out phoneNumber);

            

            if (Settings.IovationDeviceTrack_Enabled && user != null)
            {
                Logger.Information("Iovation", "Checking Iovation when Login");
                
                if (!GamMatrixClient.IovationCheck(user.ID, IovationEventType.Login, iovationBlackBox, null))
                {
                    result = CustomProfile.LoginResult.IovationDeny;
                    CustomProfile.Current.AsCustomProfile().Logoff();

                    return result;
                }
            }

            if (Settings.IsDKLicense && Settings.EnableDKRegisterWithoutNemID)
            {                
                if (CustomProfile.Current.IsAuthenticated && user != null)
                {
                    if (Settings.CheckedNemIDNotProvidedRole && !CustomProfile.Current.IsInRole(Metadata.Get("Metadata/Settings/DKLicense.NemIDNotProvidedRoleName").DefaultIfNullOrEmpty("NemID not provided")))
                    {
                        result = CustomProfile.LoginResult.NemIDNotProvided;
                        CustomProfile.Current.AsCustomProfile().Logoff();
                        return result;
                    }

                    CheckIsRofusSelfExcludedResponse rofusResponse = DkLicenseClient.CheckIsRofusSelfExcluded(user.PersonalID);
                    if (rofusResponse != null)
                    {
                        switch (rofusResponse.Status)
                        {
                            case RofusRegistrationType.RegisteredIndefinitely:
                                result = CustomProfile.LoginResult.RofusRegisteredIndefinitely;
                                CustomProfile.Current.AsCustomProfile().Logoff();
                                break;
                            case RofusRegistrationType.RegisteredTemporarily:
                                result = CustomProfile.LoginResult.RofusRegisteredTemporarily;
                                CustomProfile.Current.AsCustomProfile().Logoff();
                                break;
                            case RofusRegistrationType.NotRegistered:
                                //result = CustomProfile.LoginResult.Success;
                                break;
                            default: //RofusRegistrationType.Failed
                                result = CustomProfile.LoginResult.RofusRegistrationFailed;
                                CustomProfile.Current.AsCustomProfile().Logoff();
                                break;
                        }
                    }
                    else
                    {
                        result = CustomProfile.LoginResult.RofusRegistrationFailed;
                        CustomProfile.Current.AsCustomProfile().Logoff();
                    }
                }
            }

            if (result == CustomProfile.LoginResult.Success)
            {
                userID = user.ID;

                if (Settings.Session.SecondFactorAuthenticationEnabled)
                {
                    if (trustedDevice.HasValue)
                    {
                        if (trustedDevice.Value)
                            SecondFactorAuthenticator.SetTrustedDevice();
                        else
                            SecondFactorAuthenticator.RemoveTrustedDevice();
                    }
                }

                GamMatrixClient.SendLoginNotificationAsync(CustomProfile.Current.UserID, CustomProfile.Current.SessionID, iovationBlackBox);
            }
            else if (result == CustomProfile.LoginResult.NoPassword)
            {
                // send the reset password email
                if (user != null)
                    // ForgotPasswordController.SendEmail(this.Url, user);
                    SendForgotPasswordEmail(this.Url, user);
            }
            else if (result == CustomProfile.LoginResult.RequiresSecondFactor_FirstTime)
            {
                if (outSecondFactorAuthSetupCode.AuthType == SecondFactorAuthType.GeneralAuthCode)
                {
                    SendSecondFactorBackupCodeEmail(user, outSecondFactorAuthSetupCode.BackupCodes);
                }
                else if (secondFactorAuthType == SecondFactorAuthType.GoogleAuthenticator)
                {
                    SendSecondFactorAuthCodeEmail(user, outSecondFactorAuthSetupCode);
                }
            }

            return result;
        }


        //  
        //   
        private void SendForgotPasswordEmail(UrlHelper urlHelper, cmUser user)
        {
            SqlQuery<cmUserKey> query = new SqlQuery<cmUserKey>();
            cmUserKey userKey = new cmUserKey();
            userKey.KeyType = "ResetPassword";
            userKey.KeyValue = Guid.NewGuid().ToString();
            userKey.UserID = user.ID;
            userKey.Expiration = DateTime.Now.AddDays(1);
            userKey.DomainID = SiteManager.Current.DomainID;
            query.Insert(userKey);
            string url = urlHelper.RouteUrlEx("ForgotPassword", new { @action = "ChangePassword", @key = userKey.KeyValue });
            // send the email
            Email mail = new Email();
            mail.LoadFromMetadata("ResetPassword", user.Language);
            mail.ReplaceDirectory["USERNAME"] = user.Username;
            mail.ReplaceDirectory["FIRSTNAME"] = user.FirstName;
            mail.ReplaceDirectory["RESETLINK"] = url;
            mail.Send(user.Email);
        }
        /// <summary>
        /// this is login method
        /// the request is sent in HTTPS if SSL is available
        /// and it will be redirected to the same http protocol to avoid cross domain in the client side
        /// </summary>
        /// <param name="username"></param>
        /// <param name="password"></param>
        /// <param name="securityToken"></param>
        /// <returns></returns>
        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public virtual ActionResult SignIn(string username, string password, string securityToken, string captcha, string baseURL, string referrerID, string iovationBlackBox = null, string authToken = null, bool? trustedDevice = null, string authType = null)
        {
            string url;
            string postfix = string.Empty;
            if (Request.IsHttps() && SiteManager.Current.HttpsPort != 443 && SiteManager.Current.HttpsPort > 0)
                postfix = string.Format(":{0}", SiteManager.Current.HttpsPort);

            if (!Request.IsHttps() && SiteManager.Current.HttpPort != 80 && SiteManager.Current.HttpPort > 0)
                postfix = string.Format(":{0}", SiteManager.Current.HttpPort);

            baseURL = string.Format("{0}://{1}{2}"
                                , Request.IsHttps() ? "https" : "http"
                                , Request.Url.Host
                                , postfix
                                );

            try
            {

                if (Settings.IovationDeviceTrack_Enabled && string.IsNullOrEmpty(iovationBlackBox))
                {
                    Logger.Error("Iovation", "got nothing from client,message from Client : {0}", Request["iovationBlackBox_info"].DefaultIfNullOrEmpty("empty"));
                    //throw new ArgumentNullException("iovationBlackBox", GamMatrixClient.GetIovationError(eventType: IovationEventType.Login));
                    //throw new ArgumentNullException();
                }

                long userID = 0;
                SecondFactorAuthSetupCode secondFactorAuthSetupCode = null;
                string phoneNumber = string.Empty;
                CustomProfile.LoginResult result = InternalSignIn(username, password, securityToken, captcha, iovationBlackBox, authToken, trustedDevice, authType, out userID, out secondFactorAuthSetupCode, out phoneNumber);

                if (result == CustomProfile.LoginResult.Success && !string.IsNullOrWhiteSpace(referrerID))
                {
                    ExternalAuthManager.SaveAssociatedExternalAccount(CustomProfile.Current.UserID, referrerID);
                }
                else if (result == CustomProfile.LoginResult.NeedChangePassword)
                {
                    string htmlNeedChangePassword = string.Format(@"<!DOCTYPE html PUBLIC ""-//W3C//DTD XHTML 1.0 Transitional//EN"" ""http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"">
                                    <html xmlns=""http://www.w3.org/1999/xhtml"">
                                    <head>
                                    <meta http-equiv=""location"" content=""URL={0}"" />
                                    <meta http-equiv=""Content-Type"" content=""text/html; charset=utf-8"" />
                                    <title></title>
                                    <meta http-equiv=""Refresh"" content=""2;URL={0}"" />
                                    </head>
                                    <body>
                                    <script type=""text/javascript"">
                                    parent.parent.parent.location = '{0}';
                                    </script>
                                    </body>
                                    </html>
                                    ", "/ChangeUnSafePassWord/Index?UN=" + username.SafeJavascriptStringEncode());
                    return this.Content(htmlNeedChangePassword, "text/html");
                    //return RedirectToAction("PassWordUnSafe", "ChangePwd");Request.CurrentExecutionFilePath.SafeJavascriptStringEncode()
                }
                url = string.Format("{0}{1}"
                        , baseURL
                        , this.Url.Action("LoginResponse", new { @success = true, @result = result, @userID = userID, @phoneNumber = phoneNumber })
                        );

                if (result == CustomProfile.LoginResult.RequiresSecondFactor_FirstTime && secondFactorAuthSetupCode != null)
                {
                    url = string.Format("{0}&secondFactorAuthQrUrl={1}&secondFactorAuthCode={2}", url, HttpUtility.UrlEncode(secondFactorAuthSetupCode.QrCodeImageUrl), HttpUtility.UrlEncode(secondFactorAuthSetupCode.SetupCode));
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);

                url = string.Format("{0}{1}"
                        , baseURL
                        , this.Url.Action("LoginResponse", new { @success = false, @error = GmException.TryGetFriendlyErrorMsg(ex) })
                        );
            }

            string html = string.Format(@"<!DOCTYPE html PUBLIC ""-//W3C//DTD XHTML 1.0 Transitional//EN"" ""http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"">
<html xmlns=""http://www.w3.org/1999/xhtml"">
<head>
<meta http-equiv=""location"" content=""URL={0}"" />
<meta http-equiv=""Content-Type"" content=""text/html; charset=utf-8"" />
<title></title>
<meta http-equiv=""Refresh"" content=""2;URL={0}"" />
</head>

<body>
<script type=""text/javascript"">
self.location = '{1}';
</script>
</body>
</html>
"
                , url.SafeHtmlEncode()
                , url.SafeJavascriptStringEncode()
                );
            return this.Content(html, "text/html");
        }



        [HttpGet]
        public ViewResult DkVerifyFrame(string username)
        {
            string cpr = Request.Cookies["dkcpr"] != null ? Request.Cookies["dkcpr"].Value : "";
            string domainID = SiteManager.Current.DomainID.ToString();
            string sessionID = CustomProfile.Current.SessionID;
            string challenge = Guid.NewGuid().ToString();
            string postAction = "/Login/DkVerifyReturn?challenge=" + challenge + (!string.IsNullOrEmpty(username) ? "&username=" + username : string.Empty);
            string dkApiUrl = DkLicenseClient.GetAPIURL(APIEventType.GenerateUserLogin, domainID, "", challenge, postAction);
            string exception = string.Empty;
            string html = string.Empty;
            var vm = new RegisterDkVerifyModel();
            try
            {
                html = DkLicenseClient.GETFileData(dkApiUrl);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                exception = ex.Message;
            }
            vm.GeneratedHTML = html;
            return View(vm);
        }

        [HttpPost]
        public JsonResult DKVerifyUsername(string username)
        {
            try
            {
                UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                cmUser user = ua.GetByUsernameOrEmail(SiteManager.Current.DomainID, username, username);
                if (user != null)
                {
                    if (string.IsNullOrEmpty(user.PersonalID))
                        return this.Json(new { @success = true, @showCprPopup = true }, JsonRequestBehavior.DenyGet);
                    else
                        return this.Json(new { @success = true, @showCprPopup = false }, JsonRequestBehavior.DenyGet);
                }
                else
                {
                    Logger.Error("DKUsernameNotExist", "the user can't be found, username: '{0}', personalid: '{1}';", username, user != null ? user.PersonalID : "null");

                    return this.Json(new { @success = false, @message = Metadata.Get("/Metadata/ServerResponse.UsernameNotExist").DefaultIfNullOrEmpty(string.Empty) }, JsonRequestBehavior.DenyGet);
                }
            }
            catch (Exception ex)
            {
                return this.Json(new { @success = false, @message = ex.Message }, JsonRequestBehavior.DenyGet);
            }
        }

        [HttpPost]
        public ViewResult DkVerifyReturn(string signature, string challenge, string username)
        {
            Console.WriteLine(signature); Console.WriteLine(challenge);
            string cprLockMsg = Metadata.Get("/Metadata/ServerResponse.CPRBlocked").DefaultIfNullOrEmpty(" CPR SelfExclusion!");
            string domainID = SiteManager.Current.DomainID.ToString();
            string requestString = DkLicenseClient.GetAPIURL(APIEventType.VerifyUserLogin, domainID);
            string decodedSignature = DkLicenseClient.Base64Decode(signature);
            bool errorStatus = NemIDErrorHandler.IsError(decodedSignature);
            string errorMsg = errorStatus ? NemIDErrorHandler.GetErrorText(decodedSignature) : "";
            var values = new Dictionary<string, string>();
            string exception = string.Empty;
            string url = "";
            string baseURL = "/";
            VerifyUserLoginResponse dkuser = new VerifyUserLoginResponse();
            CustomProfile cp = CustomProfile.Current;
            cmSite site = SiteManager.Current;

            
            try
            {
                if (errorStatus)
                {
                    exception = errorMsg;
                }
                else
                {
                    if (!string.IsNullOrWhiteSpace(username))
                    {
                        UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                        cmUser user = ua.GetByUsernameOrEmail(site.DomainID, username, username);
                        if (user != null && !string.IsNullOrEmpty(user.PersonalID))
                        {
                            values.Add("cpr", user.PersonalID);
                        }
                        else
                        {
                            Logger.Error("DKUsernameNotExist", "the user can't be found, username: '{0}', personalid: '{1}';", username, user != null ? user.PersonalID : "null");

                            dkuser = new VerifyUserLoginResponse();
                            dkuser.IsSucceded = false;
                            dkuser.ErrorDetails = Metadata.Get("/Metadata/ServerResponse.UsernameNotExist").DefaultIfNullOrEmpty(string.Empty);
                            return View(dkuser);
                        }
                    }
                    

                    values.Add("challenge", challenge);
                    values.Add("signature", signature);
                    dkuser = DkLicenseClient.POSTFileData(requestString, values);
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                AsyncManager.Parameters["exception"] = ex.Message;
            }
            if (dkuser == null)
            {
                dkuser = new VerifyUserLoginResponse();
                dkuser.IsSucceded = false;
                dkuser.ErrorDetails = "null";
            }
            if (string.IsNullOrWhiteSpace(dkuser.ErrorDetails) && dkuser.RofusStatus != RofusRegistrationType.NotRegistered)
            {
                //dkuser.ErrorDetails += cprLockMsg;
                switch (dkuser.RofusStatus)
                {
                    case RofusRegistrationType.RegisteredIndefinitely:
                        dkuser.ErrorDetails += Metadata.Get("/Metadata/ServerResponse.Login_RofusRegisteredIndefinitely").DefaultIfNullOrEmpty(" CPR SelfExclusion!");
                        break;
                    case RofusRegistrationType.RegisteredTemporarily:
                        dkuser.ErrorDetails += Metadata.Get("/Metadata/ServerResponse.Login_RofusRegisteredTemporarily").DefaultIfNullOrEmpty(" CPR SelfExclusion!");
                        break;
                    case RofusRegistrationType.Failed:
                        dkuser.ErrorDetails += Metadata.Get("/Metadata/ServerResponse.Login_RofusRegistrationFailed").DefaultIfNullOrEmpty(" CPR SelfExclusion!");
                        break;
                    default: //RofusRegistrationType.NotRegistered:
                        break;
                }
            }
            else if (dkuser.RofusStatus == RofusRegistrationType.Failed)
            {
                dkuser.ErrorDetails += "\n " + Metadata.Get("/Metadata/ServerResponse.Login_RofusRegistrationFailed").DefaultIfNullOrEmpty(" CPR SelfExclusion!"); 
            }
            else
            {
                CustomProfile.LoginResult result = cp.AsCustomProfile().LoginVIADK(cp, site, dkuser.CPR);
                if (result == CustomProfile.LoginResult.Success)
                {
                    if (Settings.IsDKLicense)
                    {
                        UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                        cmUser user = ua.GetByPersonalID(site.DomainID, dkuser.CPR);

                        if (user != null && ExternalAuthManager.GetAuthPartyStatus(site.DomainID, user.Username).Count == 0)
                        {
                            if (Settings.Registration.IsDKExternalRegister)
                            {
                                DkLicenseClient.LinkToExternalDB(user.ID, dkuser.PID);
                            }

                            if (Settings.DKLicense.IsIDQCheck)
                            {
                                DkLicenseClient.UpdateTempAccountStatus(user.ID, dkuser.PID, user.Address1, user.Birth.Value, user.FirstName, user.Surname);
                            }
                        }
                    }

                    GamMatrixClient.SendLoginNotificationAsync(cp.UserID, cp.SessionID);
                    
                    url = string.Format("{0}{1}"
                    , baseURL
                    , this.Url.Action("LoginResponse", new { @success = true, @result = result })
                    );
                }
                else
                {
                    url = string.Format("{0}{1}"
                    , baseURL
                    , this.Url.Action("LoginResponse", new { @success = false, @error = "GetCPRUserError" })
                    );
                }
                if (!string.IsNullOrEmpty(exception))
                {
                    if (dkuser == null)
                    {
                        dkuser = new VerifyUserLoginResponse();
                        dkuser.ErrorDetails = "";
                    }
                    dkuser.ErrorDetails += exception;
                }
            }
            return View(dkuser);
        }
         

        public ActionResult LoginResponse(bool success, string error, CustomProfile.LoginResult? result, long userID = 0, string secondFactorAuthQrUrl = null, string secondFactorAuthCode = null, string phoneNumber = null)
        {
            this.ViewData["Success"] = success;
            this.ViewData["Error"] = error;

            this.ViewData["SecondFactorAuthQrCodeUrl"] = secondFactorAuthQrUrl;
            this.ViewData["SecondFactorAuthSetupCode"] = secondFactorAuthCode;

            this.ViewData["PhoneNumber"] = phoneNumber;

            if (result.HasValue)
            {
                this.ViewData["LoginResult"] = result.Value;
                if (result.Value != CustomProfile.LoginResult.Success)
                {
                    if (result.Value == CustomProfile.LoginResult.EmailNotVerified)
                    {
                        if (Settings.NumberOfDaysForLoginWithoutEmailVerification > 0)
                            this.ViewData["Error"] = string.Format(Metadata.Get("/Metadata/ServerResponse.Login_EmailNotVerified"), Settings.NumberOfDaysForLoginWithoutEmailVerification);
                        else
                            this.ViewData["Error"] = Metadata.Get("/Metadata/ServerResponse.Login_EmailNotVerified_DoNotAllowLogin");
                    }
                    else if (result.Value == CustomProfile.LoginResult.Blocked)
                    {
                        string errorMessage = Metadata.Get(string.Format("/Metadata/ServerResponse.Login_{0}", result.Value));
                        if (userID > 0)
                        {
                            using (GamMatrixClient client = GamMatrixClient.Get())
                            {
                                GetUserRgSelfExclusionRequest getUserRgSelfExclusionRequest = client.SingleRequest<GetUserRgSelfExclusionRequest>(new GetUserRgSelfExclusionRequest()
                                {
                                    UserID = userID,

                                });
                                if (getUserRgSelfExclusionRequest.Record != null)
                                {
                                    string blockMessage = string.Empty;
                                    switch (getUserRgSelfExclusionRequest.Record.Period)
                                    {
                                        case SelfExclusionPeriod.CoolOffFor24Hours:
                                        case SelfExclusionPeriod.CoolOffFor7Days:
                                        case SelfExclusionPeriod.CoolOffFor30Days:
                                        case SelfExclusionPeriod.CoolOffFor3Months:
                                        case SelfExclusionPeriod.CoolOffUntilSelectedDate:
                                            blockMessage = Metadata.Get("/Metadata/ServerResponse.Login_Blocked_CoolOff");
                                            break;
                                        case SelfExclusionPeriod.SelfExclusionFor7Days:
                                        case SelfExclusionPeriod.SelfExclusionFor30Days:
                                        case SelfExclusionPeriod.SelfExclusionFor6Months:
                                        case SelfExclusionPeriod.SelfExclusionFor3Months:
                                        case SelfExclusionPeriod.SelfExclusionFor1Year:
                                        case SelfExclusionPeriod.SelfExclusionFor5Years:
                                        case SelfExclusionPeriod.SelfExclusionFor7Years:
                                        case SelfExclusionPeriod.SelfExclusionUntilSelectedDate:
                                            blockMessage = Metadata.Get("/Metadata/ServerResponse.Login_Blocked_SelfExclusion");
                                            break;
                                        case SelfExclusionPeriod.SelfExclusionPermanent:
                                            blockMessage = Metadata.Get("/Metadata/ServerResponse.Login_Blocked_SelfExclusion_Permanent");
                                            break;
                                    }

                                    errorMessage = string.Format(blockMessage, getUserRgSelfExclusionRequest.Record.ExpiryDate.ToString("dd-MM-yyyy HH:mm:ss"));
                                }
                            }
                        }
                        this.ViewData["Error"] = errorMessage;
                    }
                    else
                        this.ViewData["Error"] = Metadata.Get(string.Format("/Metadata/ServerResponse.Login_{0}", result.Value));
                }
            }
            return this.View("LoginResponse");
        }

        public ActionResult SignOut()
        {
            try
            {
                OddsMatrix.OddsMatrixProxy.Logoff();
                CustomProfile.Current.AsCustomProfile().Logoff();
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }

            var returnUrl = Request.QueryString["returnUrl"];

            return this.Redirect(returnUrl ?? "/");
        }

        public JsonResult GetSecondFactorAuthType(string username,string password)
        {
            SecondFactorAuthType sfaType = SecondFactorAuthType.None;
            try
            {
                using (BLToolkit.Data.DbManager dbManager = new BLToolkit.Data.DbManager())
                {
                    UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                    cmUser user = null;
                    CustomProfile.LoginResult result = CustomProfile.Current.AsCustomProfile().VerifyUserPassword(username, password, out user);
                    
                    if (result != CustomProfile.LoginResult.Success)
                    {
                        string message = Metadata.Get(string.Format("/Metadata/ServerResponse.Login_{0}", result));
                        message = string.IsNullOrWhiteSpace(message) ? "incorrect username and password" : message;
                        return this.Json(new { @success = false, @error = message }, JsonRequestBehavior.AllowGet);
                    }
                    if (user != null)
                    {                        
                        Enum.TryParse(user.SecondFactorType.ToString(), out sfaType);                        
                    }
                }
            }
            catch (Exception ex)
            {
                return this.Json(new { @success = false, @error = ex.Message }, JsonRequestBehavior.AllowGet);
            }
            return this.Json(new { @success = true, @type = sfaType}, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// temp method
        /// </summary>
        /// <param name="username"></param>
        /// <returns></returns>
        public JsonResult GenerateAndSendSecondFactorBackupCode(string username)
        {
            if (!CustomProfile.Current.IsAuthenticated || 
                !(CustomProfile.Current.IsInRole("CMS System Admin") || CustomProfile.Current.IsInRole("CMS Domain Admin")) )
            {
                return this.Json(new { @success = false, @error = "access denied" });
            }

            string message = "operation failed!";
            if (!string.IsNullOrWhiteSpace(username))
            {
                try
                {
                    using (BLToolkit.Data.DbManager dbManager = new BLToolkit.Data.DbManager())
                    {
                        UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                        cmUser user = CustomProfile.Current.AsCustomProfile().GetUser(username, SiteManager.Current.DomainID, ua);
                        if (user != null)
                        {
                            if(user.SecondFactorType == SecondFactorAuthType.None || user.SecondFactorType == SecondFactorAuthType.NormalLogin)
                                return this.Json(new { @success = false, @error = "the player hasn't state if he/she has a mobile phone." });

                            SecondFactorAuthSetupCode setupCode = SecondFactorAuthenticator.GenerateSetupCode(SiteManager.Current, user, user.SecondFactorType);

                            if (setupCode.AuthType == SecondFactorAuthType.GeneralAuthCode)
                            {
                                SendSecondFactorBackupCodeEmail(user, setupCode.BackupCodes, true);
                            }
                            else
                            {
                                SendSecondFactorAuthCodeEmail(user, setupCode);
                            }
                            return this.Json(new { @success = true });
                        }
                    }
                }
                catch (Exception ex)
                {
                    return this.Json(new { @success = false, @error= ex.Message });
                }
            }
            
            return this.Json(new { @success = false, @error = message });
        }

        public JsonResult ResetSendSecondAuth(string username)
        {
            if (!CustomProfile.Current.IsAuthenticated ||
                !(CustomProfile.Current.IsInRole("CMS System Admin") || CustomProfile.Current.IsInRole("CMS Domain Admin")))
            {
                return this.Json(new { @success = false, @error = "access denied" });
            }

            string message = "operation failed!";
            if (!string.IsNullOrWhiteSpace(username))
            {
                try
                {
                    using (BLToolkit.Data.DbManager dbManager = new BLToolkit.Data.DbManager())
                    {
                        UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                        cmUser user = CustomProfile.Current.AsCustomProfile().GetUser(username, SiteManager.Current.DomainID, ua);
                        if (user != null)
                        {
                            SecondFactorAuthenticator.ResetSecondFactorAuth(user.ID);
                            return this.Json(new { @success = true });
                        }
                    }
                }
                catch (Exception ex)
                {
                    return this.Json(new { @success = false, @error = ex.Message });
                }
            }

            return this.Json(new { @success = false, @error = message });
        }

        public JsonResult SetSecondFactorType(string username, int secondFactorType)
        {
            if (!CustomProfile.Current.IsAuthenticated ||
                !(CustomProfile.Current.IsInRole("CMS System Admin") || CustomProfile.Current.IsInRole("CMS Domain Admin")))
            {
                return this.Json(new { @success = false, @error = "access denied" });
            }

            string message = "operation failed!";
            if (!string.IsNullOrWhiteSpace(username))
            {
                try
                {
                    using (BLToolkit.Data.DbManager dbManager = new BLToolkit.Data.DbManager())
                    {
                        UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                        cmUser user = CustomProfile.Current.AsCustomProfile().GetUser(username, SiteManager.Current.DomainID, ua);
                        if (user != null)
                        {
                            SecondFactorAuthenticator.ResetSecondFactorAuth(user.ID);
                            SecondFactorAuthenticator.SetSecondFactorType(user.ID, secondFactorType);
                            return this.Json(new { @success = true });
                        }
                    }
                }
                catch (Exception ex)
                {
                    return this.Json(new { @success = false, @error = ex.Message });
                }
            }

            return this.Json(new { @success = false, @error = message });
        }

        private void SendSecondFactorBackupCodeEmail(cmUser user, List<string> backupCodes, bool isNewGeneration = false)
        {
            // send the email
            Email mail = new Email();
            if(isNewGeneration)
                mail.LoadFromMetadata("SecondFactorNewGenerationBackupCode", user.Language);
            else
                mail.LoadFromMetadata("SecondFactorBackupCode", user.Language);
            
            mail.ReplaceDirectory["USERNAME"] = user.Username;
            mail.ReplaceDirectory["FIRSTNAME"] = user.FirstName;

            StringBuilder sb = new StringBuilder();
            if (backupCodes != null && backupCodes.Count > 0)
            {
                for (int i = 0; i < backupCodes.Count; i++)
                {
                    mail.ReplaceDirectory["BACKUPCODE" + (i + 1)] = backupCodes[i];

                    sb.AppendFormat("<li>{0}</li>", backupCodes[i]);
                }
            }
            mail.ReplaceDirectory["BACKUPCODELIST"] = sb.ToString();

            mail.Send(user.Email);
        }
        private void SendSecondFactorAuthCodeEmail(cmUser user, SecondFactorAuthSetupCode setupCode)
        {            
            // send the email
            Email mail = new Email();
            mail.LoadFromMetadata("SecondFactorAuthCode", user.Language);
            mail.ReplaceDirectory["USERNAME"] = user.Username;
            mail.ReplaceDirectory["FIRSTNAME"] = user.FirstName;
            mail.ReplaceDirectory["QRCODEIMAGEURL"] = setupCode.QrCodeImageUrl;
            mail.ReplaceDirectory["AUTHKEY"] = setupCode.SetupCode;            

            mail.Send(user.Email);
        }

        public JsonResult ValidatePhoneNumber(string username, string phoneNumber)
        {
            try
            {
                using (BLToolkit.Data.DbManager dbManager = new BLToolkit.Data.DbManager())
                {
                    UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                    cmUser user = ua.GetByUsername(SiteManager.Current.DomainID, username);
                    if (user != null && (user.Mobile.Equals(phoneNumber) || user.Phone.Equals(phoneNumber, StringComparison.InvariantCultureIgnoreCase)))
                    {
                        HttpCookie cookie = new HttpCookie(string.Format("_hvp_{0}", user.ID), "true");
                        //cookie.HttpOnly = true;
                        cookie.Expires = DateTime.Now.AddDays(1);
                        if (!string.IsNullOrWhiteSpace(SiteManager.Current.SessionCookieDomain))
                            cookie.Domain = SiteManager.Current.SessionCookieDomain;
                        Response.Cookies.Add(cookie);
                        Logger.Information("VerifyPhone", "the user {0} verify phone number at {1} for the ip {2}", user.ID, DateTime.Now.ToString("yyyy-MM-dd hh:mm:ss"), Request.GetRealUserAddress());
                        return this.Json(new { @success = true }, JsonRequestBehavior.AllowGet);
                    }
                    else
                    {
                        return this.Json(new { @success = false }, JsonRequestBehavior.AllowGet);
                    }
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message }, JsonRequestBehavior.AllowGet);
            }
        }
    }
}