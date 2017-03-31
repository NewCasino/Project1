using System;
using System.Web.Mvc;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.State;
using CM.Web;
using GmCore;

namespace GamMatrix.CMS.Controllers.Shared
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{key}")]
    public class ForgotUsernameController : ControllerEx
    {

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
                    throw new ArgumentNullException();
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
                cmUser user = ua.GetByEmail(SiteManager.Current.DomainID, email);
                if (user == null)
                    throw new UnauthorizedAccessException();

                // send the email
                Email mail = new Email();
                mail.LoadFromMetadata("UsernameReminder", user.Language);
                mail.ReplaceDirectory["USERNAME"] = user.Username;
                mail.ReplaceDirectory["FIRSTNAME"] = user.FirstName;
                mail.Send(user.Email);

                return this.View("EmailSent");
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
