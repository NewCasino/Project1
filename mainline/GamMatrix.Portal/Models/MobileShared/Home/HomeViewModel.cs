using System;

namespace GamMatrix.CMS.Models.MobileShared.Home
{
	public class HomeViewModel
	{
		public bool EnableCasino { get; private set; }
		public bool EnableLiveCasino { get; private set; }
		public bool EnableSports { get; private set; }

		public int ActiveSections { get; private set; }

		public HomeViewModel()
		{
			EnableCasino = Settings.Vendor_EnableCasino;
			EnableLiveCasino = Settings.Vendor_EnableLiveCasino;
			EnableSports = Settings.Vendor_EnableSports;
            if (EnableSports)
            {
                if (Settings.IsUKLicense && !Settings.IsOMAllowedonUKLicense)
                    EnableSports = false;
            }

			ActiveSections = 0
				+ Convert.ToInt32(EnableCasino)
				+ Convert.ToInt32(EnableLiveCasino)
				+ Convert.ToInt32(EnableSports);
		}
	}
}
