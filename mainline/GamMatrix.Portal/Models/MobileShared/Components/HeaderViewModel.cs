using GamMatrix.CMS.Models.Common.Base;

namespace GamMatrix.CMS.Models.MobileShared.Components
{
	public class HeaderViewModel : RemoteableView
	{
		public bool DisableAccount = false;
		public bool GenericHomeButton = false;

		public string GetLoginUrl()
		{
			string url;

			if (IsLocalSite)
				url = UrlHelper.RouteUrl("Login");
			else
				url = UrlHelper.RouteUrl("Login", new { redirect = UrlHelper.RouteUrl("Sports_Home") });

			return url;
		}

		public bool HasGenericHome()
		{
			return GenericHomeButton || (!Settings.Vendor_EnableSports || !Settings.Vendor_EnableCasino);
		}
	}
}
