using System.Linq;
using System.Web.Mvc;
using CM.Content;
using CM.Sites;
using GamMatrix.CMS.Models.Common.Components.ProfileInput;
using GmCore;

namespace GamMatrix.CMS.Models.MobileShared.Components
{
	public class ProfileAccountInputViewModel : ProfileInputView
	{
		public ProfileAccountInputViewModel(ProfileInputSettings inputSettings) 
			: base(inputSettings) { }

		public SelectList GetCurrencyList()
		{
			var list = GamMatrixClient.GetSupportedCurrencies()
							.FilterForCurrentDomain()
							.Select(c => new { Key = c.Code, Value = c.GetDisplayName() })
							.ToList();

			string selection = InputSettings.Currency;
			return new SelectList(list, "Key", "Value", selection);
		}

		public SelectList GetSecurityQuestionList(string selectLabel)
		{
			string[] paths = Metadata.GetChildrenPaths("/Metadata/SecurityQuestion");

			var list = paths.Select(p => new { Key = GetMetadata(p + ".Text"), Value = GetMetadata(p + ".Text") }).ToList();
			list.Insert(0, new { Key = "", Value = selectLabel });

			string selection = InputSettings.SecurityQuestion;
			return new SelectList(list, "Key", "Value", selection);
		}

		public SelectList GetLanguageList()
		{
			var list = SiteManager.Current.GetSupporttedLanguages().Select(l => new { Key = l.LanguageCode, Value = l.DisplayName }).ToList();

			string selection = MultilingualMgr.GetCurrentCulture();
			return new SelectList(list, "Key", "Value", selection);
		}
	}
}
