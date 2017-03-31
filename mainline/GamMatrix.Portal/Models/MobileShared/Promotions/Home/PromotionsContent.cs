using GamMatrix.CMS.Models.MobileShared.Components;

namespace GamMatrix.CMS.Models.MobileShared.Promotions.Home
{
	public class PromotionsContent : MetadataContent 
	{
		private string TermsBaseUrl;

		public PromotionsContent(string metadataDirectory)
			: base(metadataDirectory)
		{
			TermsBaseUrl = UrlHelper.RouteUrl("Promotions_TermsConditions");
		}

		public string GetTermsUrl(string path)
		{
			string[] segments = path.Split(new [] { '/' });

			string section = segments[segments.Length - 2];
			string promo = segments[segments.Length - 1];
			return string.Format("{0}/{1}/{2}", TermsBaseUrl, section, promo);
		}
	}
}
