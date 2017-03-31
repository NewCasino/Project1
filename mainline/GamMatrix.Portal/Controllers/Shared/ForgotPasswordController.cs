using System;
using System.Collections.Generic;
using System.Web.Mvc;
using BLToolkit.DataAccess;
using CM.Content;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.State;
using CM.Web;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Controllers.Shared
{
    [HandleError]
    [CustomValidateAntiForgeryToken]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{key}")]
    public class ForgotPasswordController : ControllerEx
    {

        protected virtual string GetKeyUrl(UrlHelper urlHelper, cmUser user)
        {
            SqlQuery<cmUserKey> query = new SqlQuery<cmUserKey>();
            cmUserKey userKey = new cmUserKey();
            userKey.KeyType = "ResetPassword";
            userKey.KeyValue = Guid.NewGuid().ToString();
            userKey.UserID = user.ID;
            userKey.Expiration = DateTime.Now.AddDays(1);
            userKey.DomainID = SiteManager.Current.DomainID;
            query.Insert(userKey);
            return urlHelper.RouteUrlEx("ForgotPassword", new { @action = "ChangePassword", @key = userKey.KeyValue });
        }


        //internal static 
       //  protected internal virtual
        internal virtual void SendEmail(UrlHelper urlHelper, cmUser user)
        {
            // send the email
            Email mail = new Email();
            mail.LoadFromMetadata("ResetPassword", user.Language);
            mail.ReplaceDirectory["USERNAME"] = user.Username;
            mail.ReplaceDirectory["FIRSTNAME"] = user.FirstName;
            mail.ReplaceDirectory["RESETLINK"] = GetKeyUrl(urlHelper, user);
            mail.Send(user.Email);  
        }

        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        public ActionResult Index()
        {
            return View("Index");
        }

        [OutputCache(Duration = 0, VaryByParam = "None")]        
        public ActionResult SendEmail(string email, string captcha)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(email) ||
                    string.IsNullOrWhiteSpace(captcha))
                {
                    //throw new ArgumentNullException();
                    return Redirect(Url.RouteUrl("ForgotPassword", new { action = "Index" }));
                }
                // for servers behind load balance, we need ensure the Permanent Session is on in LB
                // otherwise the cache may not be found
                string captchaToCompare = null;

                captchaToCompare = CustomProfile.Current.Get("captcha");
                CustomProfile.Current.Set("captcha", null);

                if (!string.Equals(captcha.Trim(), captchaToCompare, StringComparison.InvariantCultureIgnoreCase))
                    return this.View("CaptchaNotMatch");

                // find the user by email
                UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                cmUser user = ua.GetByEmail( SiteManager.Current.DomainID, email);
                if (user == null)
                {
                    string errorMessage = Metadata.Get("/Metadata/ServerResponse.EmailNotExist");
                    throw new UnauthorizedAccessException(errorMessage);
                }

                SendEmail(this.Url, user);

                return this.View("EmailSent");
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return this.View("Error");
            }
        }

        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        public ActionResult ChangePassword(string key)
        {
            try
            {
                UserKeyAccessor uka = UserKeyAccessor.CreateInstance<UserKeyAccessor>();
                cmUserKey userKey = uka.GetResetPasswordKey(SiteManager.Current.DomainID, key, DateTime.Now);
                if( userKey == null )
                    return View("InvalidLink");

                if (userKey.IsDeleted)
                    return View("PasswordChanged");

                UserAccessor userAccessor = UserAccessor.CreateInstance<UserAccessor>();
                cmUser user = userAccessor.GetByID(userKey.UserID);

                Dictionary<string, string> dic = new Dictionary<string, string>();
                dic.Add("Key", key);                
                if (user != null)
                {
                    dic.Add("Username", user.Username);
                }
                return View("ChangePassword", (object)dic);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return this.View("Error");
            }
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult SetPassword(string key, string newPassword)
        {
            try
            {
                UserKeyAccessor uka = UserKeyAccessor.CreateInstance<UserKeyAccessor>();
                cmUserKey userKey = uka.GetResetPasswordKey(SiteManager.Current.DomainID, key, DateTime.Now);
                if (userKey == null)
                    return View("InvalidLink");

                if( userKey.IsDeleted )
                    return View("PasswordChanged");

                UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                cmUser user = ua.GetByID(userKey.UserID);

                UserPasswordHistoryAccessor upha = DataAccessor.CreateInstance<UserPasswordHistoryAccessor>();
                string newPasswordHash = PasswordHelper.CreateEncryptedPassword(user.PasswordEncMode/*SiteManager.Current.PasswordEncryptionMode*/, newPassword);

                if (Settings.Password_CheckPasswordHistory)
                {                    
                    if (newPasswordHash.Equals(user.Password))
                        return View("PasswordEverUsed");
                    
                    if(upha.Exists(SiteManager.Current.DomainID, userKey.UserID,newPasswordHash))
                        return View("PasswordEverUsed");
                }

                using (GamMatrixClient client = GamMatrixClient.Get() )
                {
                    ChangeUserPasswordRequest changeUserPasswordRequest = client.SingleRequest<ChangeUserPasswordRequest>(
                        new ChangeUserPasswordRequest()
                        {
                            UserID = userKey.UserID,
                            PlainTextPassword = newPassword,
                            CheckOldPassword = false,
                        });
                }
                
                uka.DeleteKey(SiteManager.Current.DomainID, key);
                if (!upha.Exists(SiteManager.Current.DomainID, CustomProfile.Current.UserID))
                    upha.Create(SiteManager.Current.DomainID, userKey.UserID, user.Password, DateTime.Now);
                    
                upha.Create(SiteManager.Current.DomainID, userKey.UserID, newPasswordHash, DateTime.Now);

                return View("PasswordChanged");
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return this.View("Error");
            }
        }
    }
}
