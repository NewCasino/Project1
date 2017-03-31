using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web.Mvc;
using CM.Content;
using CM.State;
using CM.Web;
using GamMatrix.CMS.Controllers.Shared;
using GmCore;
using System.Web;

namespace GamMatrix.CMS.Controllers.MobileShared
{
	/// <summary>
	/// Summary description for MobileRegistrationController
	/// </summary>
	[HandleError]
	[MasterPageViewData(Name = "CurrentSectionMarkup", Value = "RegisterSection")]
	[ControllerExtraInfo(DefaultAction = "Step1")]
    public class MobileRegisterController : RegistrationController
	{
        [OutputCache(Duration = 0, VaryByParam = "None")]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        [HttpGet]
        public override ActionResult Index()
        {
            if(!Settings.MobileV2.IsRegisterV2Enabled)
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
            ,   intendedVolume
            , dOBPlace, registerCaptcha, iovationBlackBox, passport, contractValidity);
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
	}
}