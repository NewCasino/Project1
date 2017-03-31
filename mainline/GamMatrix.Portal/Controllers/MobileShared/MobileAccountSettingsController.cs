using System;
using System.Web;
using System.Web.Mvc;
using CM.Sites;
using CM.Web;

namespace GamMatrix.CMS.Controllers.MobileShared
{
	[HandleError]
    [MasterPageViewData(Name = "CurrentSectionMarkup", Value = "AccountSettingsSection")]
	[ControllerExtraInfo(DefaultAction = "Index")]
	public class MobileAccountSettingsController : ControllerEx
	{
		[HttpGet]
		public ActionResult Index()
		{
			return View("Index");
		}

        [HttpPost]
        [CustomValidateAntiForgeryToken]
		public ActionResult Update(string oddsFormat, string timeZone)
		{
			HttpCookie emZone = new HttpCookie("EM_timeZone", timeZone);
			HttpCookie omOdds = new HttpCookie("OM_oddsFormat", oddsFormat);

			emZone.Expires = omOdds.Expires = DateTime.Now.AddMonths(6);
			if (!string.IsNullOrWhiteSpace(SiteManager.Current.SessionCookieDomain))
				emZone.Domain = omOdds.Domain = SiteManager.Current.SessionCookieDomain;

			if (timeZone == "")
				emZone.Expires = DateTime.Now.AddDays(-1d);

			Response.AppendCookie(emZone);
			Response.AppendCookie(omOdds);

			return View("Success");
		}
	}
}