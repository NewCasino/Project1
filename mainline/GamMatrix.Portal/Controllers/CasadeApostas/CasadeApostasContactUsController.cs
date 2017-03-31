using System;
using System.Web.Mvc;
using CM.Content;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.State;
using CM.Web;
using GmCore;
using GamMatrix.CMS.Controllers.Shared;

namespace GamMatrix.CMS.Controllers.CasadeApostas
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index")]
    public class CasadeApostasContactUsController : ContactUsController
    {
        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public ActionResult Send2(string email, string name, string subject, string content, string captcha, string telephone, string subjectType)
        {
			if (!CheckCaptcha(captcha))
                return this.Json(new { @success = false, @error = Metadata.Get("/Components/_Captcha_ascx.Captcha_Invalid") });

            // send the email
			try
			{
                SendEmailToUser(email, name, subject, content, telephone, subjectType);
				return this.Json(new { success = true });
			}
			catch (Exception ex)
			{
				Logger.Exception(ex);
				return this.Json(new { success = false, error = GmException.TryGetFriendlyErrorMsg(ex) });
			}
        }

        protected void SendEmailToUser(string email, string name, string subject, string content, string telephone, string subjectType)
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
                    telephone = user.PhonePrefix + "-" + user.Phone;
				}
			}

			mail.ReplaceDirectory["EMAIL"] = email;
			mail.ReplaceDirectory["USERID"] = userID;
			mail.ReplaceDirectory["USERNAME"] = username;
            mail.ReplaceDirectory["NAME"] = name;
            mail.ReplaceDirectory["TELEPHONE"] = telephone;
            mail.ReplaceDirectory["SUBJECTTYPE"] = subjectType;
			mail.ReplaceDirectory["SUBJECT"] = subject.SafeHtmlEncode();
			mail.ReplaceDirectory["CONTENT"] = content.SafeHtmlEncode();
			mail.Subject = subject;
			mail.Send(Settings.Email_ContactUs);  
		}
    }
}
