using System.Collections.Generic;
using System.Linq;
using CM.Content;
using GamMatrix.CMS.Models.Common.Base;

namespace GamMatrix.CMS.Models.MobileShared.Components
{
	public class MetadataContent : ViewModelBase
	{
		protected string MetadataDirectory { get; private set; }
		public List<string> ContentPaths { get; protected set; }
		public bool NoData { get; protected set; }

		public MetadataContent(string metadataDirectory)
		{
			if (string.IsNullOrEmpty(metadataDirectory))
			{
				NoData = true;
				return;
			}

			MetadataDirectory = metadataDirectory;
			ContentPaths = Metadata.GetChildrenPaths(metadataDirectory).ToList();
			if (ContentPaths.Count == 0)
				NoData = true;
		}
	}
}
