using System;
using System.Globalization;
using System.Web.Mvc;
using BLToolkit.DataAccess;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.Web;
using GmCore;

namespace GamMatrix.CMS.Controllers.Metro
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index")]
    public class ForgotUsernamePasswordController : ControllerEx
    {
        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        public ActionResult Index()
        {
            return View("Index");
        }

        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult SendEmail(string email, string birth, bool forgotUsername)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(email) ||
                    string.IsNullOrWhiteSpace(birth))
                {
                    throw new ArgumentNullException();
                }

                DateTime birthDate;
                if (!DateTime.TryParseExact(birth, "yyyy-M-d", CultureInfo.InvariantCulture, DateTimeStyles.None, out birthDate))
                    throw new Exception("Invalid date of birth.");

                // find the user by email
                UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                cmUser user = ua.GetByEmail( SiteManager.Current.DomainID, email);
                if( user == null || (user.Birth.HasValue && (birthDate - user.Birth.Value).TotalDays >= 1 ) )
                    return this.View("Error");

                if (forgotUsername)
                {
                    Email mail = new Email();
                    mail.LoadFromMetadata("UsernameReminder", user.Language);
                    mail.ReplaceDirectory["USERNAME"] = user.Username;
                    mail.ReplaceDirectory["FIRSTNAME"] = user.FirstName;
                    mail.Send(user.Email);
                }
                else
                {
                    SendEmail(this.Url, user);
                }

                return this.View("EmailSent");
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return this.View("Error");
            }
        }

        private static void SendEmail(UrlHelper urlHelper, cmUser user)
        {
            // create the cmUserKey for reset password
            SqlQuery<cmUserKey> query = new SqlQuery<cmUserKey>();
            cmUserKey userKey = new cmUserKey();
            userKey.KeyType = "ResetPassword";
            userKey.KeyValue = Guid.NewGuid().ToString();
            userKey.UserID = user.ID;
            userKey.Expiration = DateTime.Now.AddDays(1);
            userKey.DomainID = SiteManager.Current.DomainID;
            query.Insert(userKey);

            // send the email
            Email mail = new Email();
            mail.LoadFromMetadata("ResetPassword", user.Language);
            mail.ReplaceDirectory["USERNAME"] = user.Username;
            mail.ReplaceDirectory["FIRSTNAME"] = user.FirstName;
            mail.ReplaceDirectory["RESETLINK"] = urlHelper.RouteUrlEx("ForgotPassword", new { @action = "ChangePassword", @key = userKey.KeyValue });
            mail.Send(user.Email);
        }
    }
}
