using GamMatrix.CMS.Models.Common.Base;

namespace GamMatrix.CMS.Models.MobileShared.Components
{
	public class AddApplicationViewModel : ViewModelBase
	{
		private bool IsNativeApp;
		private TerminalType UserDevice;

		public bool EnableIOS { get; private set; }
		public bool EnableAndroid { get; private set; }

		public string NativeAppUrl { get; private set; }
		public bool ShowAddToHome { get; private set; } 

		public AddApplicationViewModel()
		{
			IsNativeApp = (Request.Cookies["M360_isNativeApp"] != null);
			UserDevice = Request.GetTerminalType();

			EnableIOS = !IsNativeApp && (UserDevice == TerminalType.iPhone || UserDevice == TerminalType.iPad);
			EnableAndroid = !IsNativeApp && UserDevice == TerminalType.Android;

			if (EnableIOS)
				NativeAppUrl = GetMetadata("/Metadata/Settings.NativeApp_IOS");
			else if (EnableAndroid)
				NativeAppUrl = GetMetadata("/Metadata/Settings.NativeApp_Android");

			ShowAddToHome = (Request.Cookies["M360_ATH"] == null);
		}
	}
}
