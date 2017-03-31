using System;
using System.Globalization;
using System.Web.Mvc;
using CM.Content;
using CM.Web;

namespace GamMatrix.CMS.Controllers.Daebak88
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index")]
    public class Daebak88ProfileController : GamMatrix.CMS.Controllers.Shared.ProfilePageController
    {
        protected readonly string CURRENCY = "KRW";
        protected readonly int COUNTRYID = 202;

        protected override CM.db.cmUser InitializeProfileForUpdate(CM.db.cmUser user, string avatar, string alias, string currency, string securityQuestion, string securityAnswer, string language, int? country, int? regionID, string address1, string address2, string streetname, string streetnumber, string city, string postalCode, string mobilePrefix, string mobile, string phonePrefix, string phone, bool allowNewsEmail, bool allowSmsOffer, string title, string firstname, string surname, string birth, string preferredCurrency, string taxCode, string affiliateMarker, int? intendedVolume)
        {
            string random1 = GetRandomString(6).ToLower();
            string random2 = GetRandomString(6).ToLower();

            if (!string.IsNullOrWhiteSpace(preferredCurrency))
                user.PreferredCurrency = preferredCurrency;
                
            //taxCode
            if (!string.IsNullOrWhiteSpace(taxCode))
                user.TaxCode = taxCode;

            if (!string.IsNullOrWhiteSpace(avatar))
                user.Avatar = avatar.Trim();

            if (!string.IsNullOrWhiteSpace(alias))
                user.Alias = alias.Trim();

            if (intendedVolume.HasValue)
                user.intendedVolume = intendedVolume.Value;

            if (!string.IsNullOrWhiteSpace(securityQuestion))
                user.SecurityQuestion = securityQuestion.Trim();
            else if (string.IsNullOrWhiteSpace(user.SecurityQuestion))
                user.SecurityQuestion = Metadata.Get(Metadata.GetChildrenPaths("Metadata/SecurityQuestion")[0] + ".Text");

            if (!string.IsNullOrWhiteSpace(securityAnswer))
                user.SecurityAnswer = securityAnswer.Trim();
            else if (string.IsNullOrWhiteSpace(user.SecurityAnswer))
                user.SecurityAnswer = "football";

            if (!string.IsNullOrWhiteSpace(language))
                user.Language = language.Trim();

            if (regionID.HasValue)
                user.RegionID = regionID.Value;

            if (!string.IsNullOrWhiteSpace(address1))
                user.Address1 = address1.Trim();
            else if (string.IsNullOrWhiteSpace(user.Address1))
                user.Address1 = "address1" + random1;

            if (!string.IsNullOrWhiteSpace(address2))
                user.Address2 = address2.Trim();

            if (!string.IsNullOrWhiteSpace(streetname))
                user.StreetName = streetname.Trim();

            if (!string.IsNullOrWhiteSpace(streetnumber))
                user.StreetNumber = streetnumber.Trim(); 

            if (!string.IsNullOrWhiteSpace(city))
                user.City = city.Trim();
            else if (string.IsNullOrWhiteSpace(user.City))
                user.City = "city" + random2;

            if (!string.IsNullOrWhiteSpace(postalCode))
                user.Zip = postalCode.Trim();
            else if (string.IsNullOrWhiteSpace(user.Zip))
                user.Zip = "100-000";

            if (!string.IsNullOrWhiteSpace(mobilePrefix) &&
                !string.IsNullOrWhiteSpace(mobile))
            {
                user.Mobile = mobile;
                user.MobilePrefix = mobilePrefix;
            }

            if (!string.IsNullOrWhiteSpace(phonePrefix) &&
                !string.IsNullOrWhiteSpace(phone))
            {
                user.Phone = phone;
                user.PhonePrefix = phonePrefix;
            }

            if (string.IsNullOrWhiteSpace(user.Title) &&
                !string.IsNullOrWhiteSpace(title))
            {
                user.Title = title;
                user.Gender = string.Equals(title, "Mr.", StringComparison.OrdinalIgnoreCase) ? "M" : "F";
            }
            else if (string.IsNullOrWhiteSpace(user.Title))
            { 
                user.Title = "Mr.";
                user.Gender = "M";
            }

            if (string.IsNullOrWhiteSpace(user.FirstName) || user.FirstName.ContainSpecialCharactors())
            {
                if (!string.IsNullOrWhiteSpace(firstname))
                {
                    user.FirstName = firstname;
                }
            }

            if (string.IsNullOrWhiteSpace(user.Surname) || user.Surname.ContainSpecialCharactors())
            {
                if (!string.IsNullOrWhiteSpace(surname))
                {
                    user.Surname = surname;
                }
            }


            if (!user.Birth.HasValue)
            {
                DateTime birthday;
                if (DateTime.TryParseExact(birth, "yyyy-M-d", CultureInfo.InvariantCulture, DateTimeStyles.None, out birthday))
                {
                    user.Birth = birthday;
                }
            }

            if (user.CountryID == 0 && country.HasValue)
            {
                if (country > 0)
                    user.CountryID = country.Value;
            }
            else if (user.CountryID == 0)
                user.CountryID = COUNTRYID;

            if (string.IsNullOrWhiteSpace(user.Currency))
            {
                if (!string.IsNullOrWhiteSpace(currency))
                    user.Currency = currency;
                else
                    user.Currency = CURRENCY;
            }            

            user.AllowNewsEmail = allowNewsEmail;
            user.AllowSmsOffer = allowSmsOffer;

            return user;
        }

        public string GetRandomString(int length)
        {
            int rep = 0;
            string str = string.Empty;
            long num2 = DateTime.Now.Ticks + rep;
            rep++;
            Random random = new Random(((int)(((ulong)num2) & 0xffffffffL)) | ((int)(num2 >> rep)));
            for (int i = 0; i < length; i++)
            {
                char ch;
                int num = random.Next();
                if ((num % 2) == 0)
                {
                    ch = (char)(0x30 + ((ushort)(num % 10)));
                }
                else
                {
                    ch = (char)(0x41 + ((ushort)(num % 0x1a)));
                }
                str = str + ch.ToString();
            }
            return str;
        }
    }
}
