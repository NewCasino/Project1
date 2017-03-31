using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web.Mvc;
using CM.Content;
using CM.State;
using CM.Web;
using GamMatrixAPI;
using GmCore;
using OAuth;

namespace GamMatrix.CMS.Controllers.Shared
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index")]
    public class QuickRegistrationController: RegistrationController
    {
        public override ActionResult Index()
        {
            var referrerID = Request.QueryString["referrerID"];
            if (!string.IsNullOrEmpty(referrerID))
            {
                var referrerData = ReferrerData.Load(referrerID);
                this.ViewData["ReferrerData"] = referrerData;
            }

            return View("Index");
        }
        public ActionResult Dialog() 
        {
            return View("Dialog");
        }
        protected override string InitUsername(string username, string email)
        {
            if (string.IsNullOrWhiteSpace(username))
                return email;
            return username;
        }
        protected override void ValidationRegistrationArguments(string title, string firstname, string surname, string email, string birth, string personalId, int country, int? regionID, string address1, string address2, string streetname, string streetnumber, string city, string postalCode, string mobilePrefix, string mobile, string phonePrefix, string phone, string avatar, string username, string alias, string password, string currency, string securityQuestion, string securityAnswer, string language, bool allowNewsEmail, bool allowSmsOffer, string affiliateMarker, bool? isUsernameAvailable, bool? isAliasAvailable, bool? isEmailAvailable, IPLocation ipLocation, string taxCode, string referrerID
            , string intendedVolume
            , string dOBPlace, string registerCaptcha, string iovationBlackBox = null, string passport = null, string contractValidity = null)
        {
            IsQuickRegistration = true;
            List<string> errorFields = new List<string>();
            if (Settings.QuickRegistration.IsUserNameVisible)
            {
                if (!Regex.IsMatch(username, @"^\w{4,20}$"))
                    throw new ArgumentException(Metadata.Get("/Metadata/ServerResponse.Register_InvalidUsername"));

                if (string.IsNullOrEmpty(username))
                    errorFields.Add("username");
            }
            if (string.IsNullOrEmpty(email))
                errorFields.Add("email");

            if (string.IsNullOrEmpty(password))
                errorFields.Add("password");

            if (string.IsNullOrEmpty(currency))
                errorFields.Add("currency");


            if (Settings.QuickRegistration.IsTitleVisible && Settings.Registration.IsTitleRequired && string.IsNullOrEmpty(title))
                errorFields.Add("title");

            if (Settings.QuickRegistration.IsFirstnameVisible && Settings.Registration.IsFirstnameRequired && string.IsNullOrEmpty(firstname))
                errorFields.Add("firstname");

            if (Settings.QuickRegistration.IsSurnameVisible && Settings.Registration.IsSurnameRequired && string.IsNullOrEmpty(surname))
                errorFields.Add("surname");

            if (Settings.QuickRegistration.IsAddress1Visible && Settings.Registration.IsAddress1Required && string.IsNullOrEmpty(address1))
                errorFields.Add("address1");

            if (Settings.QuickRegistration.IsStreetVisible && Settings.Registration.IsStreetRequired && string.IsNullOrEmpty(streetname))
                errorFields.Add("streetname");

            if (Settings.QuickRegistration.IsStreetVisible && Settings.Registration.IsStreetRequired && string.IsNullOrEmpty(streetnumber))
                errorFields.Add("streetnumber");

            if (Settings.QuickRegistration.IsCityVisible && Settings.Registration.IsCityRequired && string.IsNullOrEmpty(city))
                errorFields.Add("city");

            if (Settings.QuickRegistration.IsPostalCodeVisible && Settings.Registration.IsPostalCodeRequired && string.IsNullOrEmpty(postalCode))
                errorFields.Add("postal code");

            if (Settings.QuickRegistration.IsMobileVisible && Settings.Registration.IsMobileRequired && string.IsNullOrEmpty(mobilePrefix))
                errorFields.Add("mobile prefix");

            if (Settings.QuickRegistration.IsMobileVisible && Settings.Registration.IsMobileRequired && string.IsNullOrEmpty(mobile))
                errorFields.Add("mobile");

            if (Settings.QuickRegistration.IsSecurityQuestionVisible && Settings.Registration.IsSecurityQuestionRequired && string.IsNullOrEmpty(securityQuestion))
                errorFields.Add("security question");

            if (Settings.QuickRegistration.IsSecurityAnswerVisible && Settings.Registration.IsSecurityAnswerRequired && string.IsNullOrEmpty(securityAnswer))
                errorFields.Add("security answer");            

            if (Settings.QuickRegistration.IsLanguageVisible && string.IsNullOrEmpty(language))
                errorFields.Add("language");

            if(Settings.IsDKLicense && string.IsNullOrEmpty( intendedVolume))
                errorFields.Add(" intended gambling volume");

            if (Settings.QuickRegistration.IsCaptchaRequired && string.IsNullOrEmpty(registerCaptcha))
                errorFields.Add("registerCaptcha");

            if (Settings.Registration.IsPassportRequired && string.IsNullOrEmpty(passport))
                errorFields.Add("passport");

            //if (Settings.IsDKLicense && string.IsNullOrEmpty(dOBPlace))
            //    errorFields.Add("DOB place");
                
            if (errorFields.Count > 0)
                throw new ArgumentException(
                    Metadata.Get("/Metadata/ServerResponse.Register_EmptyFields").Replace("$FIELDS$", string.Join(",", errorFields))
                );
            ValidationRegisterCaptcha(registerCaptcha);
            if (Settings.QuickRegistration.IsUserNameVisible && !Regex.IsMatch(username, @"^\w{4,20}$"))
                throw new ArgumentException(Metadata.Get("/Metadata/ServerResponse.Register_InvalidUsername"));

            if (isUsernameAvailable.HasValue && !isUsernameAvailable.Value)
                throw new ArgumentException(Metadata.Get("/Metadata/ServerResponse.Register_InvalidUsername"));
            if (isEmailAvailable.HasValue && !isEmailAvailable.Value)
                throw new ArgumentException(Metadata.Get("/Metadata/ServerResponse.Register_InvalidEmail"));
            if (isAliasAvailable.HasValue && !isAliasAvailable.Value)
                throw new ArgumentException(Metadata.Get("/Metadata/ServerResponse.Register_InvalidAlias"));
        }

        protected override void ValidationRegisterCaptcha(string registerCaptcha)
        {
            if (Settings.QuickRegistration.IsCaptchaRequired)
            {
                string captchaToCompare = CustomProfile.Current.Get("captcha");
                CustomProfile.Current.Set("captcha", null);

                if (!string.Equals(registerCaptcha.Trim(), captchaToCompare, StringComparison.InvariantCultureIgnoreCase))
                {
                    throw new ArgumentException(Metadata.Get("/Components/_Captcha_ascx.Captcha_Invalid"));
                }
            }
        }

        protected override void ValidationRegistrationBirth(string birth, out DateTime? dt)
        {
            DateTime temp;
            if (DateTime.TryParseExact(birth, "yyyy-M-d", CultureInfo.InvariantCulture, DateTimeStyles.None, out temp))
                dt = temp;
            else if ( Settings.QuickRegistration.IsBirthDateVisible && Settings.Registration.IsBirthDateRequired)
                throw new ArgumentException(Metadata.Get("/Metadata/ServerResponse.Register_InvalidBirthdate"));
            else
                dt = null;
        }

        public virtual ViewResult Step1()
        {
            return View("Step1");
        }

        public virtual RedirectResult Step2()
        {
            return new RedirectResult(Url.RouteUrl("QuickRegister", new { action = "Step1" }));
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [CompressFilter]
        public virtual ViewResult Step2(string username, string password, string email, string personalID)
        { 
            this.ViewData["username"] = username;
            this.ViewData["passwprd"] = password;
            this.ViewData["email"] = email;
            this.ViewData["personalID"] = personalID;

            IPLocation ipLocation = IPLocation.GetByIP(Request.GetRealUserAddress());
            if (ipLocation.CountryID == 211 && !string.IsNullOrWhiteSpace(personalID)) //Sweden
            {
				var userDetails = GetSwedishUserDetails(personalID);
				if (userDetails != null)
                {
					this.ViewData["address1"] = userDetails["address1"];
                    this.ViewData["streetname"] = userDetails["streetname"];
                    this.ViewData["streetnumber"] = userDetails["streetnumber"];
					this.ViewData["city"] = userDetails["city"];
					this.ViewData["firstname"] = userDetails["firstname"];
					this.ViewData["surname"] = userDetails["surname"];
					this.ViewData["postalCode"] = userDetails["postalCode"];

					this.ViewData["country"] = userDetails["country"];
                }
            }

            return View("Step2");
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [CompressFilter]
        public virtual ViewResult Step2Ex(string title,
            string firstname,
            string surname, 
            string dlDay ,
            string dlMonth,
            string dlYear,
             string birth,
            string username, 
            string password, 
            string email,
            string securityquestion,
            string securityanswer, 
            string personalID)
        {
  
                this.ViewData["username"] = username;
                this.ViewData["passwprd"] = password;
                this.ViewData["email"] = email;
                this.ViewData["personalID"] = personalID;
                this.ViewData["title"] = title;
                this.ViewData["firstname"] = firstname;
                this.ViewData["surname"] = surname;
                this.ViewData["birth"] = birth;
                this.ViewData["securityquestion"] = securityquestion;
                this.ViewData["securityanswer"] = securityanswer;
                IPLocation ipLocation = IPLocation.GetByIP(Request.GetRealUserAddress());
                if (ipLocation.CountryID == 211 && !string.IsNullOrWhiteSpace(personalID)) //Sweden
                { 
                    var userDetails = GetSwedishUserDetails(personalID);
                    if (userDetails != null)
                    {
                        this.ViewData["address1"] = userDetails["address1"];
                        this.ViewData["streetname"] = userDetails["streetname"];
                        this.ViewData["streetnumber"] = userDetails["streetnumber"];
                        this.ViewData["city"] = userDetails["city"];
                        this.ViewData["firstname"] = userDetails["firstname"];
                        this.ViewData["surname"] = userDetails["surname"];
                        this.ViewData["postalCode"] = userDetails["postalCode"];
                        this.ViewData["country"] = userDetails["country"];
                    }
                }
                return View("Step2"); 
        }

		protected Dictionary<string, object> GetSwedishUserDetails(string personalID)
		{
			Dictionary<string, object> UserDetails = null;

			CountryInfo country = CountryManager.GetAllCountries().FirstOrDefault(p => p.InternalID == 211);
			if (country != null && !string.IsNullOrWhiteSpace(country.PersonalIdValidationRegularExpression))
			{
				Regex reg = new Regex(country.PersonalIdValidationRegularExpression);
				if (reg.Match(personalID).Success)
				{
					personalID = personalID.Replace(" ", "").Replace("-", "");
					GetUserPersonalDetailsSSNRequest response = GamMatrixClient.GetUserPersonalDetailsBySSN(personalID);
					if (string.IsNullOrWhiteSpace(response.ErrorCode))
					{
						UserDetails = new Dictionary<string, object>
						{
							{ "address1", response.Address },
							{ "city", response.City },
							{ "firstname", response.FName },
							{ "surname", response.LName },
							{ "postalCode", response.PostalCode },
							{ "country", 211 },
						};
					}
				}
			}

			return UserDetails;
		}
    }
}
