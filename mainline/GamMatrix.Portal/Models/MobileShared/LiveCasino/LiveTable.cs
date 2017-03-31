namespace GamMatrix.CMS.Models.MobileShared.LiveCasino
{
	public class LiveTable
	{
		public string ID;
		public string VendorID;

		public string Name;
		public string LaunchUrl;
		public string ThumbnailUrl;

		public string Limits;
		public string OpeningHours;

		public bool IsOpen;

        public bool VisibleOnSmallDevice;

		public bool HasLimits()
		{
			return !string.IsNullOrEmpty(Limits);
		}
	}
}
