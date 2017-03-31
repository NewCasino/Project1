using System.Collections.Generic;
using System.Linq;
using CM.Content;

namespace GamMatrix.CMS.Models.MobileShared.Promotions.Home
{
	public class PresentationListViewModel : PromotionsContent
	{
		public PresentationListViewModel(string metadataDirectory)
			: base(metadataDirectory)
		{
			string[] sectionPaths = Metadata.GetChildrenPaths(metadataDirectory);

			ContentPaths = new List<string>();
			foreach (string path in sectionPaths)
				ContentPaths.AddRange(Metadata.GetChildrenPaths(path)
					.Where(p => !string.IsNullOrEmpty(
						GetMetadata(string.Format("{0}/.BannerUrl", p)))));
			if (ContentPaths.Count == 0)
				NoData = true;
		}
	}
}
