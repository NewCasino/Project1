using System;
using System.Web.Mvc;
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
    public class ContactUsController : ControllerEx
    {
        [HttpGet]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        public ActionResult Index()
        {
            return this.View();
        }


        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public virtual ActionResult Send(string email, string name, string subject, string content, string captcha)
        {
			if (!CheckCaptcha(captcha))
                return this.Json(new { @success = false, @error = Metadata.Get("/Components/_Captcha_ascx.Captcha_Invalid") });

            // send the email
			try
			{
				SendEmailToUser(email, name, subject, content);
				return this.Json(new { success = true });
			}
			catch (Exception ex)
			{
				Logger.Exception(ex);
				return this.Json(new { success = false, error = GmException.TryGetFriendlyErrorMsg(ex) });
			}
        }

		protected bool CheckCaptcha(string captcha)
		{
			 // for servers behind load balance, we need ensure the Permanent Session is on in LB
            // otherwise the cache may not be found
            string captchaToCompare = null;

            captchaToCompare = CustomProfile.Current.Get("captcha");
            CustomProfile.Current.Set("captcha", null);

			return string.Equals(captcha.Trim(), captchaToCompare, StringComparison.InvariantCultureIgnoreCase);
		}

		protected void SendEmailToUser(string email, string name, string subject, string content)
		{
			Email mail = new Email();
			mail.LoadFromMetadata("ContactUs", "en");
			string userID = "<Anonymous User>".SafeHtmlEncode();
			string username = "<Anonymous User>".SafeHtmlEncode();

			if (CustomProfile.Current.IsAuthenticated)
			{
				UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
				cmUser user = ua.GetByID(CustomProfile.Current.UserID);
				if (user != null)
				{
					email = user.Email;
					name = string.Format("{0} {1}", user.FirstName, user.Surname);
					userID = CustomProfile.Current.UserID.ToString();
					username = CustomProfile.Current.UserName.ToString().SafeHtmlEncode();
				}
			}

			mail.ReplaceDirectory["EMAIL"] = email;
			mail.ReplaceDirectory["USERID"] = userID;
			mail.ReplaceDirectory["USERNAME"] = username;
			mail.ReplaceDirectory["NAME"] = name;
			mail.ReplaceDirectory["SUBJECT"] = subject.SafeHtmlEncode();
			mail.ReplaceDirectory["CONTENT"] = content.SafeHtmlEncode();
			mail.Subject = subject;
			mail.Send(Settings.Email_ContactUs);  
		}
    }
}
