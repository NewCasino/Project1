using System;
using System.Web;
using System.Web.Mvc;
using CM.Sites;
using CM.Web;
using GamMatrix.CMS.Models.MobileShared.Home;

namespace GamMatrix.CMS.Controllers.MobileShared
{
	[HandleError]
	[MasterPageViewData(Name = "CurrentSectionMarkup", Value = "HomeSection")]
	[ControllerExtraInfo(DefaultAction = "Index")]
	public class MobileHomeController : ControllerEx
	{
		public virtual ActionResult Index()
		{
			CheckNativeApp();

			//redirect to custom DefaultUrl when accessing /Home explicitly
			if (!string.Equals(SiteManager.Current.DefaultUrl, "/Home", StringComparison.OrdinalIgnoreCase))
				return Redirect(SiteManager.Current.DefaultUrl);

			var model = new HomeViewModel();

			if (model.ActiveSections == 1)
			{
				var redirectRoute = model.EnableSports ? "Sports_Home"
					: model.EnableLiveCasino ? "LiveCasinoLobby"
					: "CasinoLobby";

				return Redirect(Url.RouteUrl(redirectRoute, new { btag = Request.QueryString["btag"] }));
			}

			return View(model);
		}

		protected void CheckNativeApp()
		{
			bool isNativeApp = false;

			if (!bool.TryParse(Request.QueryString["app_ios"], out isNativeApp)
				&& !bool.TryParse(Request.QueryString["app_android"], out isNativeApp))
				return;

			if (isNativeApp)
			{
				HttpCookie appCookie = new HttpCookie("M360_isNativeApp", "true");
				if (!string.IsNullOrWhiteSpace(SiteManager.Current.SessionCookieDomain))
					appCookie.Domain = SiteManager.Current.SessionCookieDomain;
				Response.AppendCookie(appCookie);
			}
		}
	}
}
