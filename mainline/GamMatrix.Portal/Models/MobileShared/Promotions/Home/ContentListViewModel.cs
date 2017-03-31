namespace GamMatrix.CMS.Models.MobileShared.Promotions.Home
{
	public class ContentListViewModel : PromotionsContent
	{
		public ContentListViewModel(string metadataDirectory)
			: base(metadataDirectory)
		{
		}

		public string GetPromoTitle(string path)
		{
			return GetMetadata(path + ".Title");
		}

		public string GetPromoSummary(string path)
		{
			return GetMetadata(path + ".Summary");
		}
	}
}
