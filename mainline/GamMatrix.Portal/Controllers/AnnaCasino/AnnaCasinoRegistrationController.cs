using System.Web.Mvc;
using CM.Web;
using GamMatrix.CMS.Controllers.Shared;

namespace GamMatrix.CMS.Controllers.AnnaCasino
{
    public class AnnaCasinoRegistrationController : QuickRegistrationController
    {
        [HttpPost]
        [CompressFilter]
        public ViewResult Step1(string username, string password, string email)
        {
            this.ViewData["username"] = username;
            this.ViewData["passwprd"] = password;
            this.ViewData["email"] = email;
            return View("Step1");
        }

        public RedirectResult Step3()
        {
            return new RedirectResult(Url.RouteUrl("QuickRegister", new { action = "Step1" }));
        }

        [HttpPost]
        [CompressFilter]
        public ViewResult Step3(
            string title,
            string firstname,
            string surname,
            string dlDay,
            string dlMonth,
            string dlYear,
            string birth,
            string username,
            string password,
            string email,
            string phonePrefix,
            string phone,
            int? country,
            int? regionID,
            string address1,
            string address2,
            string city,
            string postalCode,
            string mobilePrefix,
            string mobile
            )
        {
            this.ViewData["title"] = title;
            this.ViewData["firstname"] = firstname;
            this.ViewData["surname"] = surname;
            this.ViewData["dlDay"] = dlDay;
            this.ViewData["dlMonth"] = dlMonth;
            this.ViewData["dlYear"] = dlYear;
            this.ViewData["birth"] = birth;
            this.ViewData["username"] = username;
            this.ViewData["password"] = password;
            this.ViewData["email"] = email;
            this.ViewData["phonePrefix"] = phonePrefix;
            this.ViewData["phone"] = phone;
            this.ViewData["country"] = country;
            this.ViewData["regionID"] = regionID;
            this.ViewData["address1"] = address1;
            this.ViewData["address2"] = address2;
            this.ViewData["city"] = city;
            this.ViewData["postalCode"] = postalCode;
            this.ViewData["mobilePrefix"] = mobilePrefix;
            this.ViewData["mobile"] = mobile;
            return View("Step3");
        }
    }
}
