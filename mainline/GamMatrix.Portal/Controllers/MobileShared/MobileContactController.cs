using System;
using System.Web.Mvc;
using CM.Content;
using CM.db;
using CM.db.Accessor;
using CM.State;
using CM.Web;
using GamMatrix.CMS.Controllers.Shared;
using GmCore;

namespace GamMatrix.CMS.Controllers.MobileShared
{
	/// <summary>
	/// Summary description for ContactUsController
	/// </summary>
	[HandleError]
	[MasterPageViewData(Name = "CurrentSectionMarkup", Value = "ContactSection")]
	[ControllerExtraInfo(DefaultAction = "Index")]
	public class MobileContactController : ContactUsController
	{
        [HttpPost]
        [CustomValidateAntiForgeryToken]
		public override ActionResult Send(string email, string name, string subject, string content, string captcha)
		{
			if (!CheckCaptcha(captcha))
			{
				ViewData["ErrorMessage"] = Metadata.Get("/Components/_Captcha_ascx.Email_Incorrect");
				return View("Error");
			}

			if (CustomProfile.Current.IsAuthenticated)
			{
				UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
				cmUser user = ua.GetByID(CustomProfile.Current.UserID);

				name = string.Format("{0} {1}", user.FirstName, user.Surname);
				email = user.Email;
			}

			// send the email
			try
			{
				SendEmailToUser(email, name, subject, content);
				return this.Redirect(this.Url.Action("Success"));
			}
			catch (Exception ex)
			{
				Logger.Exception(ex);
				ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
				return View("Error");
			}
		}


		public ViewResult Success()
		{
			return View();
		}
	}
}