using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Globalization;
using System.Web.Mvc;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.State;
using CM.Web;
using GamMatrixAPI;
using GmCore;
using GamMatrix.CMS.Integration.OAuth;
using GamMatrix.CMS.Controllers.Shared;

namespace GamMatrix.CMS.Controllers.ArtemisBetV3
{
    public class ArtemisBetQuickRegistrationController : QuickRegistrationController
    {
        protected virtual cmUser InitializeProfileForUpdate(cmUser user
        , string avatar
        , string alias
        , string currency
        , string securityQuestion
        , string securityAnswer
        , string language
        , int? country
        , int? regionID
        , string address1
        , string address2
        , string city
        , string postalCode
        , string mobilePrefix
        , string mobile
        , string phonePrefix
        , string phone
        , bool allowNewsEmail
        , bool allowSmsOffer
        , string title
        , string firstname
        , string surname
        , string birth
        , string preferredCurrency
        , string taxCode
        , string affiliateMarker)
            {
            if (string.IsNullOrWhiteSpace(user.AffiliateMarker) && !string.IsNullOrWhiteSpace(affiliateMarker))
                user.AffiliateMarker = affiliateMarker;

            if (!string.IsNullOrWhiteSpace(preferredCurrency))
                user.PreferredCurrency = preferredCurrency;
            //taxCode
            if (!string.IsNullOrWhiteSpace(taxCode))
                user.TaxCode = taxCode;

            if (!string.IsNullOrWhiteSpace(avatar))
                user.Avatar = avatar.Trim();

            if (!string.IsNullOrWhiteSpace(alias))
                user.Alias = alias.Trim();

            if (!string.IsNullOrWhiteSpace(securityQuestion))
                user.SecurityQuestion = securityQuestion.Trim();

            if (!string.IsNullOrWhiteSpace(securityAnswer))
                user.SecurityAnswer = securityAnswer.Trim();

            if (!string.IsNullOrWhiteSpace(language))
                user.Language = language.Trim();

            if (regionID.HasValue)
                user.RegionID = regionID.Value;

            if (!string.IsNullOrWhiteSpace(address1))
                user.Address1 = address1.Trim();

            if (address2 != null)
                user.Address2 = address2.Trim();

            if (!string.IsNullOrWhiteSpace(city))
                user.City = city.Trim();

            if (!string.IsNullOrWhiteSpace(postalCode))
                user.Zip = postalCode.Trim();

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

            if (string.IsNullOrWhiteSpace(user.FirstName) || user.FirstName.ContainSpecialCharactors()
                //|| SiteManager.Current.DistinctName.Equals("Thrills", StringComparison.InvariantCultureIgnoreCase)
                )
            {
                if (!string.IsNullOrWhiteSpace(firstname))
                {
                    user.FirstName = firstname;
                }
            }

            if (string.IsNullOrWhiteSpace(user.Surname) || user.Surname.ContainSpecialCharactors()
                //|| SiteManager.Current.DistinctName.Equals("Thrills", StringComparison.InvariantCultureIgnoreCase)
                )
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
            if (string.IsNullOrWhiteSpace(user.Currency))
            {
                if (!string.IsNullOrWhiteSpace(currency))
                    user.Currency = currency;
            }

            user.AllowNewsEmail = allowNewsEmail;
            user.AllowSmsOffer = allowSmsOffer;

            return user;
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public virtual ActionResult UpdateProfile(string avatar
            , string alias
            , string currency
            , string securityQuestion
            , string securityAnswer
            , string language
            , int? country
            , int? regionID
            , string address1
            , string address2
            , string city
            , string postalCode
            , string mobilePrefix
            , string mobile
            , string phonePrefix
            , string phone
            , bool allowNewsEmail
            , bool allowSmsOffer
            , string title
            , string firstname
            , string surname
            , string birth
            , string preferredCurrency
            , string taxCode
            , string affiliateMarker
            )
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return this.View("/Profile/Anonymous");

            try
            {
                try
                {
                    UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                    cmUser user = ua.GetByID(CustomProfile.Current.UserID);
                    bool IsProfileAlreadyCompleted = true;
                    if (string.IsNullOrWhiteSpace(user.Address1) ||
                        string.IsNullOrWhiteSpace(user.Zip) ||
                        string.IsNullOrWhiteSpace(user.Mobile) ||
                        string.IsNullOrWhiteSpace(user.SecurityQuestion) ||
                        string.IsNullOrWhiteSpace(user.SecurityAnswer) ||
                        string.IsNullOrWhiteSpace(user.City) ||
                        string.IsNullOrWhiteSpace(user.Title) ||
                        string.IsNullOrWhiteSpace(user.FirstName) ||
                        string.IsNullOrWhiteSpace(user.Surname) ||
                        string.IsNullOrWhiteSpace(user.Currency) ||
                        string.IsNullOrWhiteSpace(user.Language) ||
                        user.CountryID <= 0 ||
                        !user.Birth.HasValue)
                    {
                        IsProfileAlreadyCompleted = false;
                    }

                    user = InitializeProfileForUpdate(user
                        , avatar
                        , alias
                        , currency
                        , securityQuestion
                        , securityAnswer
                        , language
                        , country
                        , regionID
                        , address1
                        , address2
                        , city
                        , postalCode
                        , mobilePrefix
                        , mobile
                        , phonePrefix
                        , phone
                        , allowNewsEmail
                        , allowSmsOffer
                        , title
                        , firstname
                        , surname
                        , birth
                        , preferredCurrency
                        , taxCode
                        , affiliateMarker);

                    if (!IsProfileAlreadyCompleted)
                        user.CompleteProfile = DateTime.Now;
                    GamMatrixClient.UpdateUserDetails(user);
                    if (Settings.IsDKLicense && Settings.DKLicense.IsIDQCheck)
                    {
                        DkLicenseClient.UpdateTempAccountStatus(user.ID, user.PersonalID, user.Address1, user.Birth.Value, user.FirstName, user.Surname);
                    }
                    //update role string of session
                    if (!IsProfileAlreadyCompleted || CustomProfile.Current.IsInRole(Settings.DKLicense.DKTempAccountRole))
                    {
                        string roleString = GamMatrixClient.GetRoleString(user.ID, SiteManager.Current);
                        CustomProfile.Current.RoleString = roleString;
                    }

                    //CustomProfile.Current.PreferredCurrency = user.PreferredCurrency;
                    CustomProfile.ReloadSessionCache(user.ID);
                }
                catch (GmException gex)
                {
                    // ignore the error SYS_1034
                    if (gex.ReplyResponse.ErrorCode != "SYS_1034")
                        throw;
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return this.View("ErrorView");
            }

            return this.View("Success");
        }

        public virtual ViewResult Step3()
        {
            return View("Step3");
        }
    }
}
