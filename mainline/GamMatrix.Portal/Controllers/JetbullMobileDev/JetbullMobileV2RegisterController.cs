using System;
using System.Collections.Generic;
using System.Text.RegularExpressions;
using System.Web.Mvc;
using CM.Content;
using CM.Web;
using GamMatrix.CMS.Controllers.Shared;
using GamMatrix.CMS.Models.MobileShared.Components;
using System.Web;

namespace GamMatrix.CMS.Controllers.JetbullMobileDev
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index")]
    public class JetbullMobileV2RegisterController : RegistrationController
    {
        [OutputCache(Duration = 0, VaryByParam = "None")]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        [HttpGet]
        public override ActionResult Index()
        {
            return View("Index", new RegisterV2FormViewModel());
        }

        [HttpPost]
        public ActionResult Index(RegisterV2FormViewModel vm)
        {
            if (ModelState.IsValid)
            {
                return new RedirectResult(Url.RouteUrl("Home"));
            }

            return new RedirectResult(Url.RouteUrl("Register", new { action = "Register" }));
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
            List<string> errorFields = new List<string>();

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

            if (Settings.IsDKLicense && string.IsNullOrEmpty(intendedVolume))
                errorFields.Add(" intended gambling volume");

            //if (Settings.IsDKLicense && string.IsNullOrEmpty(dOBPlace))
            //   errorFields.Add("DOB place");

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
            , string dOBPlace, string registerCaptcha = null, string iovationBlackBox = null, string passport = null, string contractValidity = null)
        {
            if (string.IsNullOrWhiteSpace(language))
            {
                language = MultilingualMgr.GetCurrentCulture().ToLowerInvariant();
            }

            base.RegisterAsync(title, firstname, surname, email, birth, personalId, country, regionID
                , address1, address2, streetname, streetnumber, city, postalCode, mobilePrefix, mobile, phonePrefix
                , phone, avatar, username, alias, password, currency, securityQuestion
                , securityAnswer, language, allowNewsEmail, allowSmsOffer, taxCode, referrerID
            ,   intendedVolume
            ,   dOBPlace, registerCaptcha, iovationBlackBox, passport);
        }

        [HttpGet]
        public ActionResult CountryBlocked()
        {
            return this.View("CountryBlockedView");
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
    }
}
