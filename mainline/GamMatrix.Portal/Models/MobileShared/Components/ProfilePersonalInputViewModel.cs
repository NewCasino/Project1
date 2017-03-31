using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Web.Mvc;
using GamMatrix.CMS.Models.Common.Components.ProfileInput;

namespace GamMatrix.CMS.Models.MobileShared.Components
{
	public class ProfilePersonalInputViewModel : ProfileInputView
	{
		public DateSelectorView DateSelect { get; private set; }

		public ProfilePersonalInputViewModel(ProfileInputSettings inputSettings) 
			: base(inputSettings) 
		{
			if (inputSettings.Birth.HasValue)
				DateSelect = new DateSelectorView(inputSettings.Birth.Value);
			else
				DateSelect = new DateSelectorView();
		}

		private class TitleComparer : IEqualityComparer<KeyValuePair<string, string>>
		{
			public bool Equals(KeyValuePair<string, string> x, KeyValuePair<string, string> y)
			{
				return string.Compare(x.Value, y.Value, true) == 0;
			}

			public int GetHashCode(KeyValuePair<string, string> obj)
			{
				return obj.Value.GetHashCode();
			}
		}

		public SelectList GetTitleList(string metaPath, string selectLabel, object selectedValue = null)
		{
			Dictionary<string, string> titleList = new Dictionary<string, string>();
			titleList.Add("", selectLabel);
			titleList.Add("Mr.", GetMetadata(metaPath + ".Mr"));
			titleList.Add("Mrs.", GetMetadata(metaPath + ".Mrs"));
			titleList.Add("Miss", GetMetadata(metaPath + ".Miss"));
			titleList.Add("Ms.", GetMetadata(metaPath + ".Ms"));
			var list = titleList.AsEnumerable().Where(t => !string.IsNullOrWhiteSpace(t.Value)).Distinct(new TitleComparer());

			return new SelectList(list, "Key", "Value", selectedValue);
		}

		public string GetLegalAgeDate()
		{
			return DateTime.Now.AddYears(-1 * Settings.Registration.LegalAge).ToString("yyyy, M - 1, d");
		}

		public string GetPersonalIdRulesJson()
		{
			StringBuilder json = new StringBuilder();
			json.Append("{");

			List<CountryInfo> countries = CountryManager.GetAllCountries().Where(c => c.IsPersonalIdVisible).ToList();
			foreach (CountryInfo country in countries)
			{
				json.AppendFormat(CultureInfo.InvariantCulture
					, "\"{0}\":{1},"
					, country.InternalID
					, GetPersonalIDRulesByCountryJson(country.InternalID)
					);
			}
			if (json[json.Length - 1] == ',')
				json.Remove(json.Length - 1, 1);

			json.Append("}");
			return json.ToString();
		}

		private string GetPersonalIDRulesByCountryJson(int CountryId)
		{
			var country = CountryManager.GetAllCountries().FirstOrDefault(c => c.InternalID == CountryId);
			return string.Format("{{\"visible\":{1},\"required\":{2},\"validator\":\"{3}\",\"length\":{4}}}"
				, country.InternalID
				, country.IsPersonalIdVisible.ToString().ToLowerInvariant()
				, country.IsPersonalIdMandatory.ToString().ToLowerInvariant()
				, country.PersonalIdValidationRegularExpression.SafeJavascriptStringEncode()
				, country.PersonalIdMaxLength.ToString("D0")
				);
		}
	}
}
