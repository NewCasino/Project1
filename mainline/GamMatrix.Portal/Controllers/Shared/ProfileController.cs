using System;
using System.Globalization;
using System.Linq;
using System.Web.Mvc;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.State;
using CM.Web;
using GamMatrixAPI;
using GmCore;
using GamMatrix.CMS.Integration.OAuth;
using TwoFactorAuth;
using System.Web;
using System.Text.RegularExpressions;

namespace GamMatrix.CMS.Controllers.Shared
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index")]
    public class ProfilePageController : AsyncControllerEx
    {
        [HttpGet]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        public virtual ActionResult Index()
        {
            return View("Index");
        }


        #region GetIPLocation
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
        #endregion

        [HttpGet]
        public JsonResult GetPayCards(VendorID vendorID)
        {
            try
            {
                if (!CustomProfile.Current.IsAuthenticated)
                    throw new UnauthorizedAccessException();

                var payCards = GamMatrixClient.GetPayCards(vendorID)
                    .Select(p => new
                    {
                        ID = p.ID.ToString(),
                        ExpiryDate = p.ExpiryDate.ToString("MM/yyyy"),
                        DisplayNumber = p.DisplayName,
                    }).ToArray();
                return this.Json(new { @success = true, @payCards = payCards }, JsonRequestBehavior.AllowGet);
            }
            catch (GmException ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = GmException.TryGetFriendlyErrorMsg(ex) }, JsonRequestBehavior.AllowGet);
            }
        }// GetPayCards

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
            , string streetname
            , string streetnumber
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
            , int? intendedVolume)
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

            if (intendedVolume.HasValue)
                user.intendedVolume = intendedVolume.Value;

            if (!string.IsNullOrWhiteSpace(address1))
                user.Address1 = address1.Trim();

            if (address2 != null)
                user.Address2 = address2.Trim();

            if (streetname != null)
                user.StreetName = streetname.Trim();

            if (streetnumber != null)
                user.StreetNumber = streetnumber.Trim();

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
            , string streetname
            , string streetnumber
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
            , int? intendedVolume
            , string personalID = null
            , string favoriteTeam = null
            , string passport = null
            )
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return this.View("Anonymous");

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
                    if (Settings.Registration.IsPersonalIDRequired && !string.IsNullOrWhiteSpace(personalID) && string.IsNullOrWhiteSpace(user.PersonalID))
                    {
                        user.PersonalID = personalID;
                        IsProfileAlreadyCompleted = false;
                    }

                    if (!string.IsNullOrWhiteSpace(streetname) && !string.IsNullOrWhiteSpace(streetnumber))
                    {
                        address1 = string.Format("{0} {1}", streetname, streetnumber);
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
                        , streetname
                        , streetnumber
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
                        , affiliateMarker
                        , intendedVolume);

                    if (!IsProfileAlreadyCompleted)
                        user.CompleteProfile = DateTime.Now;
                    GamMatrixClient.UpdateUserDetails(user);
                    if (Settings.IsDKLicense && Settings.DKLicense.IsIDQCheck)
                    {
                        DkLicenseClient.UpdateTempAccountStatus(user.ID, user.PersonalID, user.Address1, user.Birth.Value, user.FirstName, user.Surname);
                    }
                    //artemisbet need it
                    if (!string.IsNullOrWhiteSpace(favoriteTeam))
                    {
                        GamMatrixClient.SetUserMetadata("FavoriteTeam", favoriteTeam);
                    }

                    //update passport
                    if (!String.IsNullOrEmpty(passport))
                    {
                        string originalPassport = string.Empty;
                        var resp = GamMatrixClient.GetUserImageRequest(user.ID, user.PassportID);
                        if (resp != null && resp.Image != null)
                        {
                            originalPassport = string.Format("data:{0};base64,{1}", resp.Image.ImageContentType, Convert.ToBase64String(resp.Image.ImageFile));
                        }

                        if (!string.Equals(passport, originalPassport, StringComparison.InvariantCultureIgnoreCase))
                        {
                            Match m = Regex.Match(passport, @"(\w+):(?<ContentType>[\s\S]*?);base64,(?<Image>.+)", RegexOptions.IgnoreCase);
                            if (m.Success)
                            {
                                try
                                {
                                    string contentType = m.Groups["ContentType"].Value;
                                    byte[] passportImage = Convert.FromBase64String(m.Groups["Image"].Value);
                                    string filename = string.Format("{0}.{1}", Guid.NewGuid().ToString("N").Substring(0, new Random().Next(1, 8)), contentType.Split(new char[] { '/' })[1].ToLowerInvariant());
                                    GamMatrixClient.AddUserImageRequest(user.ID, filename, contentType, passportImage, true);
                                }
                                catch (Exception exx)
                                {
                                    Logger.Error("UploadImage", string.Format("incorrect passport format, userid:{0}, source: {1}, exception:{2}", user.ID, passport, exx.Message));
                                }

                            }
                            else
                            {
                                Logger.Error("UploadImage", string.Format("incorrect passport format, userid:{0}, source: {1}", user.ID, passport));
                            }
                        }
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
                return this.View("Error");
            }

            return this.View("Success");
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public JsonResult UpdateMobile(string mobilePrefix, string mobile)
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return this.Json(new { @success = false, @error = "You need to login to be able to update your mobile." });

            try
            {
                UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                cmUser user = ua.GetByID(CustomProfile.Current.UserID);

                bool modified = false;

                if (!string.IsNullOrWhiteSpace(mobilePrefix) && !mobilePrefix.Equals(user.MobilePrefix, StringComparison.InvariantCultureIgnoreCase))
                {
                    modified = true;
                    user.MobilePrefix = mobilePrefix;
                }
                if (!string.IsNullOrWhiteSpace(mobile) && !mobile.Equals(user.Mobile, StringComparison.InvariantCultureIgnoreCase))
                {
                    modified = true;
                    user.Mobile = mobile;
                }

                if (modified)
                    GamMatrixClient.UpdateUserDetails(user);

                return this.Json(new { @success = true });
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = GmException.TryGetFriendlyErrorMsg(ex) });
            }
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public JsonResult ResetSecondFactorVerified()
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return this.Json(new { @success = false, @error = "You need to login to be able to update your mobile." });

            try
            {
                if (Settings.Session.SecondFactorAuthenticationEnabled)
                    SecondFactorAuthenticator.ResetSecondFactorAuth(CustomProfile.Current.UserID);

                return this.Json(new { @success = true });
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = GmException.TryGetFriendlyErrorMsg(ex) });
            }
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public JsonResult RenewContract(string contractValidity)
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return this.Json(new { @success = false, @error = "You need to login to be able to renew your contract." });

            try
            {
                UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                cmUser user = ua.GetByID(CustomProfile.Current.UserID);

                bool result = GamMatrixClient.SetUserLicenseLTContractValidityRequest(CustomProfile.Current.UserID, contractValidity, user.Language);

                return this.Json(new { @success = result });
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message });
            }
        }

        public JsonResult UpdateCPR(string username, string cpr, int intendedVolume)
        {
            try
            {
                UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                cmUser user = null;
                if (!string.IsNullOrEmpty(username))
                {
                    user = ua.GetByUsernameOrEmail(SiteManager.Current.DomainID, username, username);
                }
                else
                {
                    user = ua.GetByID(CustomProfile.Current.UserID);
                }

                if (user != null)
                {
                    user.PersonalID = cpr;
                    user.intendedVolume = intendedVolume;
                    GamMatrixClient.UpdateUserDetails(user);
                    return this.Json(new { @success = true });
                }
                else
                {
                    return this.Json(new { @success = false, @error = CM.Content.Metadata.Get("/Metadata/ServerResponse.UsernameNotExist").DefaultIfNullOrEmpty(string.Empty) });
                }
                
            }
            catch (Exception ex)
            {
                return this.Json(new { @success = false, @error = ex.Message });
            }
        }
    }
}
