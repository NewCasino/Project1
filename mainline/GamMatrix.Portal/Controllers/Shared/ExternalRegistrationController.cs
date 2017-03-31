using System;
using System.Collections.Generic;
using System.Text.RegularExpressions;
using System.Web.Mvc;
using BLToolkit.Data;
using BLToolkit.DataAccess;
using CM.Content;
using CM.db;
using CM.db.Accessor;
using CM.Misc;
using CM.Sites;
using CM.State;
using CM.Web;
using GamMatrixAPI;
using GmCore;
using OAuth;

namespace GamMatrix.CMS.Controllers.Shared
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index")]
    public class ExternalRegistrationController : RegistrationController
    {
        private string GetBaseUrl()
        {
            if (Request.IsHttps() && SiteManager.Current.HttpsPort > 0)
            {
                return string.Format("https://{0}{1}"
                        , Request.Url.Host
                        , (SiteManager.Current.HttpsPort != 443) ? (":" + SiteManager.Current.HttpsPort.ToString()) : string.Empty
                        );
            }
            else
            {
                return string.Format("http://{0}{1}"
                        , Request.Url.Host
                        , (SiteManager.Current.HttpPort != 80) ? (":" + SiteManager.Current.HttpPort.ToString()) : string.Empty
                        );
            }
        }

        public ActionResult OAuth(ExternalAuthParty authParty)
        {
            ReferrerData referrer = ReferrerData.Create(CustomProfile.Current);
            referrer.AuthParty = authParty;
            referrer.Action = ExternalAuthAction.Login;
            referrer.ReturnUrl = ExternalAuthManager.GetReturnUrl(authParty, referrer.ID);
            referrer.CallbackUrl = ExternalAuthManager.GetCallbackUrl(GetBaseUrl(), referrer.ID);
            referrer.Save();

            try
            {
                IExternalAuthClient client = ExternalAuthManager.GetClient(authParty);
                this.ViewData["FormHtml"] = client.GetExternalLoginUrl(referrer);
                return View("OAuth");
            }
            catch (Exception ex)
            {
                return this.Content(ex.Message);
            }
        }

        public ActionResult Associate(ExternalAuthParty authParty, ExternalAuthAction status)
        {
            if (!CustomProfile.Current.IsAuthenticated)
            {
                this.ViewData["ErrorCode"] = ErrorCode.NotLogin;
                return this.View("Error");
            }
            if (status == ExternalAuthAction.Unassociate)
            {
                using (var dbManager = new DbManager())
                {
                    var eua = DataAccessor.CreateInstance<ExternalLoginAccessor>(dbManager);
                    eua.DeleteExternalUserByUserID(CustomProfile.Current.DomainID, (int)authParty, CustomProfile.Current.UserID);
                    return this.View("Success");
                }
            }
            else
            {
                using (var dbManager = new DbManager())
                {
                    var eua = DataAccessor.CreateInstance<ExternalLoginAccessor>(dbManager);
                    if (eua.ExistAuthPartyExternalUserByUserName(CustomProfile.Current.DomainID, CustomProfile.Current.UserName, (int)authParty) == 0)
                    {
                        ReferrerData referrer = ReferrerData.Create(CustomProfile.Current);
                        referrer.AuthParty = authParty;
                        referrer.Action = ExternalAuthAction.Associate;
                        referrer.ReturnUrl = ExternalAuthManager.GetReturnUrl(authParty, referrer.ID);
                        referrer.CallbackUrl = ExternalAuthManager.GetCallbackUrl(GetBaseUrl(), referrer.ID);
                        referrer.Save();

                        IExternalAuthClient client = ExternalAuthManager.GetClient(authParty);
                        this.ViewData["FormHtml"] = client.GetExternalLoginUrl(referrer);
                        return View("OAuth");
                    }
                    else
                    {
                        this.ViewData["ErrorCode"] = ErrorCode.ExistedParty;
                        return this.View("Error");
                    }
                }
            }
        }

        
        public ActionResult ProcessAssociate(string username, string password, string referrerID)
        {
            if (string.IsNullOrEmpty(username) || string.IsNullOrEmpty(password))
            {
                this.ViewData["ErrorCode"] = ErrorCode.EmptyParamets;
                return this.View("Error");
            }
            try
            {
                ReferrerData referrerData = ReferrerData.Load(referrerID);

                if (referrerData.GetAssociateStatus() != AssociateStatus.Associated)
                {
                    using (var dbManager = new DbManager())
                    {
                        var ua = DataAccessor.CreateInstance<UserAccessor>(dbManager);

                        var user = ua.GetByUsername(SiteManager.Current.DomainID, username);
                        if (user != null)
                        {
                            if (PasswordHelper.CreateEncryptedPassword(user.PasswordEncMode, password) == user.Password)
                            {
                                var eua = DataAccessor.CreateInstance<ExternalLoginAccessor>(dbManager);
                                if (referrerData.Action == ExternalAuthAction.Associate)
                                {
                                    eua.Create(referrerData.DomainID, user.ID, (int)referrerData.AuthParty, referrerData.ExternalID);
                                    return this.View("Success");
                                }
                            }
                        }
                        else
                            this.ViewData["ErrorCode"] = ErrorCode.ConfirmError;
                    }
                }
                else
                    this.ViewData["ErrorCode"] = ErrorCode.ExistedExternalUser;

                return this.View("Error");
            }
            finally
            {
                ReferrerData.Delete(referrerID);
            }
        }

        public ActionResult Callback(string referrerID)
        {
            try
            {
                if (string.IsNullOrEmpty(referrerID))
                {
                    this.ViewData["ErrorCode"] = ErrorCode.ReferrerIDIsEmpty;
                    return this.View("Error");
                }

                var referrerData = ReferrerData.Load(referrerID);
                if (referrerData.Action == ExternalAuthAction.Error)
                {
                    return this.Content(referrerData.ErrorMessage);
                }

                if (string.IsNullOrWhiteSpace(referrerData.ExternalUserInfo.ID))
                {
                    this.ViewData["ErrorCode"] = ErrorCode.ErrorToken;
                    return this.View("Error");
                }

                ViewData["referrerID"] = referrerData.ID;
                switch (referrerData.Action)
                {
                    case ExternalAuthAction.Associate:
                        return this.View("Confirm");

                    case ExternalAuthAction.Login:
                        {
                            var status = referrerData.GetAssociateStatus();
                            if (status == AssociateStatus.Associated)
                            {
                                //already associated, login the user automatic.
                                if (!AuthParty_Setting.Enable_Login)
                                {
                                    return this.View("Callback");
                                    //this.ViewData["ErrorCode"] = ErrorCode.Disenable_Login;
                                    //return this.View("Error");
                                }

                                var user = FindUser(referrerData);
                                if (user == null)
                                {
                                    this.ViewData["ErrorCode"] = ErrorCode.NoAssociatedUser;
                                    return this.View("Error");
                                }

                                var result = CustomProfile.Current.AsCustomProfile()
                                                          .Login(user.Username, string.Empty, string.Empty,
                                                                 LoginMode.ExternalLogin);

                                if (result == CustomProfile.LoginResult.Success)
                                {
                                    //return this.View("Success");
                                    return this.View("Callback");
                                }

                                if (result == CustomProfile.LoginResult.EmailNotVerified)
                                {
                                    if (Settings.NumberOfDaysForLoginWithoutEmailVerification > 0)
                                        this.ViewData["ErrorCode"] =
                                            string.Format(Metadata.Get("/Metadata/ServerResponse.Login_EmailNotVerified"),
                                                          Settings.NumberOfDaysForLoginWithoutEmailVerification);
                                    else
                                        this.ViewData["ErrorCode"] =
                                            Metadata.Get("/Metadata/ServerResponse.Login_EmailNotVerified_DoNotAllowLogin");
                                }
                                else
                                    this.ViewData["ErrorCode"] =
                                        Metadata.Get(string.Format("/Metadata/ServerResponse.Login_{0}", result));
                            }
                            else if (status == AssociateStatus.EmailAlreadyRegistered)
                            {
                                //the user is exists.
                                return this.View("Callback");
                            }
                            else
                            {
                                //the user is not exists, go to register page.
                                if (!AuthParty_Setting.Enable_Register)
                                {
                                    this.ViewData["ErrorCode"] = ErrorCode.Disenable_Register;
                                    return this.View("Error");
                                }

                                //return Redirect("/Register?referrerID=" + referrerID);
                                return View("Callback");
                            }
                        }
                        break;

                    default:
                        this.ViewData["ErrorCode"] = ErrorCode.ErrorAction;
                        break;
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Content(ex.Message);
            }
            return View("Error");
        }

        private cmUser FindUser(ReferrerData referrer)
        {
            using (var dbManager = new DbManager())
            {
                var ula = DataAccessor.CreateInstance<ExternalLoginAccessor>(dbManager);
                var ua = DataAccessor.CreateInstance<UserAccessor>(dbManager);

                var externalLogin = ula.GetUserByKey(referrer.ExternalID, referrer.DomainID, (int)referrer.AuthParty);
                if (externalLogin == null)
                    return null;

                return ua.GetByID(externalLogin.UserID);
            }
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public void ExternalRegisterAsync(
            string username,
            string firstname,
            string surname,
            string currency,
            string email,
            string password,
            string referrerID
            )
        {
            if (!string.IsNullOrEmpty(referrerID))
            {
                AsyncManager.Parameters["isValid"] = true;
                PrepareParams(
                AsyncManager
                , string.Empty
                , firstname
                , surname
                , email
                , string.Empty
                , string.Empty
                , null
                , null
                , string.Empty
                , string.Empty
                , string.Empty
                , string.Empty
                , string.Empty
                , string.Empty
                , string.Empty
                , string.Empty
                , string.Empty
                , string.Empty
                , string.Empty
                , username
                , string.Empty
                , password
                , currency
                , string.Empty
                , string.Empty
                , string.Empty
                , null
                , null
                , string.Empty
                , referrerID
            , string.Empty
            ,   string.Empty
            , string.Empty
                    );
                AsyncManager.Parameters["referrerID"] = referrerID;
            }
            else
            {
                AsyncManager.Parameters["isValid"] = false;
            }

        }
        public ViewResult ExternalRegisterCompleted(
            string title
            , string firstname
            , string surname
            , string email
            , string birth
            , string personalId
            , int country
            , int? regionID
            , string address1
            , string address2
            , string streetname
            , string streetnumber
            , string city
            , string postalCode
            , string mobilePrefix
            , string mobile
            , string phonePrefix
            , string phone
            , string avatar
            , string username
            , string alias
            , string password
            , string currency
            , string securityQuestion
            , string securityAnswer
            , string language
            , bool allowNewsEmail
            , bool allowSmsOffer
            , string affiliateMarker
            , bool? isUsernameAvailable
            , bool? isAliasAvailable
            , bool? isEmailAvailable
            , string taxCode
            , string intendedVolume
            , string dOBPlace
            , string registerCaptcha = null
            )
        {
            if (!((bool)AsyncManager.Parameters["isValid"]))
            {
                this.ViewData["ErrorCode"] = ErrorCode.Register_ValidFail;
                return View("Error");
            }
            string referrerID = string.Empty;
            ReferrerData referrerData = null;
            try
            {
                referrerID = AsyncManager.Parameters["referrerID"].ToString();
                referrerData = ReferrerData.Load(referrerID);
                if (referrerData == null)
                {
                    this.ViewData["ErrorCode"] = ErrorCode.Register_NullData;
                    return View("Error");
                }
                bool bolEmailExist = false;
                //check the user have register in current operator,
                using (DbManager dbManager = new DbManager())
                {
                    UserAccessor ua = DataAccessor.CreateInstance<UserAccessor>(dbManager);
                    bolEmailExist = ua.IsEmailExist(SiteManager.Current.DomainID, 0L, email);
                }
                if (bolEmailExist)
                {
                    return View("Login");
                }
                ResultStatus status = RegisterProcess(
                title
                , firstname
                , surname
                , email
                , birth
                , personalId
                , country
                , regionID
                , address1
                , address2
                , streetname
                , streetnumber
                , city
                , postalCode
                , mobilePrefix
                , mobile
                , phonePrefix
                , phone
                , avatar
                , username
                , alias
                , password
                , currency
                , securityQuestion
                , securityAnswer
                , language
                , allowNewsEmail
                , allowSmsOffer
                , affiliateMarker
                , isUsernameAvailable
                , isAliasAvailable
                , isEmailAvailable
                , taxCode
                , referrerID
            ,   intendedVolume
            ,   dOBPlace
            , registerCaptcha
                );
                if (status == ResultStatus.Success)
                {
                    using (DbManager dbManager = new DbManager())
                    {
                        ExternalLoginAccessor eua = DataAccessor.CreateInstance<ExternalLoginAccessor>(dbManager);
                        eua.Create(CustomProfile.Current.DomainID, CustomProfile.Current.UserID, (int)referrerData.AuthParty, referrerData.ExternalID);
                    }
                    try
                    {
                        using (GamMatrixClient client = GamMatrixClient.Get())
                        {
                            AddNoteRequest request = new AddNoteRequest()
                            {
                                Note = "This user is registered from " + referrerData.AuthParty.ToString(),
                                Type = NoteType.User,
                                Importance = ImportanceType.Normal,
                                TypeID = CustomProfile.Current.UserID
                            };
                            client.SingleRequest<AddNoteRequest>(request);
                        }
                    }
                    catch
                    {
                    }
                    return View("Success");
                }
                else
                {
                    this.ViewData["ErrorCode"] = ErrorCode.Register_fail;
                    return View("Error");
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorCode"] = ErrorCode.Register_Exception;
                return View("Error");
            }
            finally
            {
                if (AsyncManager.Parameters["referrerID"] != null)
                {
                    ReferrerData.Delete(AsyncManager.Parameters["referrerID"].ToString());
                }
            }
        }

        protected override void ValidationRegistrationArguments(
                string title
            , string firstname
            , string surname
            , string email
            , string birth
            , string personalId
            , int country
            , int? regionID
            , string address1
            , string address2
            , string streetname
            , string streetnumber
            , string city
            , string postalCode
            , string mobilePrefix
            , string mobile
            , string phonePrefix
            , string phone
            , string avatar
            , string username
            , string alias
            , string password
            , string currency
            , string securityQuestion
            , string securityAnswer
            , string language
            , bool allowNewsEmail
            , bool allowSmsOffer
            , string affiliateMarker
            , bool? isUsernameAvailable
            , bool? isAliasAvailable
            , bool? isEmailAvailable
            , IPLocation ipLocation
            , string taxCode
            , string referrerID
            , string intendedVolume,
            string dOBPlace
            , string registerCaptcha = null
            , string iovationBlackBox = null
            , string passport = null
            , string contractValidity = null
            )
        {
            IsQuickRegistration = true;
            List<string> errorFields = new List<string>();
            if (!Regex.IsMatch(username, @"^\w{4,20}$"))
                throw new ArgumentException(Metadata.Get("/Metadata/ServerResponse.Register_InvalidUsername"));

            if (string.IsNullOrEmpty(username))
                errorFields.Add("username");
            if (string.IsNullOrEmpty(email))
                errorFields.Add("email");
            if (string.IsNullOrEmpty(firstname))
                errorFields.Add("firstname");
            if (string.IsNullOrEmpty(surname))
                errorFields.Add("second name");
            if (string.IsNullOrEmpty(currency))
                errorFields.Add("currency");
            if (string.IsNullOrEmpty(password))
                errorFields.Add("password");
            if (Settings.Registration.IsPassportRequired && string.IsNullOrEmpty(passport))
                errorFields.Add("passport");
            if (errorFields.Count > 0)
            {
                throw new ArgumentException(
                    Metadata.Get("/Metadata/ServerResponse.Register_EmptyFields").Replace("$FIELDS$", string.Join(",", errorFields))
                );
            }
            if (isUsernameAvailable.HasValue && !isUsernameAvailable.Value)
                throw new ArgumentException(Metadata.Get("/Metadata/ServerResponse.Register_InvalidUsername"));
            if (isEmailAvailable.HasValue && !isEmailAvailable.Value)
                throw new ArgumentException(Metadata.Get("/Metadata/ServerResponse.Register_InvalidEmail"));
            if (isAliasAvailable.HasValue && !isAliasAvailable.Value)
                throw new ArgumentException(Metadata.Get("/Metadata/ServerResponse.Register_InvalidAlias"));
        }

        protected override void ValidationRegistrationBirth(string birth, out DateTime? dt)
        {
            dt = null;
        }
    }
}
