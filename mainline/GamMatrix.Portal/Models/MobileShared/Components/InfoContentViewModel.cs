using GamMatrix.CMS.Models.Common.Base;

namespace GamMatrix.CMS.Models.MobileShared.Components
{
	public class InfoContentViewModel : ViewModelBase
	{
		private string MetadataPath { get; set; }

		public InfoContentViewModel(string metadataPath)
		{
			MetadataPath = metadataPath;
		}

		public string GetTitle()
		{
			return GetMetadata(MetadataPath + ".Title");
		}

		public string GetContent()
		{
			return GetMetadata(MetadataPath + ".Html");
		}

        public string GetPartialView()
        {
            return GetMetadata(MetadataPath + ".PartialView");
        }
	}
}
