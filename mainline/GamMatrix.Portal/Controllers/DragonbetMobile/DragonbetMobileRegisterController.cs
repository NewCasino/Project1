using CM.Content;
using CM.State;
using CM.Web;
using GamMatrix.CMS.Controllers.Shared;
using GamMatrixAPI;
using GmCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Web.Mvc;

namespace GamMatrix.CMS.Controllers.DragonbetMobile
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Step1")]
    public class DragonbetMobileRegisterController : RegistrationController
    {
        [OutputCache(Duration = 0, VaryByParam = "None")]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        [HttpGet]
        public override ActionResult Index()
        {
            if (!Settings.MobileV2.IsRegisterV2Enabled)
                return new RedirectResult(Url.RouteUrl("Register", new { action = "Step1" }));
            return base.Index();
        }

        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        [CompressFilter]
        public ActionResult Step1()
        {
            if (Settings.MobileV2.IsRegisterV2Enabled)
                return new RedirectResult(Url.RouteUrl("Register", new { action = "Index" }));
            return View("Step1");
        }

        [HttpGet]
        public RedirectResult Step2()
        {
            return new RedirectResult(Url.RouteUrl("Register", new { action = "Step1" }));
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [CompressFilter]
        public ViewResult Step2(string title
            , string firstname
            , string surname
            , string email
            , string birth
            , string cprnumber
            , string personalID
            )
        {
            this.ViewData["StateVars"] = new Dictionary<string, string>
			{
				{ "title", title },
				{ "firstname", firstname },
				{ "surname", surname },
				{ "email", email },
				{ "birth", birth },
                { "cprnumber", cprnumber },
                { "personalID"  , personalID },
            };

            return View("Step2");
        }

        [HttpGet]
        public RedirectResult Step3()
        {
            return new RedirectResult(Url.RouteUrl("Register", new { action = "Step1" }));
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [CompressFilter]
        public ViewResult Step3(string title
            , string firstname
            , string surname
            , string email
            , string birth
            , string cprnumber
            , string country
            , string mobilePrefix
            , string mobile
            , string city
            , string postalCode
            , string address1
            , string address2
            , string personalID
            //, string intendedVolume
            , string regionID
            , string bank
            , string bankAccountNo
            , string nameOfAccount
            )
        {
            this.ViewData["StateVars"] = new Dictionary<string, string>
			{
				{ "title", title },
				{ "firstname", firstname },
				{ "surname", surname },
				{ "email", email },
				{ "birth", birth },

				{ "country", country },
				{ "mobilePrefix", mobilePrefix },
				{ "mobile", mobile },
				{ "city", city },
				{ "postalCode", postalCode },
				{ "address1", address1 },
				{ "address2", address2 },

                { "cprnumber", cprnumber },
                { "personalID", personalID },
                //{ "cprnumber", intendedVolume },
                { "regionID", regionID },
                {"bank", bank},
                {"bankAccountNo", bankAccountNo},
                {"nameOfAccount",nameOfAccount}
            };

            return View("Step3");
        }

        [HttpGet]
        public ActionResult CountryBlocked()
        {
            return this.View("CountryBlockedView");
        }

        [HttpGet]
        public ActionResult RegionBlocked()
        {
            return this.View("RegionBlockedView");
        }

        [HttpGet]
        public ActionResult MaxSameIPRegistrationExceeded()
        {
            return this.View("MaxSameIPRegistrationExceededView");
        }

        public ViewResult Complete()
        {
            return View("CompleteView");
        }



        protected override void ValidationRegistrationArguments(string title, string firstname, string surname, string email
            , string birth, string personalId, int country, int? regionID, string address1, string address2, string streetname, string streetnumber, string city
            , string postalCode, string mobilePrefix, string mobile, string phonePrefix, string phone, string avatar
            , string username, string alias, string password, string currency, string securityQuestion, string securityAnswer
            , string language, bool allowNewsEmail, bool allowSmsOffer, string affiliateMarker, bool? isUsernameAvailable
            , bool? isAliasAvailable, bool? isEmailAvailable, CM.State.IPLocation ipLocation, string taxCode, string referrerID
            , string intendedVolume
            , string dOBPlace, string registerCaptcha = null, string iovationBlackBox = null, string passport = null, string contractValidity = null)
        {

            if (!Settings.MobileV2.IsRegisterV2Enabled)
            {
                base.ValidationRegistrationArguments(title, firstname, surname, email
                    , birth, personalId, country, regionID, address1, address2, streetname, streetnumber, city
                    , postalCode, mobilePrefix, mobile, phonePrefix, phone, avatar
                    , username, alias, password, currency, securityQuestion, securityAnswer
                    , language, allowNewsEmail, allowSmsOffer, affiliateMarker, isUsernameAvailable
                    , isAliasAvailable, isEmailAvailable, ipLocation, taxCode, referrerID
            , intendedVolume
            , dOBPlace, registerCaptcha, iovationBlackBox, passport);
                return;
            }

            List<string> errorFields = new List<string>();

            if (Settings.IovationDeviceTrack_Enabled && string.IsNullOrEmpty(iovationBlackBox))
            {
                errorFields.Add("iovationBlackBox");
            }

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

            if (string.IsNullOrEmpty(username))
                errorFields.Add("username");

            if (string.IsNullOrEmpty(password))
                errorFields.Add("password");

            if (string.IsNullOrEmpty(currency))
                errorFields.Add("currency");

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


        public override void RegisterAsync(string title, string firstname, string surname, string email, string birth
            , string personalId, int? country, int? regionID, string address1, string address2, string streetname, string streetnumber, string city
            , string postalCode, string mobilePrefix, string mobile, string phonePrefix, string phone, string avatar
            , string username, string alias, string password, string currency, string securityQuestion, string securityAnswer
            , string language, bool? allowNewsEmail, bool? allowSmsOffer, string taxCode, string referrerID
            , string intendedVolume
            , string dOBPlace, string registerCaptcha, string iovationBlackBox = null, string passport = null, string contractValidity = null)
        {
            if (string.IsNullOrWhiteSpace(language))
            {
                language = MultilingualMgr.GetCurrentCulture().ToLowerInvariant();
            }

            if (Settings.MobileV2.IsRegisterV2Enabled)
            {
                allowSmsOffer = allowNewsEmail;
            }

            base.RegisterAsync(title, firstname, surname, email, birth, personalId, country, regionID
                , address1, address2, streetname, streetnumber, city, postalCode, mobilePrefix, mobile, phonePrefix
                , phone, avatar, username, alias, password, currency, securityQuestion
                , securityAnswer, language, allowNewsEmail, allowSmsOffer, taxCode, referrerID
            , intendedVolume
            , dOBPlace, registerCaptcha, iovationBlackBox, passport, contractValidity);
        }

        public override ViewResult RegisterCompleted(string title, string firstname, string surname, string email, string birth, string personalId, int country, int? regionID, string address1, string address2, string streetname, string streetnumber, string city, string postalCode, string mobilePrefix, string mobile, string phonePrefix, string phone, string avatar, string username, string alias, string password, string currency, string securityQuestion, string securityAnswer, string language, bool allowNewsEmail, bool allowSmsOffer, string affiliateMarker, bool? isUsernameAvailable, bool? isAliasAvailable, bool? isEmailAvailable, string taxCode, string referrerID, string intendedVolume, string dOBPlace, string registerCaptcha, string iovationBlackBox = null, string passport = null, string contractValidity = null)
        {
            string bank = Request.Form["bank"];
            string bankAccountNo = Request.Form["bankAccountNo"];
            string bankAccountName = Request.Form["nameOfAccount"];

            var registerCompltedViewResult =
                base.RegisterCompleted(title, firstname, surname, email, birth, personalId, country, regionID, address1, address2, streetname, streetnumber, city, postalCode
                , mobilePrefix, mobile, phonePrefix, phone, avatar, username, alias, password, currency, securityQuestion, securityAnswer, language
                , allowNewsEmail, allowSmsOffer, affiliateMarker, isUsernameAvailable, isAliasAvailable, isEmailAvailable, taxCode, referrerID
            , intendedVolume
            , dOBPlace, registerCaptcha, passport, contractValidity);

            string registerLocalBankErr;
            if (CustomProfile.Current.UserCountryID == 202 || CustomProfile.Current.UserCountryID == 51)
            {
                if (this.RegisterLocalBankPayCard(VendorID.LocalBank, bank, bankAccountName, bankAccountNo, out registerLocalBankErr) == false)
                {

                }
            }

            return registerCompltedViewResult;//base.RegisterCompleted(title, firstname, surname, email, birth, personalId, country, regionID, address1, address2, city, postalCode, mobilePrefix, mobile, phonePrefix, phone, avatar, username, alias, password, currency, securityQuestion, securityAnswer, language, allowNewsEmail, allowSmsOffer, affiliateMarker, isUsernameAvailable, isAliasAvailable, isEmailAvailable, taxCode);
        }


        [HttpGet]
        public JsonResult GetIPLocation()
        {
            try
            {
                IPLocation ipLocation = IPLocation.GetByIP(Request.GetRealUserAddress());
                if (ipLocation == null)
                    return this.Json(new { @success = false, @error = string.Empty }, JsonRequestBehavior.AllowGet);

                CountryInfo countryInfo = CountryManager.GetAllCountries().FirstOrDefault(c => c.InternalID == ipLocation.CountryID);
                bool isRegionBlocked = false;
                if (countryInfo.RestrictRegistrationByRegionCode == null) countryInfo.RestrictRegistrationByRegionCode = string.Empty;
                string[] regionCodeList = countryInfo.RestrictRegistrationByRegionCode.Split(',');
                if (countryInfo != null && countryInfo.RestrictRegistrationByIP && !Settings.WhiteList_EMUserIPs.Contains(ipLocation.IP, StringComparer.InvariantCultureIgnoreCase))
                {
                    if (countryInfo.RestrictRegistrationByRegion && !string.IsNullOrEmpty(countryInfo.RestrictRegistrationByRegionCode))
                    {
                        if (!regionCodeList.Contains(ipLocation.RegionCode))
                        {
                            isRegionBlocked = true;
                        }
                    }
                    else
                    {
                        isRegionBlocked = true;
                    }
                }
                var data = new
                {
                    ip = ipLocation.IP,
                    found = ipLocation.Found,
                    countryID = ipLocation.CountryID,
                    countryCode = ipLocation.CountryCode,
                    isCountryRegistrationBlocked = (countryInfo != null && countryInfo.RestrictRegistrationByIP && isRegionBlocked && !Settings.WhiteList_EMUserIPs.Contains(ipLocation.IP, StringComparer.InvariantCultureIgnoreCase)),
                };

                return this.Json(new { @success = true, @data = data }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception exception)
            {
                Logger.Exception(exception);
                return this.Json(new { @success = false, @error = GmException.TryGetFriendlyErrorMsg(exception) }, JsonRequestBehavior.AllowGet);
            }
        }

        private bool RegisterLocalBankPayCard(VendorID vendorID
            , string bankName
            , string nameOnAccount
            , string bankAccountNo
            , out string error
            )
        {
            error = string.Empty;

            if (string.IsNullOrWhiteSpace(bankName)
                || string.IsNullOrWhiteSpace(nameOnAccount)
                || string.IsNullOrWhiteSpace(bankAccountNo))
                throw new ArgumentException();

            if (!CustomProfile.Current.IsAuthenticated)
                throw new UnauthorizedAccessException();

            if (CustomProfile.Current.UserCountryID != 51 && CustomProfile.Current.UserCountryID != 202)
                throw new ArgumentException("your country did not allowed the bank.");

            string displayNumber = "";
            string identityNumber = "";
            if (CustomProfile.Current.UserCountryID == 202 || CustomProfile.Current.UserCountryID == 51) // Korea or China
            {
                displayNumber = bankAccountNo;
                identityNumber = bankAccountNo;
            }

            List<PayCardInfoRec> payCards = GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.LocalBank);
            if (payCards.Exists(p => p.OwnerName.Equals(nameOnAccount, StringComparison.InvariantCultureIgnoreCase)
                && p.BankName.Equals(bankName, StringComparison.InvariantCultureIgnoreCase)
                && (p.BankAccountNo.Equals(bankAccountNo, StringComparison.InvariantCultureIgnoreCase))))
            {
                //return this.Json(new { @success = false, @error = "Multi card with same details is not allowed" });
                error = "Multi card with same details is not allowed";
                return false;
            }

            PayCardRec payCard = new PayCardRec();
            payCard.VendorID = vendorID;
            payCard.ActiveStatus = ActiveStatus.Active;
            payCard.UserID = CustomProfile.Current.UserID;
            payCard.BankAccountNo = bankAccountNo;
            payCard.IdentityNumber = identityNumber;
            payCard.DisplayNumber = displayNumber;
            payCard.DisplayName = displayNumber;
            payCard.OwnerName = nameOnAccount;
            payCard.BankName = bankName;
            payCard.BankCountryID = CustomProfile.Current.UserCountryID;

            long newPayCardID = GamMatrixClient.RegisterPayCard(payCard);

            //return this.Json(new { @success = true, @payCardID = newPayCardID.ToString() });
            return true;
        }
    }
}
