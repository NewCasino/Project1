using CM.Web;
using GamMatrixAPI;
using GmCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Web;
using System.Web.Mvc;
using System.Web.Mvc.Async;

namespace GamMatrix.CMS.Controllers._777DK
{
    public class _777DKRegistrationController : GamMatrix.CMS.Controllers.Shared.RegistrationController
    {
        public override void RegisterAsync(string title, string firstname, string surname, string email, string birth, string personalId, int? country, int? regionID, string address1, string address2, string streetname, string streetnumber, string city, string postalCode, string mobilePrefix, string mobile, string phonePrefix, string phone, string avatar, string username, string alias, string password, string currency, string securityQuestion, string securityAnswer, string language, bool? allowNewsEmail, bool? allowSmsOffer, string taxCode, string referrerID, string intendedVolume, string dOBPlace, string registerCaptcha, string iovationBlackBox = null, string passport = null, string contractValidity = null)
        {
            string affiliateMarker = Request["affiliateMarker"];
            AsyncManager.Parameters["affiliateMarker"] = affiliateMarker;
            base.RegisterAsync(title, firstname, surname, email, birth, personalId, country, regionID, address1, address2, streetname, streetnumber, city, postalCode, mobilePrefix, mobile, phonePrefix, phone, avatar, username, alias, password, currency, securityQuestion, securityAnswer, language, allowNewsEmail, allowSmsOffer, taxCode, referrerID, intendedVolume, dOBPlace, registerCaptcha, iovationBlackBox, passport, contractValidity);
        }
    }
}
