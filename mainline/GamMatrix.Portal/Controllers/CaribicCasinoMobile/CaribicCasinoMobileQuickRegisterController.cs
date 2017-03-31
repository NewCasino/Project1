using System.Collections.Generic;
using System.Web.Mvc;
using CM.State;
using CM.Web;
using GamMatrix.CMS.Controllers.Shared;

namespace GamMatrix.CMS.Controllers.CaribicCasinoMobile
{
    public class CaribicCasinoMobileQuickRegistrationController : QuickRegistrationController
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
    }
}
