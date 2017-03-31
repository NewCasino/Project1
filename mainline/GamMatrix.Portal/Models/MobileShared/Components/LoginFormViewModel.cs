using GamMatrix.CMS.Models.Common.Base;

namespace GamMatrix.CMS.Models.MobileShared.Components
{
	public class LoginFormViewModel : ViewModelBase
	{
		public bool Hidden { get; set; }

		public string RedirectUrl { private get; set; }

		public string GetRedirectUrl()
		{
			if (!string.IsNullOrEmpty(RedirectUrl))
				return RedirectUrl;

			if (!string.IsNullOrEmpty(Request.QueryString["redirect"]))
				return Request.QueryString["redirect"];

			if (Request.UrlReferrer != null)
				return Request.UrlReferrer.ToString();

			return UrlHelper.RouteUrl("Home");
		}
	}
}
