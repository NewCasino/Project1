using System;
using System.Web.Mvc;
using BLToolkit.DataAccess;
using CM.Content;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.State;
using CM.Web;
using GmCore;

namespace GamMatrix.CMS.Controllers.Shared
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index")]
    public class ChangeEmailController : ControllerEx
    {
        [HttpGet]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        public ActionResult Index()
        {
            if (CustomProfile.Current.IsAuthenticated)
            {
                UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                cmUser user = ua.GetByID(CustomProfile.Current.UserID);
                if (!user.IsEmailVerified)
                    return View("EmailNotVerified");

                // if the profile is uncompleted, redirect user to profile page
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
                    !user.Birth.HasValue ||
                    CustomProfile.Current.IsInRole("Incomplete Profile"))
                {
                    return View("IncompleteProfile");
                }
            }
            return View("Index");
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public ActionResult ChangeEmail(string email, string password, string captcha)
        {
            try
            {
                if (!CustomProfile.Current.IsAuthenticated)
                    throw new UnauthorizedAccessException();


                string captchaToCompare = null;

                captchaToCompare = CustomProfile.Current.Get("captcha");
                CustomProfile.Current.Set("captcha", null);

                if (!string.Equals(captcha.Trim(), captchaToCompare, StringComparison.InvariantCultureIgnoreCase))
                {
                    this.ViewData["ErrorMessage"] = Metadata.Get("/Components/_Captcha_ascx.Captcha_Invalid");
                    return View("Error");
                }

                // find the user by email
                UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                cmUser user = ua.GetByID(CustomProfile.Current.UserID);
                if (user == null)
                    throw new UnauthorizedAccessException();

                // compare the password
                string hashedPassword = PasswordHelper.CreateEncryptedPassword(SiteManager.Current.PasswordEncryptionMode, password);
                if (!string.Equals(user.Password, hashedPassword, StringComparison.InvariantCultureIgnoreCase))
                {
                    return View("Error_IncorrectPassword");
                }

                // create the cmUserKey for reset password
                SqlQuery<cmUserKey> query = new SqlQuery<cmUserKey>();
                cmUserKey userKey = new cmUserKey();
                userKey.KeyType = "ChangeEmail";
                userKey.KeyValue = Guid.NewGuid().ToString();
                userKey.UserID = CustomProfile.Current.UserID;
                userKey.Expiration = DateTime.Now.AddDays(1);
                userKey.DomainID = SiteManager.Current.DomainID;
                userKey.Email = email;
                query.Insert(userKey);

                // send the email
                Email mail = new Email();
                mail.LoadFromMetadata("ChangeEmail", MultilingualMgr.GetCurrentCulture());
                mail.ReplaceDirectory["USERNAME"] = user.Username;
                mail.ReplaceDirectory["FIRSTNAME"] = user.FirstName;
                mail.ReplaceDirectory["ACTIVELINK"] = this.Url.RouteUrlEx("ChangeEmail", new { @action = "ActivateNewEmail", @key = userKey.KeyValue });
                mail.Send(email);

                mail = new Email();
                mail.LoadFromMetadata("ChangeEmailNotification", MultilingualMgr.GetCurrentCulture());
                mail.ReplaceDirectory["USERNAME"] = user.Username;
                mail.ReplaceDirectory["EMAIL"] = email;
                mail.ReplaceDirectory["FIRSTNAME"] = user.FirstName;
                mail.Send(user.Email);

                return View("Success");
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return View("Error");
            }
        }

        public ActionResult ActivateNewEmail(string key)
        {
            UserKeyAccessor uka = UserKeyAccessor.CreateInstance<UserKeyAccessor>();
            cmUserKey userKey = uka.GetChangeEmailKey(SiteManager.Current.DomainID, key, DateTime.Now);
            if (userKey == null)
            {
                return View("Error_InvalidLink");
            }

            UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
            cmUser user = ua.GetByID(userKey.UserID);
            if( user == null )
            {
                return View("Error_InvalidLink");
            }

            if (user.Email != userKey.Email)
            {
                user.Email = userKey.Email;
                GamMatrixClient.UpdateUserDetails(user);

                if (!user.IsEmailVerified)
                {
                    ua.VerifyEmail(user.ID);
                }
            }

            return View("Success_NewEmailActivated");
        }
    }
}
