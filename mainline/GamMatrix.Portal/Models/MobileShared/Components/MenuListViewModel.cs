using System.Text.RegularExpressions;

namespace GamMatrix.CMS.Models.MobileShared.Components
{
	public class MenuListViewModel : MetadataContent
	{
		private string RedirectUrlBase { get; set; }

		public MenuListViewModel(string metadataDirectory, string redirectUrlBase = null)
			: base(metadataDirectory)
		{
			if (string.IsNullOrEmpty(redirectUrlBase))
			{
				Match m = Regex.Match(Request.Path, @"^\/(?<baseUrl>\w+)(\/.*)?", RegexOptions.ECMAScript);
				if (m.Success)
					RedirectUrlBase = string.Format("/{0}", m.Groups["baseUrl"].Value);
			}
			else
				RedirectUrlBase = redirectUrlBase;
		}

		public string GetItemUrl(string path)
		{
			return RedirectUrlBase + path.Substring(MetadataDirectory.Length);
		}

		public string GetItemTitle(string path)
		{
			return GetMetadata(path + ".Title");
		}
	}
}
