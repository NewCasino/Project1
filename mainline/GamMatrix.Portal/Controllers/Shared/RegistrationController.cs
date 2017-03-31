using BLToolkit.Data;
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
using Newtonsoft.Json;
using OAuth;
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Globalization;
using System.Text;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Mvc;
using System.Web.Mvc.Async;

namespace GamMatrix.CMS.Controllers.Shared
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index")]
    public class RegistrationController : AsyncControllerEx
    {
        protected bool IsQuickRegistration { get; set; }

        [OutputCache(Duration = 0, VaryByParam = "None")]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        public virtual ActionResult Index()
        {
            var referrerID = Request.QueryString["referrerID"];
            if (!string.IsNullOrEmpty(referrerID))
            {
                var referrerData = ReferrerData.Load(referrerID);
                this.ViewData["ReferrerData"] = referrerData;
            }

            return View("Index");
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public JsonResult VerifyUniquePersonalID(string personalID, string message)
        {
            try
            {

                bool isExist = false;
                if (!string.IsNullOrWhiteSpace(personalID))
                {
                    using (DbManager dbManager = new DbManager())
                    {
                        long userID = 0L;
                        if (CustomProfile.Current.IsAuthenticated)
                            userID = CustomProfile.Current.UserID;
                        UserAccessor ua = DataAccessor.CreateInstance<UserAccessor>(dbManager);
                        using (CodeProfiler.Step(1, "Registration - VerifyUniquePersonalID"))
                        {
                            isExist = ua.IsPersonalIDExist(SiteManager.Current.DomainID, userID, personalID);
                        }
                    }
                }
                return this.Json(new
                {
                    @value = personalID,
                    @success = !isExist,
                    @error = isExist ? message : string.Empty
                });
            }
            catch (Exception ex)
            {
                return this.Json(new
                {
                    @value = personalID,
                    @success = false,
                    @error = ex.Message
                });
            }
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public JsonResult VerifyRegisterCaptcha(string registerCaptcha, string message)
        {
            try
            {

                bool isValid = false;
                if (Settings.Registration.IsCaptchaRequired)
                {
                    string captchaToCompare = CustomProfile.Current.Get("captcha");

                    if (string.Equals(registerCaptcha.Trim(), captchaToCompare, StringComparison.InvariantCultureIgnoreCase))
                    {
                        isValid = true;
                    }
                }
                return this.Json(new
                {
                    @value = registerCaptcha,
                    @success = isValid,
                    @error = !isValid ? message : string.Empty
                });
            }
            catch (Exception ex)
            {
                return this.Json(new
                {
                    @value = registerCaptcha,
                    @success = false,
                    @error = ex.Message
                });
            }
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public JsonResult VerifyUniqueMobile(string mobilePrefix, string mobile, string message)
        {
            try
            {
                bool isExist = false;
                if (!string.IsNullOrWhiteSpace(mobilePrefix) && !string.IsNullOrWhiteSpace(mobile))
                {
                    using (DbManager dbManager = new DbManager())
                    {
                        long userID = 0L;
                        if (CustomProfile.Current.IsAuthenticated)
                            userID = CustomProfile.Current.UserID;
                        UserAccessor ua = DataAccessor.CreateInstance<UserAccessor>(dbManager);
                        using (CodeProfiler.Step(1, "Registration - VerifyUniqueMobile"))
                        {
                            isExist = ua.IsMobileExist(SiteManager.Current.DomainID, userID, mobilePrefix, mobile);
                        }
                    }
                }
                return this.Json(new
                {
                    @value = string.Format("{0} {1}", mobilePrefix, mobile),
                    @success = !isExist,
                    @error = isExist ? message : string.Empty
                });
            }
            catch (Exception ex)
            {
                return this.Json(new
                {
                    @value = string.Format("{0} {1}", mobilePrefix, mobile),
                    @success = false,
                    @error = ex.Message
                });
            }
        }

        [HttpGet]
        public JsonResult GetRegionsByCountry(int countryID)
        {
            var regions = CountryManager.GetCountryRegions(countryID)
                .Select(r => new { @DisplayName = r.GetDisplayName(), @ID = r.ID })
                .OrderBy(r => r.DisplayName)
                .ToArray();

            return this.Json(new { @success = true, @regions = regions, @countryID = countryID.ToString() }, JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public void VerifyUniqueEmailAsync(string email, string message)
        {
            AsyncManager.Parameters["email"] = email;
            AsyncManager.Parameters["isEmailAvailable"] = true;
            AsyncManager.Parameters["message"] = message;
            try
            {
                bool isExist = false;
                if (!string.IsNullOrWhiteSpace(email))
                {
                    using (DbManager dbManager = new DbManager())
                    {
                        long userID = 0L;
                        if (CustomProfile.Current.IsAuthenticated)
                            userID = CustomProfile.Current.UserID;
                        UserAccessor ua = DataAccessor.CreateInstance<UserAccessor>(dbManager);

                        using (CodeProfiler.Step(1, "Registration - VerifyUniqueEmail"))
                        {
                            isExist = ua.IsEmailExist(SiteManager.Current.DomainID, userID, email);
                        }
                    }

                    AsyncManager.Parameters["isEmailAvailable"] = !isExist;

                    if (!isExist)
                    {
                        List<VendorRec> vendors = GamMatrixClient.GetGamingVendors();
                        if (vendors.Exists(v => v.VendorID == VendorID.EverleafNetwork))
                        {
                            AsyncManager.OutstandingOperations.Increment();
                            GamMatrixClient.IsEverleafPokerUserNameEmailAndAliasAvailableAsync(Guid.NewGuid().ToString("N").Truncate(10)
                                , email
                                , Guid.NewGuid().ToString("N").Truncate(10)
                                , OnEverleafPokerUsernameEmailAndAliasAvailableVerifyCompleted
                                );
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }
        }

        public JsonResult VerifyUniqueEmailCompleted(string email, string message)
        {
            return this.Json(new
            {
                @success = (bool)AsyncManager.Parameters["isEmailAvailable"],
                @value = email,
                @error = message,
            });
        }

        public ActionResult InvalidBtag()
        {
            if (CustomProfile.Current.IsAuthenticated)
                return this.Content(string.Empty);
            bool isInvalid = false;
            string affiliateMarker = string.Empty;
            if (Request.Cookies.AllKeys.Contains("btag"))
            {
                affiliateMarker = Server.UrlDecode(Request.Cookies["btag"].Value);
                if (!string.IsNullOrEmpty(Settings.Affiliate.Btag_FormatExpression) &&
                !Regex.IsMatch(affiliateMarker, Settings.Affiliate.Btag_FormatExpression))
                {
                    isInvalid = true;
                }
            }
            if (isInvalid)
                return this.PartialView("InvalidBtag");
            else
                return this.Content(string.Empty);
        }


        /// <summary>
        /// Verify the username is available
        /// </summary>
        /// <param name="username"></param>
        /// <param name="message"></param>
        /// <returns></returns>
        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public void VerifyUniqueUsernameAsync(string username, string message)
        {
            AsyncManager.Parameters["username"] = username;
            AsyncManager.Parameters["isUsernameAvailable"] = true;
            AsyncManager.Parameters["message"] = message;
            try
            {
                bool isExist = false;
                using (DbManager dbManager = new DbManager())
                {
                    UserAccessor ua = DataAccessor.CreateInstance<UserAccessor>(dbManager);
                    using (CodeProfiler.Step(1, "Registration - IsUsernameExist DB"))
                    {
                        isExist = ua.IsUsernameExist(SiteManager.Current.DomainID, username);
                    }

                    AsyncManager.Parameters["isUsernameAvailable"] = !isExist;
                    if (!isExist)
                    {
                        List<VendorRec> vendors = GamMatrixClient.GetGamingVendors();
                        if (Settings.Registration.UsenameAsAlias)
                        {
                            if (vendors.Exists(v => v.VendorID == GamMatrixAPI.VendorID.BingoNetwork))
                            {
                                AsyncManager.OutstandingOperations.Increment();
                                GamMatrixClient.IsAliasAvailableAsync(username, OnAliasAvailableVerifyCompleted);
                            }
                        }

                        if (vendors.Exists(v => v.VendorID == GamMatrixAPI.VendorID.EverleafNetwork))
                        {
                            AsyncManager.OutstandingOperations.Increment();
                            GamMatrixClient.IsEverleafPokerUserNameEmailAndAliasAvailableAsync(username, "dummy@fakeemail.com", username, OnEverleafPokerUsernameEmailAndAliasAvailableVerifyCompleted);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }
        }

        public JsonResult VerifyUniqueUsernameCompleted(string alias, string message)
        {
            try
            {
                bool isAvailable = (bool)AsyncManager.Parameters["isUsernameAvailable"];
                if (isAvailable && Settings.Registration.UsenameAsAlias)
                {
                    if (AsyncManager.Parameters.ContainsKey("isAliasAvailable"))
                        isAvailable = (bool)AsyncManager.Parameters["isAliasAvailable"];
                }
                return this.Json(new
                {
                    @success = isAvailable,
                    @value = AsyncManager.Parameters["username"],
                    @error = AsyncManager.Parameters["message"],
                });
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new
                {
                    @success = false,
                    @value = alias,
                    @error = GmException.TryGetFriendlyErrorMsg(ex),
                });
            }
        }

        /// <summary>
        /// Verify the alias is avialable
        /// </summary>
        /// <param name="bluff21Alias"></param>
        /// <param name="message"></param>
        /// <returns></returns>
        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public void VerifyUniqueAliasAsync(string alias, string message)
        {
            AsyncManager.Parameters["alias"] = alias;
            AsyncManager.Parameters["isAliasAvailable"] = true;
            AsyncManager.Parameters["message"] = message;

            List<VendorRec> vendors = GamMatrixClient.GetGamingVendors();
            if (vendors.Exists(v => v.VendorID == GamMatrixAPI.VendorID.BingoNetwork))
            {
                IsAliasAvailableRequest request = new IsAliasAvailableRequest()
                {
                    Alias = alias,
                };
                AsyncManager.OutstandingOperations.Increment();
                GamMatrixClient.IsAliasAvailableAsync(alias, OnAliasAvailableVerifyCompleted);
            }

            if (vendors.Exists(v => v.VendorID == GamMatrixAPI.VendorID.EverleafNetwork))
            {
                AsyncManager.OutstandingOperations.Increment();
                GamMatrixClient.IsEverleafPokerUserNameEmailAndAliasAvailableAsync(Guid.NewGuid().ToString("N").Truncate(10)
                    , "dummy@fakeemail.com"
                    , alias
                    , OnEverleafPokerUsernameEmailAndAliasAvailableVerifyCompleted
                    );
            }
        }

        protected void OnAliasAvailableVerifyCompleted(bool isAvailable)
        {
            if (!AsyncManager.Parameters.ContainsKey("isAliasAvailable") ||
                !isAvailable)
            {
                AsyncManager.Parameters["isAliasAvailable"] = isAvailable;
            }
            AsyncManager.OutstandingOperations.Decrement();
        }

        protected void OnEverleafPokerUsernameEmailAndAliasAvailableVerifyCompleted(bool isUsernameAvailable, bool isEmailAvailable, bool isAliasAvailable)
        {
            if (!AsyncManager.Parameters.ContainsKey("isUsernameAvailable") ||
                !isUsernameAvailable)
            {
                AsyncManager.Parameters["isUsernameAvailable"] = isUsernameAvailable;
            }

            if (!AsyncManager.Parameters.ContainsKey("isEmailAvailable") ||
                !isEmailAvailable)
            {
                AsyncManager.Parameters["isEmailAvailable"] = isEmailAvailable;
            }

            if (!AsyncManager.Parameters.ContainsKey("isAliasAvailable") ||
                !isAliasAvailable)
            {
                AsyncManager.Parameters["isAliasAvailable"] = isAliasAvailable;
            }

            AsyncManager.OutstandingOperations.Decrement();
        }

        public JsonResult VerifyUniqueAliasCompleted(string alias, string message)
        {
            return this.Json(new
            {
                @success = (bool)AsyncManager.Parameters["isAliasAvailable"],
                @value = AsyncManager.Parameters["alias"],
                @error = AsyncManager.Parameters["message"],
            });
        }

        protected virtual string InitUsername(string username, string email)
        {
            if (Settings.Registration.IsUseEmailForUsername)
            {
                username = email;
            }
            return username;
        }


        [HttpPost]
        public ViewResult DkVerifyReturn(string challenge, string signature)
        { 
            string cprLockMsg = Metadata.Get("/Metadata/ServerResponse.CPRBlocked").DefaultIfNullOrEmpty(" CPR SelfExclusion!");
            string cpr = Request.Cookies["dkcpr"] != null ? Request.Cookies["dkcpr"].Value : "null";
            string domainID = SiteManager.Current.DomainID.ToString(); 
            string requestString = DkLicenseClient.GetAPIURL(APIEventType.VerifyUserLogin, domainID);
            string decodedSignature = DkLicenseClient.Base64Decode(signature);
            bool errorStatus = NemIDErrorHandler.IsError(decodedSignature);
            string errorMsg = errorStatus ? NemIDErrorHandler.GetErrorText(decodedSignature) : "";
            string exception = string.Empty;
            VerifyUserLoginResponse dkuser = null;
            try
            {
                if (errorStatus)
                {
                    exception = errorMsg;
                }
                else
                {
                    var values = new Dictionary<string, string>();
                    values.Add("challenge", challenge);
                    values.Add("signature", signature);
                    values.Add("cpr", cpr);
                    dkuser = DkLicenseClient.POSTFileData(requestString, values);
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                exception = ex.Message;
            }

            if (dkuser == null)
            {
                dkuser = new VerifyUserLoginResponse();
                dkuser.ErrorDetails = "";
            }
            if (!string.IsNullOrEmpty(exception))
                dkuser.ErrorDetails += exception;
            /*if (string.IsNullOrEmpty(exception) && dkuser.RofusStatus != RofusRegistrationType.NotRegistered)
                dkuser.ErrorDetails += cprLockMsg;*/
            else
            {
                switch (dkuser.RofusStatus)
                {
                    case RofusRegistrationType.RegisteredIndefinitely:
                        dkuser.ErrorDetails += Metadata.Get("/Metadata/ServerResponse.Register_RofusRegisteredIndefinitely").DefaultIfNullOrEmpty(" CPR SelfExclusion!");
                        break;
                    case RofusRegistrationType.RegisteredTemporarily:
                        dkuser.ErrorDetails += Metadata.Get("/Metadata/ServerResponse.Register_RofusRegisteredTemporarily").DefaultIfNullOrEmpty(" CPR SelfExclusion!");
                        break;
                    case RofusRegistrationType.Failed:
                        dkuser.ErrorDetails += Metadata.Get("/Metadata/ServerResponse.Register_RofusRegistrationFailed").DefaultIfNullOrEmpty(" CPR SelfExclusion!");
                        break;
                    default: //RofusRegistrationType.NotRegistered:
                        break;
                }
            }

            return View(dkuser);
        } 

        [HttpGet]
        public JsonResult DKValidateCprAndAge(string cpr)
        {
            string domainID = SiteManager.Current.DomainID.ToString(); 
            string dkApiUrl = DkLicenseClient.GetAPIURL(APIEventType.ValidateCprAndAge, domainID, cpr);
            string html = string.Empty;
            string exception = string.Empty;
            ValidateCprAndAgeResponse result = null;
            try
            {
                html = DkLicenseClient.GETFileData(dkApiUrl);
                result = JsonConvert.DeserializeObject<ValidateCprAndAgeResponse>(html);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                exception = ex.Message;
            } 
                return string.IsNullOrWhiteSpace(exception) ? 
                this.Json(new
                {
                    @success = true,
                    @data = result,
                }, JsonRequestBehavior.AllowGet) :
                 this.Json(new
                 {
                     @success = false,
                     @errorMsg = exception,
                 }, JsonRequestBehavior.AllowGet);            
        } 


        [HttpGet]
        public JsonResult DKVerifyJson(string cpr, string address, DateTime birthDate, string userFirstName, string userLastName)
        {
            string domainID = SiteManager.Current.DomainID.ToString(); 
            string formatedBirthdate = birthDate.Year.ToString("00") + "-" + birthDate.Month.ToString("00") + "-" + birthDate.Day.ToString("00");
            string dkApiUrl = DkLicenseClient.GetAPIURL(APIEventType.ValidateCpr, domainID, cpr, "", "", address, formatedBirthdate, userFirstName, userLastName);
            string exception = string.Empty;
            string html = string.Empty; 
            try
            {
                html = DkLicenseClient.GETFileData(dkApiUrl);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                exception = ex.Message;
            }
            if (string.IsNullOrEmpty(exception))
            {
                return this.Json(new
                {
                    @success = true,
                    @data = html,
                }, JsonRequestBehavior.AllowGet);
            }
            else
            {
                return this.Json(new
                {
                    @success = false,
                    @errorMsg = exception,
                }, JsonRequestBehavior.AllowGet);
            }
        }
         

        [HttpGet]
        public ViewResult DkVerifyFrame()
        {
            string cpr = Request.Cookies["dkcpr"] != null ? Request.Cookies["dkcpr"].Value : "";
            string domainID = SiteManager.Current.DomainID.ToString(); 
            string challenge = Guid.NewGuid().ToString();
            string postAction = "/Register/DkVerifyReturn?challenge=" + challenge;
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


        /// <summary>
        /// Register user
        /// </summary>
        /// <returns></returns>
        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public virtual void RegisterAsync(string title
            , string firstname
            , string surname
            , string email
            , string birth
            , string personalId
            , int? country
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
            , bool? allowNewsEmail
            , bool? allowSmsOffer
            , string taxCode
            , string referrerID
            , string intendedVolume
            , string dOBPlace
            , string registerCaptcha
            , string iovationBlackBox = null
            , string passport = null
            , string contractValidity = null
            )
        {
            username = InitUsername(username, email);
            PrepareParams(
            AsyncManager
            , title
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
            , taxCode
            , referrerID
            , intendedVolume
            , dOBPlace
            , registerCaptcha
            , iovationBlackBox
            , passport
            , contractValidity
                );
        }// Register



        protected virtual void ValidationRegistrationArguments(string title
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
            , string intendedVolume
            , string dOBPlace
            , string registerCaptcha
            , string iovationBlackBox = null
            , string passport = null
            , string contractValidity = null
            )
        {
            List<string> errorFields = new List<string>();
            if (Settings.Registration.IsTitleRequired && string.IsNullOrEmpty(title))
                errorFields.Add("title");

            if (Settings.Registration.IsFirstnameRequired && string.IsNullOrEmpty(firstname))
                errorFields.Add("firstname");

            if (Settings.Registration.IsSurnameRequired && string.IsNullOrEmpty(surname))
                errorFields.Add("surname");

            if (Settings.Registration.IsTitleRequired && string.IsNullOrEmpty(title))
                errorFields.Add("title");

            if (string.IsNullOrEmpty(email))
                errorFields.Add("email");

            if (Settings.Registration.IsAddress1Required && string.IsNullOrEmpty(address1))
                errorFields.Add("address1");

            if (Settings.Registration.IsStreetRequired && string.IsNullOrEmpty(streetname))
                errorFields.Add("streetname");

            if (Settings.Registration.IsStreetRequired && string.IsNullOrEmpty(streetnumber))
                errorFields.Add("streetnumber");

            if (Settings.Registration.IsCityRequired && string.IsNullOrEmpty(city))
                errorFields.Add("city");

            if (Settings.Registration.IsPostalCodeRequired && string.IsNullOrEmpty(postalCode))
                errorFields.Add("postal code");

            if (Settings.Registration.IsMobileRequired && string.IsNullOrEmpty(mobilePrefix))
                errorFields.Add("mobile prefix");

            if (Settings.Registration.IsMobileRequired && string.IsNullOrEmpty(mobile))
                errorFields.Add("mobile");

            if (Settings.Registration.IsSecurityQuestionRequired && string.IsNullOrEmpty(securityQuestion))
                errorFields.Add("security question");

            if (Settings.Registration.IsSecurityAnswerRequired && string.IsNullOrEmpty(securityAnswer))
                errorFields.Add("security answer");

            if (string.IsNullOrEmpty(username))
                errorFields.Add("username");

            if (string.IsNullOrEmpty(password))
                errorFields.Add("password");

            if (string.IsNullOrEmpty(currency))
                errorFields.Add("currency");

            if (Settings.IsDKLicense && string.IsNullOrEmpty(intendedVolume))
                errorFields.Add("intended gambling volume");

            if (Settings.IovationDeviceTrack_Enabled && string.IsNullOrEmpty(iovationBlackBox))
            {
                Logger.Error("Iovation", "got nothing from client,message from Client : {0}", Request["iovationBlackBox_info"].DefaultIfNullOrEmpty("empty"));
                //errorFields.Add("iovationBlackBox");
            }

            //if (Settings.IsDKLicense && string.IsNullOrEmpty(dOBPlace))
            //    errorFields.Add("DOB place");

            if (string.IsNullOrEmpty(language))
                errorFields.Add("language");

            if (Settings.Registration.IsCaptchaRequired && string.IsNullOrEmpty(registerCaptcha))
                errorFields.Add("registerCaptcha");

            if (Settings.Registration.IsPassportRequired && string.IsNullOrEmpty(passport))
                errorFields.Add("passport");

            if (errorFields.Count > 0)
                throw new ArgumentException(
                    Metadata.Get("/Metadata/ServerResponse.Register_EmptyFields").Replace("$FIELDS$", string.Join(",", errorFields))
                );
            ValidationRegisterCaptcha(registerCaptcha);
            //if (!Regex.IsMatch(username, @"^\w{4,20}$"))
            if (!Regex.IsMatch(username, @"^([a-z0-9A-Z_\.\@\+\-]+)$"))
                throw new ArgumentException(Metadata.Get("/Metadata/ServerResponse.Register_InvalidUsername"));

            if (isUsernameAvailable.HasValue && !isUsernameAvailable.Value)
                throw new ArgumentException(Metadata.Get("/Metadata/ServerResponse.Register_InvalidUsername"));
            if (isEmailAvailable.HasValue && !isEmailAvailable.Value)
                throw new ArgumentException(Metadata.Get("/Metadata/ServerResponse.Register_InvalidEmail"));
            if (isAliasAvailable.HasValue && !isAliasAvailable.Value)
                throw new ArgumentException(Metadata.Get("/Metadata/ServerResponse.Register_InvalidAlias"));
        }

        protected virtual void ValidationRegisterCaptcha(string registerCaptcha)
        {
            if (Settings.Registration.IsCaptchaRequired) { 
                string captchaToCompare = CustomProfile.Current.Get("captcha");
                CustomProfile.Current.Set("captcha", null);

                if (!string.Equals(registerCaptcha.Trim(), captchaToCompare, StringComparison.InvariantCultureIgnoreCase))
                {
                    throw new ArgumentException(Metadata.Get("/Components/_Captcha_ascx.Captcha_Invalid"));
                }
            }
        }

        protected virtual void ValidationRegistrationBirth(string birth, out DateTime? dt)
        {
            DateTime temp;
            if (DateTime.TryParseExact(birth, "yyyy-M-d", CultureInfo.InvariantCulture, DateTimeStyles.None, out temp))
                dt = temp;
            else if (Settings.Registration.IsBirthDateRequired)
                throw new ArgumentException(Metadata.Get("/Metadata/ServerResponse.Register_InvalidBirthdate"));
            else
                dt = null;
        }
        public virtual ViewResult RegisterCompleted(string title
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
            , string referrerID
            , string intendedVolume
            , string dOBPlace
            , string registerCaptcha
            , string iovationBlackBox = null
            , string passport = null
            , string contractValidity = null
            )
        {
            try
            {
                ResultStatus rsStatus = RegisterProcess(
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
            , intendedVolume
            , dOBPlace
            , registerCaptcha
            , iovationBlackBox
            , passport
            , contractValidity
                    );
                switch (rsStatus)
                {
                    case ResultStatus.CountryBlocked:
                        return this.View("CountryBlockedView");
                    case ResultStatus.RegionBlocked:
                        return this.View("RegionBlockedView");
                    case ResultStatus.MaxSameIPRegistrationExceeded:
                        return this.View("MaxSameIPRegistrationExceededView");
                    case ResultStatus.UsernameExist:
                        throw new ArgumentException(Metadata.Get("/Metadata/ServerResponse.Register_InvalidUsername"));
                    case ResultStatus.EmailExist:
                        throw new ArgumentException(Metadata.Get("/Metadata/ServerResponse.Register_InvalidEmail"));
                    case ResultStatus.DunplicateUserExist:
                        throw new ArgumentException(Metadata.Get("/Metadata/ServerResponse.Register_DunplicateUser"));
                    case ResultStatus.InvalidCPR:
                        throw new ArgumentException(Metadata.Get("/Metadata/ServerResponse.Register_InvalidCPR").DefaultIfNullOrEmpty("Invalid CPR"));
                    case ResultStatus.OverAgeLimit:
                        throw new ArgumentException(Metadata.Get("/Metadata/ServerResponse.Register_OverAgeLimit").DefaultIfNullOrEmpty("Over age limit"));
                    case ResultStatus.RofusRegisteredIndefinitely:
                        throw new ArgumentException(Metadata.Get("/Metadata/ServerResponse.Register_RofusRegisteredIndefinitely"));
                    case ResultStatus.RofusRegisteredTemporarily:
                        throw new ArgumentException(Metadata.Get("/Metadata/ServerResponse.Register_RofusRegisteredTemporarily"));
                    case ResultStatus.RofusRegistrationFailed:
                        throw new ArgumentException(Metadata.Get("/Metadata/ServerResponse.Register_RofusRegistrationFailed"));
                    case ResultStatus.Success:
                        return this.View("SuccessView");
                    default:
                        return this.View("ErrorView");

                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = ex.Message;
                return this.View("ErrorView");
            }
        }


        /// <summary>
        /// Activate the user
        /// </summary>
        /// <param name="email"></param>
        /// <param name="key"></param>
        /// <returns></returns>
        [HttpGet]
        public ViewResult Activate(string email, string key)
        {
            try
            {
                using (DbManager dbManager = new DbManager())
                {
                    UserKeyAccessor uka = DataAccessor.CreateInstance<UserKeyAccessor>(dbManager);
                    UserAccessor ua = DataAccessor.CreateInstance<UserAccessor>(dbManager);

                    cmUserKey userKey = uka.Get(SiteManager.Current.DomainID, key, email);

                    if (userKey == null)
                    {
                        this.ViewData["PartialView"] = "ActivationFailed";
                        return this.View("Activate");
                    }
                    else if (userKey.Expiration < DateTime.Now) // the activation link is expired
                    {
                        this.ViewData["PartialView"] = "ActivationExpiried";
                        return this.View("Activate");
                    }
                    else // success
                    {
                        string roleString = null;
                        bool IsIncompleteProfile = false;
                        if (CustomProfile.Current.IsAuthenticated)
                        {
                            if (CustomProfile.Current.IsEmailVerified) //already verified
                            {
                                this.ViewData["PartialView"] = "ActivationSucceed";
                                return this.View("Activate");
                            }

                            if (CustomProfile.Current.IsInRole("Incomplete Profile"))
                            {
                                IsIncompleteProfile = true;
                            }
                        }
                        else
                        {
                            roleString = GamMatrixClient.GetRoleString(userKey.UserID, SiteManager.Current);
                            if (!string.IsNullOrWhiteSpace(roleString) && roleString.Split(',').Contains("Incomplete Profile"))
                            {
                                IsIncompleteProfile = true;
                            }
                        }

                        cmUser user = ua.GetByID(userKey.UserID);
                        if (!IsIncompleteProfile)
                            ua.VerifyEmail(userKey.UserID);
                        else
                        {
                            user.IsEmailVerified = true;

                            this.ViewData["Firstname"] = user.FirstName;
                            this.ViewData["Username"] = user.Username;
                            this.ViewData["Email"] = user.Email;

                            GamMatrixClient.UpdateUserDetails(user);

                            //update role string of session
                            if (CustomProfile.Current.IsAuthenticated)
                            {
                                roleString = GamMatrixClient.GetRoleString(user.ID, SiteManager.Current);
                                CustomProfile.Current.RoleString = roleString;
                            }
                        }

                        CustomProfile.UpdateSessions(user.ID, (sess) =>
                        {
                            sess.IsEmailVerified = true;
                            if (roleString != null)
                            {
                                sess.Roles = roleString.Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
                                sess.IncompleteProfile = sess.Roles.Contains("Incomplete Profile");
                            }
                            return true;
                        });

                        if (Settings.Registration.SendWelcomeEmail)
                        {
                            SendWelcomeEmail(user);
                        }

                        if (!Settings.Registration.DisableAutoLogin && Settings.Registration.AutoLoginAfterActivation && !CustomProfile.Current.IsAuthenticated)
                        {
                            CustomProfile.Current.AsCustomProfile().Login(user.Username, user.Password, null, CM.Misc.LoginMode.ExternalLogin);
                        }

                        this.ViewData["PartialView"] = "ActivationSucceed";
                        return this.View("Activate");
                    }
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);

                GmException gex = ex as GmException;
                if (gex != null)
                {
                    if (gex.ReplyResponse != null && !string.IsNullOrWhiteSpace(gex.ReplyResponse.ErrorCode))
                    {
                        if (gex.ReplyResponse.ErrorCode.Equals("SYS_1034", StringComparison.OrdinalIgnoreCase))
                        {
                            this.ViewData["PartialView"] = "ActivationSucceed";
                            return this.View("Activate");
                        }
                    }
                }
                this.ViewData["PartialView"] = "ErrorView";
                this.ViewData["ErrorMessage"] = ex.Message;
                return this.View("Activate");
            }
        }// Activate

        [HttpGet]
        public JsonResult ResendVerificationEmail()
        {
            if (CustomProfile.Current.IsAuthenticated)
            {
                using (DbManager dbManager = new DbManager())
                {
                    UserAccessor ua = DataAccessor.CreateInstance<UserAccessor>(dbManager);
                    cmUser user = ua.GetByID(CustomProfile.Current.UserID);
                    if (!user.IsEmailVerified)
                    {
                        try
                        {
                            UserKeyAccessor uka = DataAccessor.CreateInstance<UserKeyAccessor>(dbManager);
                            int count = uka.GetKeyCount(SiteManager.Current.DomainID, user.ID, "Verification");
                            if (count > 5)
                            {
                                return this.Json(new
                                {
                                    @success = false,
                                    @errorCode = 2,
                                }, JsonRequestBehavior.AllowGet);
                            }

                            int ExpirationDaynum = 7;
                            string ExpirationDaynumStr = Metadata.Get("/Metadata/Email/Activation.ExpirationDaynum").DefaultIfNullOrEmpty("7");
                            int.TryParse(ExpirationDaynumStr, out ExpirationDaynum);
                            // create the cmUserKey for activation
                            SqlQuery<cmUserKey> query = new SqlQuery<cmUserKey>(dbManager);
                            cmUserKey userKey = new cmUserKey();
                            userKey.KeyType = "Verification";
                            userKey.KeyValue = Guid.NewGuid().ToString();
                            userKey.UserID = user.ID;
                            userKey.Expiration = DateTime.Now.AddDays(ExpirationDaynum);
                            userKey.DomainID = SiteManager.Current.DomainID;
                            query.Insert(userKey);

                            // send the email
                            Email mail = new Email();
                            mail.LoadFromMetadata("Activation", user.Language);
                            mail.ReplaceDirectory["USERNAME"] = user.Username;
                            mail.ReplaceDirectory["FIRSTNAME"] = user.FirstName;
                            mail.ReplaceDirectory["ACTIVELINK"] = this.Url.RouteUrlEx("Register", new { @action = "Activate", @email = user.Email, @key = userKey.KeyValue });
                            mail.Send(user.Email);
                        }
                        catch (Exception ex)
                        {
                            Logger.Exception(ex);

                            return this.Json(new
                            {
                                @success = false,
                                @errorCode = 1,
                            }, JsonRequestBehavior.AllowGet);
                        }
                    }
                }

                return this.Json(new
                {
                    @success = true,
                    @errorCode = -1,
                }, JsonRequestBehavior.AllowGet);
            }

            return this.Json(new
            {
                @success = false,
                @errorCode = 0,
            }, JsonRequestBehavior.AllowGet);
        }

        protected void PrepareParams(
            AsyncManager asyncManager
            , string title
            , string firstname
            , string surname
            , string email
            , string birth
            , string personalId
            , int? country
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
            , bool? allowNewsEmail
            , bool? allowSmsOffer
            , string taxCode
            , string referrerID
            , string intendedVolume
            , string dOBPlace
            , string registerCaptcha
            , string iovationBlackBox = null
            , string passport = null
            , string contractValidity = null
            )
        {
            if (Settings.Registration.UsenameAsAlias && !string.IsNullOrWhiteSpace(username))
            {
                alias = username;
            }
            if (!country.HasValue)
                country = 0;

            asyncManager.Parameters["title"] = title;
            asyncManager.Parameters["firstname"] = firstname;
            asyncManager.Parameters["surname"] = surname;
            asyncManager.Parameters["email"] = email;
            asyncManager.Parameters["birth"] = birth;
            asyncManager.Parameters["personalId"] = personalId;
            asyncManager.Parameters["country"] = country;
            asyncManager.Parameters["regionID"] = regionID;
            asyncManager.Parameters["address1"] = address1;
            asyncManager.Parameters["address2"] = address2;
            asyncManager.Parameters["streetname"] = streetname;
            asyncManager.Parameters["streetnumber"] = streetnumber;
            asyncManager.Parameters["city"] = city;
            asyncManager.Parameters["postalCode"] = postalCode;
            asyncManager.Parameters["mobilePrefix"] = mobilePrefix;
            asyncManager.Parameters["mobile"] = mobile;
            asyncManager.Parameters["phonePrefix"] = phonePrefix;
            asyncManager.Parameters["phone"] = phone;
            asyncManager.Parameters["avatar"] = avatar;
            asyncManager.Parameters["username"] = username;
            asyncManager.Parameters["alias"] = alias;
            asyncManager.Parameters["password"] = password;
            asyncManager.Parameters["currency"] = currency;
            asyncManager.Parameters["securityQuestion"] = securityQuestion;
            asyncManager.Parameters["securityAnswer"] = securityAnswer;
            asyncManager.Parameters["language"] = language;
            asyncManager.Parameters["allowNewsEmail"] = allowNewsEmail.HasValue ? allowNewsEmail.Value : false;
            asyncManager.Parameters["allowSmsOffer"] = allowSmsOffer.HasValue ? allowSmsOffer.Value : false;
            asyncManager.Parameters["taxCode"] = taxCode;
            asyncManager.Parameters["referrerID"] = referrerID;
            asyncManager.Parameters["intendedVolume"] = intendedVolume;
            AsyncManager.Parameters["dOBPlace"] = dOBPlace;
            asyncManager.Parameters["iovationBlackBox"] = iovationBlackBox;
            asyncManager.Parameters["isUsernameAvailable"] = true;
            asyncManager.Parameters["isEmailAvailable"] = true;
            asyncManager.Parameters["isAliasAvailable"] = true;
            asyncManager.Parameters["registerCaptcha"] = registerCaptcha;
            AsyncManager.Parameters["passport"] = passport;
            AsyncManager.Parameters["contractValidity"] = contractValidity;


            if (Request.Cookies["btag"] != null)
            {
                string strAffiliate = Server.UrlDecode(Request.Cookies["btag"].Value);
                if (strAffiliate.Length > 64) strAffiliate = strAffiliate.Substring(0, 64);
                asyncManager.Parameters["affiliateMarker"] = strAffiliate;
            }
            List<VendorRec> vendors = GamMatrixClient.GetGamingVendors();
            if (vendors.Exists(v => v.VendorID == GamMatrixAPI.VendorID.BingoNetwork))
            {
                if (!string.IsNullOrEmpty(alias))
                {
                    asyncManager.OutstandingOperations.Increment();
                    GamMatrixClient.IsAliasAvailableAsync(alias, OnAliasAvailableVerifyCompleted);
                }
            }

            if (vendors.Exists(v => v.VendorID == GamMatrixAPI.VendorID.EverleafNetwork))
            {
                if (!string.IsNullOrEmpty(alias))
                {
                    asyncManager.OutstandingOperations.Increment();
                    GamMatrixClient.IsEverleafPokerUserNameEmailAndAliasAvailableAsync(username
                        , email
                        , alias
                        , OnEverleafPokerUsernameEmailAndAliasAvailableVerifyCompleted
                        );
                }
            }
        }
        protected enum ResultStatus
        {
            CountryBlocked,
            RegionBlocked,
            MaxSameIPRegistrationExceeded,
            UsernameExist,
            EmailExist,
            DunplicateUserExist,
            Success,
            OverAgeLimit,
            InvalidCPR,

            /// <summary>
            /// Rofus Registration status
            /// </summary>
            RofusRegistrationFailed,
            RofusRegisteredIndefinitely,
            RofusRegisteredTemporarily,
        }
        protected ResultStatus RegisterProcess(
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
            , string referrerID
            , string intendedVolume
            , string dOBPlace
            , string registerCaptcha
            , string iovationBlackBox = null
            , string passport = null
            , string contractValidity = null
        )
        {
            IPLocation ipLocation = IPLocation.GetByIP(Request.GetRealUserAddress());
            ValidationRegistrationArguments(title
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
                , ipLocation
                , taxCode
                , referrerID
                , intendedVolume
        , dOBPlace, registerCaptcha, iovationBlackBox, passport);

            DateTime? birthday = null;
            ValidationRegistrationBirth(birth, out birthday);
            int hasCountry = CountryManager.GetAllCountries().Where(c => c.UserSelectable && c.InternalID == country).Count();
            if (hasCountry == 0)
                return ResultStatus.CountryBlocked;

            // registration blocked countries
            if (ipLocation != null && ipLocation.Found)
            {
                CountryInfo countryInfo = CountryManager.GetAllCountries().FirstOrDefault(c => c.InternalID == ipLocation.CountryID);
                if (countryInfo != null && countryInfo.RestrictRegistrationByIP && !Settings.WhiteList_EMUserIPs.Contains(ipLocation.IP, StringComparer.InvariantCultureIgnoreCase))
                {
                    if (countryInfo.RestrictRegistrationByRegion && !string.IsNullOrEmpty(countryInfo.RestrictRegistrationByRegionCode))
                    {
                        if (!countryInfo.RestrictRegistrationByRegionCode.Split(new char[]{','}, StringSplitOptions.RemoveEmptyEntries).Contains(ipLocation.RegionCode))
                        {
                            Logger.Error("User is Blocked", string.Format("User {0} is blocked by region in the site {1}.", username, SiteManager.Current.DistinctName));
                            return ResultStatus.RegionBlocked;
                        }
                    }
                    else
                    {
                        Logger.Error("User is Blocked", string.Format("User {0} is blocked by country in the site {1}.", username, SiteManager.Current.DistinctName));
                        return ResultStatus.CountryBlocked;
                    }
                } 
                else
                {
                    Logger.Error("CountryInfo Load failure", string.Format("Country Info can't be load correctly,countryInfo={0},whiteList_EMUserIPs={1}, User {2} with the ip {3} register on the site {4}.",countryInfo != null, Settings.WhiteList_EMUserIPs.Contains(ipLocation.IP, StringComparer.InvariantCultureIgnoreCase),  username, Request.GetRealUserAddress(), SiteManager.Current.DistinctName));
                }

                if (ipLocation.CountryID == 231)
                {
                    Logger.Error("US user Registered", string.Format("User {0} with the ip {1} register successfully in the site {2}.", username, Request.GetRealUserAddress(), SiteManager.Current.DistinctName));
                }
            }
            else
            {
                Logger.Error("Register Location", string.Format("User {0} can't be positioned in the site {1}.", username, SiteManager.Current.DistinctName));
            }

            int signUpCountryID = 0;
            if (ipLocation != null && ipLocation.Found)
                signUpCountryID = ipLocation.CountryID;

            string pid = string.Empty;
            if (country == 64 && Settings.IsDKLicense && !Settings.EnableDKRegisterWithoutNemID)
            {
                pid = username;
                username = email;
            }

            if(Settings.IsDKLicense && Settings.Registration.IsDkTitleAutoSetByCPRNumber)
            {
                string rightCPR = personalId.Length >= 4 ? personalId.Substring(personalId.Length - 4, 4) : personalId;
                int cprNum = 0;
                if (int.TryParse(rightCPR, out cprNum))
                {
                    title = cprNum % 2 != 0 ? "Mr." : "Ms.";
                }
            }

            using (DbManager dbManager = new DbManager())
            {
                UserAccessor ua = DataAccessor.CreateInstance<UserAccessor>(dbManager);

                // check registration time for same IP within the same day
                string[] ips = Settings.Registration.SameIPLimitWhitelist;
                if (null == ips ||
                    null == ips.FirstOrDefault(i => string.Equals(i, Request.GetRealUserAddress(), StringComparison.InvariantCulture)))
                {
                    int sameIPLimitPerDay = Settings.Registration.SameIPLimitPerDay;
                    if (sameIPLimitPerDay > 0)
                    {
                        using (CodeProfiler.Step(1, "Registration - GetRegistrationNumberTodayFromIP"))
                        {
                            int total = ua.GetRegistrationNumberTodayFromIP(SiteManager.Current.DomainID, Request.GetRealUserAddress());
                            if (total > 0 && sameIPLimitPerDay <= total)
                            {
                                return ResultStatus.MaxSameIPRegistrationExceeded;
                            }
                        }
                    }
                }
                using (CodeProfiler.Step(1, "Registration - IsUsernameExist"))
                {
                    if (
                        Settings.IsDKLicense &&
                        ua.GetByPersonalID(SiteManager.Current.DomainID, personalId) != null)
                        return ResultStatus.UsernameExist;

                    if (ua.IsUsernameExist(SiteManager.Current.DomainID, username))
                        return ResultStatus.UsernameExist;
                }
                using (CodeProfiler.Step(1, "Registration - IsEmailExist"))
                {
                    if (ua.IsEmailExist(SiteManager.Current.DomainID, 0L, email))
                        return ResultStatus.EmailExist;
                }

                // Registration - Check DK user 's cpr & age
                using (CodeProfiler.Step(1, "Registration - Check DK user 's cpr & age"))
                {
                    if (country == 64 && Settings.IsDKLicense  )
                    {
                        if (Settings.Registration.IsVerifyCprAndAge) {
                            ValidateCprAndAgeResponse ucar = DkLicenseClient.ValidateAgeAndCpr(personalId);
                            if (ucar.AgeStatus == AgeStatusType.AgeIs17OrBelow) {
                                return ResultStatus.OverAgeLimit;
                            }
                            if (ucar.CprStatus == CPRStatusType.CPRIsNotRegistered) {
                                return ResultStatus.InvalidCPR;
                            }
                        }

                        if (Settings.EnableDKRegisterWithoutNemID)
                        {
                            try
                            {
                                CheckIsRofusSelfExcludedResponse rofusResponse = DkLicenseClient.CheckIsRofusSelfExcluded(personalId);
                                if (rofusResponse != null)
                                {
                                    switch (rofusResponse.Status)
                                    {
                                        case RofusRegistrationType.RegisteredIndefinitely:
                                            return ResultStatus.RofusRegisteredIndefinitely;
                                        case RofusRegistrationType.RegisteredTemporarily:
                                            return ResultStatus.RofusRegisteredTemporarily;
                                        case RofusRegistrationType.NotRegistered:
                                            Logger.Information("CheckIsRofusSelfExcluded", string.Format("CPR:{0};RofusRegistrationType is NotRegistered", personalId));
                                            break;
                                        default: //RofusRegistrationType.Failed
                                            return ResultStatus.RofusRegistrationFailed;
                                    }
                                }
                                else
                                {
                                    return ResultStatus.RofusRegistrationFailed;
                                }
                            } catch(Exception ex)
                            {
                                Logger.Error("CheckIsRofusSelfExcluded", string.Format("CPR:{0}\nException:{1}", personalId, ex.Message));
                                return ResultStatus.RofusRegistrationFailed;
                            }
                            
                        }
                    }
                }

                if (birthday.HasValue && Settings.Registration.EnableLgaDunplicateAccountVerification)
                {
                    using (CodeProfiler.Step(1, "Registration - IsDunplicateUserExist"))
                    {
                        if (ua.IsDunplicateUserExist(SiteManager.Current.DomainID, firstname, surname, birthday.Value))
                            return ResultStatus.DunplicateUserExist;
                    }
                }

                if (!string.IsNullOrWhiteSpace(streetname) && !string.IsNullOrWhiteSpace(streetnumber))
                {
                    address1 = string.Format("{0} {1}", streetname, streetnumber);
                }

                bool IsProfileCompleted = true;
                if (string.IsNullOrWhiteSpace(address1) ||
                    string.IsNullOrWhiteSpace(postalCode) ||
                    string.IsNullOrWhiteSpace(mobile) ||
                    string.IsNullOrWhiteSpace(securityQuestion) ||
                    string.IsNullOrWhiteSpace(securityAnswer) ||
                    string.IsNullOrWhiteSpace(city) ||
                    string.IsNullOrWhiteSpace(title) ||
                    string.IsNullOrWhiteSpace(firstname) ||
                    string.IsNullOrWhiteSpace(surname) ||
                    string.IsNullOrWhiteSpace(currency) ||
                    string.IsNullOrWhiteSpace(language) ||
                    country <= 0 ||
                    !birthday.HasValue)
                {
                    IsProfileCompleted = false;
                }
                DateTime? nullDateTime = null;
                long userID = 0L;
                using (CodeProfiler.Step(1, "Registration - Insert cmUser table"))
                {
                    userID = ua.Create(title
                        , firstname
                        , surname
                        , string.Format("{0} {1}", firstname, surname)
                        , personalId
                        , alias
                        , avatar
                        , string.Compare(title, "Mr.", true) == 0 ? 'M' : 'F'
                        , username
                        , PasswordHelper.CreateEncryptedPassword(SiteManager.Current.PasswordEncryptionMode, password)
                        , SiteManager.Current.PasswordEncryptionMode
                        , email
                        , !Settings.Registration.RequireActivation
                        , securityQuestion
                        , securityAnswer
                        , country
                        , regionID
                        , Request.GetRealUserAddress()
                        , signUpCountryID
                        , address1
                        , address2
                        , streetname
                        , streetnumber
                        , postalCode
                        , city
                        , birthday
                        , currency
                        , mobilePrefix
                        , mobile
                        , string.IsNullOrEmpty(phone) ? string.Empty : phonePrefix
                        , phone
                        , SiteManager.Current.DomainID
                        , language
                        , affiliateMarker
                        , allowNewsEmail
                        , allowSmsOffer
                        , taxCode
                        , DateTime.Now
                        , IsProfileCompleted ? DateTime.Now : nullDateTime
                        , string.IsNullOrEmpty(intendedVolume) ? 0 : int.Parse(intendedVolume)
                        , dOBPlace
                        , Request.Browser.IsMobileDevice
                        );
                }

                if (!String.IsNullOrEmpty(passport))
                {
                    Match m = Regex.Match(passport, @"(\w+):(?<ContentType>[\s\S]*?);base64,(?<Image>.+)", RegexOptions.IgnoreCase);
                    if (m.Success)
                    {
                        try
                        {
                            string contentType = m.Groups["ContentType"].Value;
                            byte[] passportImage = Convert.FromBase64String(m.Groups["Image"].Value);
                            string filename = string.Format("{0}.{1}", Guid.NewGuid().ToString("N").Substring(0, new Random().Next(1, 8)), contentType.Split(new char[] { '/' })[1].ToLowerInvariant());
                            long passportID = GamMatrixClient.AddUserImageRequest(userID, filename, contentType, passportImage, true);
                        }
                        catch (Exception exx)
                        {
                            Logger.Error("UploadImage", string.Format("incorrect passport format, userid:{0}, source: {1}, exception:{2}", userID, passport, exx.Message));
                        }
                        
                    }
                    else
                    {
                        Logger.Error("UploadImage", string.Format("incorrect passport format, userid:{0}, source: {1}", userID, passport));
                    }
                    
                }

                if (Settings.EnableContract && !string.IsNullOrWhiteSpace(contractValidity))
                {
                    GamMatrixClient.SetUserLicenseLTContractValidityRequest(userID, contractValidity, language);
                }

                using (CodeProfiler.Step(1, "Registration - Insert password to history table"))
                {
                    UserPasswordHistoryAccessor upha = DataAccessor.CreateInstance<UserPasswordHistoryAccessor>(dbManager);

                    upha.Create(SiteManager.Current.DomainID, userID, PasswordHelper.CreateEncryptedPassword(SiteManager.Current.PasswordEncryptionMode, password), DateTime.Now);
                }

                if (Settings.Registration.RequireActivation)
                {
                    using (CodeProfiler.Step(1, "Registration - Send Email"))
                    {
                        try
                        {
                            int ExpirationDaynum = 7;
                            string ExpirationDaynumStr = Metadata.Get("/Metadata/Email/Activation.ExpirationDaynum").DefaultIfNullOrEmpty("7");
                            int.TryParse(ExpirationDaynumStr, out ExpirationDaynum);
                            // create the cmUserKey for activation
                            SqlQuery<cmUserKey> query = new SqlQuery<cmUserKey>(dbManager);
                            cmUserKey userKey = new cmUserKey();
                            userKey.KeyType = "Verification";
                            userKey.KeyValue = Guid.NewGuid().ToString();
                            userKey.UserID = userID;
                            userKey.Expiration = DateTime.Now.AddDays(ExpirationDaynum);
                            userKey.DomainID = SiteManager.Current.DomainID;
                            query.Insert(userKey);

                            // send the email
                            Email mail = new Email();
                            mail.LoadFromMetadata("Activation", language);
                            mail.ReplaceDirectory["USERNAME"] = username;
                            mail.ReplaceDirectory["FIRSTNAME"] = firstname;
                            mail.ReplaceDirectory["ACTIVELINK"] = this.Url.RouteUrlEx("Register", new { @action = "Activate", @email = email, @key = userKey.KeyValue });
                            mail.Send(email);
                        }
                        catch (Exception ex)
                        {
                            Logger.Exception(ex);
                        }
                    }
                }
                else
                {
                    if (Settings.Registration.SendWelcomeEmail)
                    {
                        SendWelcomeEmail(new cmUser
                        {
                            ID = (int)userID,
                            Username = username,
                            FirstName = firstname,
                            Email = email,
                        });
                    }
                }

                if (IsQuickRegistration && IsProfileCompleted && !Settings.Registration.RequireActivation)
                {
                    IsQuickRegistration = false;
                }
                // export to GmCore, if error happens here, it will be exported at the next time the user login
                if (IsQuickRegistration)
                    GamMatrixClient.QuickRegisterUser(userID, Settings.IovationDeviceTrack_Enabled ? iovationBlackBox : null);
                else
                    GamMatrixClient.RegisterUser(userID, currency, Settings.IovationDeviceTrack_Enabled ? iovationBlackBox : null);

                if (!string.IsNullOrWhiteSpace(referrerID))
                {
                    ExternalAuthManager.SaveAssociatedExternalAccount(userID, referrerID);
                }

                if (Settings.IsDKLicense && Settings.Registration.IsDKExternalRegister && !Settings.EnableDKRegisterWithoutNemID)
                {
                    DkLicenseClient.LinkToExternalDB(userID, pid);
                }
                if (Settings.IsDKLicense && Settings.DKLicense.IsIDQCheck) {
                    DkLicenseClient.UpdateTempAccountStatus(userID, personalId, address1, birthday.Value, firstname, surname);
                }
                if (!Settings.Registration.DisableAutoLogin)
                {
                    if (!(Settings.Registration.RequireActivation && Settings.NumberOfDaysForLoginWithoutEmailVerification <= 0))
                    {
                        // login the user
                        CustomProfile.Current.AsCustomProfile().Login(username, password, null);
                    }
                }
            }
            return ResultStatus.Success;
        }

        protected void SendWelcomeEmail(cmUser user)
        {
            try
            {
                Email mail = new Email();
                mail.LoadFromMetadata("Welcome", user.Language);
                mail.ReplaceDirectory["USERNAME"] = user.Username;
                mail.ReplaceDirectory["FIRSTNAME"] = user.FirstName;
                mail.Send(user.Email);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                throw ex;
            }
        }
    }
}
