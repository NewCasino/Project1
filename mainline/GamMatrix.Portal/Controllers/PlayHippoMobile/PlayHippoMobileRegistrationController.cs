using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using GamMatrix.CMS.Controllers.Shared;
using System.Web.Mvc;
using CM.Web;
using System.Globalization;
using GamMatrixAPI;
using CM.State;
using GmCore;
using System.Text.RegularExpressions;

namespace GamMatrix.CMS.Controllers.PlayHippoMobile
{
	[HandleError]
	[ControllerExtraInfo(DefaultAction = "Step1")]
	public class PlayHippoMobileRegistrationController : RegistrationController
	{
		[HttpGet]
		[OutputCache(Duration = 0, VaryByParam = "None")]
		[ProtocolAttribute(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
		[CompressFilter]
		public ActionResult Step1()
		{
			return View("Step1");
		}

		[HttpGet]
		public RedirectResult Step2()
		{
			return new RedirectResult(Url.RouteUrl("Register", new { action = "Step1" }));
		}

		[HttpPost]
		[CompressFilter]
		public ViewResult Step2(string username
			, string email
			, string password
			, string currency
			, string securityQuestion
			, string securityAnswer
			, string personalID
			)
		{
			ViewData["StateVars"] = new Dictionary<string, string>
			{
				{ "username", username },
				{ "email", email },
				{ "password", password },
				{ "currency", currency },
				{ "securityQuestion", securityQuestion },
				{ "securityAnswer", securityAnswer },
				{ "personalID", personalID },
			};

			var userDetails = GetUserDataBySSN(personalID);
			if (userDetails != null)
				ViewData["UserDetails"] = new Dictionary<string, string>
				{
					{ "userDetails", "1" },
					{ "address1", userDetails.Address },
					{ "city", userDetails.City },
					{ "firstname", userDetails.FName },
					{ "surname", userDetails.LName },
					{ "postalCode", userDetails.PostalCode },
					{ "country", "211" }
				};

			return View("Step2");
		}

		private GetUserPersonalDetailsSSNRequest GetUserDataBySSN(string personalID)
		{
			IPLocation ipLocation = GamMatrixClient.GetIPLocation(Request.GetRealUserAddress());
			if (ipLocation.CountryID == 211 && !string.IsNullOrWhiteSpace(personalID)) //Sweden
			{
				CountryInfo country = CountryManager.GetAllCountries().FirstOrDefault(p => p.InternalID == 211);
				if (country != null && !string.IsNullOrWhiteSpace(country.PersonalIdValidationRegularExpression))
				{
					Regex reg = new Regex(country.PersonalIdValidationRegularExpression);
					if (reg.Match(personalID).Success)
					{
						personalID = personalID.Replace(" ", "").Replace("-", "");
						GetUserPersonalDetailsSSNRequest response = GamMatrixClient.GetUserPersonalDetailsBySSN(personalID);
						if (string.IsNullOrWhiteSpace(response.ErrorCode))
							return response;
					}
				}
			}

			return null;
		}

		[HttpGet]
		public RedirectResult Step3()
		{
			return new RedirectResult(Url.RouteUrl("Register", new { action = "Step1" }));
		}

		[HttpPost]
		[CompressFilter]
		public ViewResult Step3(string username
			, string email
			, string password
			, string currency
			, string securityQuestion
			, string securityAnswer
			, string personalID

			, string title
			, string firstname
			, string surname
			, int? day
			, int? month
			, int? year
			, string language

			, string userDetails
			, string address1
			, string city
			, string postalCode
			, string country
			)
		{
			string birth = string.Empty;
			if (day != null && month != null && year != null)
			{
				birth = new DateTime((int)year, (int)month, (int)day)
					.ToString("yyyy-M-d", CultureInfo.InvariantCulture);
			}

			ViewData["StateVars"] = new Dictionary<string, string>
			{
				{ "username" , username },
				{ "email", email },
				{ "password", password },
				{ "currency" , currency },
				{ "securityQuestion" , securityQuestion },
				{ "securityAnswer" , securityAnswer },
				{ "personalID" , personalID },

				{ "title" , title },
				{ "firstname" , firstname },
				{ "surname" , surname },
				{ "birth" , birth },
				{ "language" , language },
			};

			if (int.Parse(userDetails) == 1)
				ViewData["UserDetails"] = new Dictionary<string, string>
				{
					{ "userDetails", "1" },
					{ "address1", address1 },
					{ "city", city },
					{ "postalCode", postalCode },
					{ "country", country }
				};

			return View("Step3");
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
