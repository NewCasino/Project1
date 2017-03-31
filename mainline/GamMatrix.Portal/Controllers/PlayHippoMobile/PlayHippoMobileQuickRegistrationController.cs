using System.Collections.Generic;
using System.Web.Mvc;
using CM.State;
using CM.Web;
using GamMatrix.CMS.Controllers.Shared;

namespace GamMatrix.CMS.Controllers.PlayHippoMobile
{
	public class PlayHippoMobileQuickRegistrationController : QuickRegistrationController
	{
		public override RedirectResult Step2()
		{
			return new RedirectResult(Url.RouteUrl("QuickRegister", new { action = "Index" }));
		}

		[CompressFilter]
		public override ViewResult Step2(string username, string password, string email, string personalID)
		{
			ViewData["StateVars"] = new Dictionary<string, string>
			{
				{ "username", username },
				{ "password", password },
				{ "email", email },
				{ "personalID", personalID },
			};

            IPLocation ipLocation = IPLocation.GetByIP(Request.GetRealUserAddress());
			if (ipLocation.CountryID == 211 && !string.IsNullOrWhiteSpace(personalID)) //Sweden
			{
				var userVars = GetSwedishUserDetails(personalID);
				if (userVars != null)
				{
					ViewData["UserDetails"] = new Dictionary<string, string>
					{
						{ "FirstName", userVars["firstname"].ToString() },
						{ "Surname", userVars["surname"].ToString() },
						{ "Country", userVars["country"].ToString() },
						{ "Address1", userVars["address1"].ToString() },
						{ "City", userVars["city"].ToString() },
						{ "Zip", userVars["postalCode"].ToString() },
						{ "PersonalID", personalID },
					};
				}
			}

			return View();
		}

        public override ViewResult RegisterCompleted(string title, string firstname, string surname, string email, string birth, string personalId, int country, int? regionID, string address1, string address2, string streetname, string streetnumber, string city, string postalCode, string mobilePrefix, string mobile, string phonePrefix, string phone, string avatar, string username, string alias, string password, string currency, string securityQuestion, string securityAnswer, string language, bool allowNewsEmail, bool allowSmsOffer, string affiliateMarker, bool? isUsernameAvailable, bool? isAliasAvailable, bool? isEmailAvailable, string taxCode, string referrerID
            , string intendedVolume
            , string dOBPlace, string registerCaptcha = null, string iovationBlackBox = null, string passport = null, string contractValidity = null)
		{
			if (language == null && country == 211)//sweden
			{
				language = "sv";
			}

			return base.RegisterCompleted(title, firstname, surname, email, birth, personalId, country, regionID, address1, address2, streetname, streetnumber, city, postalCode, mobilePrefix, mobile, phonePrefix, phone, avatar, username, alias, password, currency, securityQuestion, securityAnswer, language, allowNewsEmail, allowSmsOffer, affiliateMarker, isUsernameAvailable, isAliasAvailable, isEmailAvailable, taxCode, referrerID,intendedVolume
            , dOBPlace, registerCaptcha, iovationBlackBox, passport, contractValidity);
		}
	}
}
