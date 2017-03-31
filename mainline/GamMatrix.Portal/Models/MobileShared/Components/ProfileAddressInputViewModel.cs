using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Web.Mvc;
using GamMatrix.CMS.Models.Common.Components.ProfileInput;

namespace GamMatrix.CMS.Models.MobileShared.Components
{
	public class ProfileAddressInputViewModel : ProfileInputView
	{
		private List<CountryInfo> CountryList;

		public ProfileAddressInputViewModel(ProfileInputSettings inputSettings) 
			: base(inputSettings) 
		{
			CountryList = CountryManager.GetAllCountries()
				.Where(c => c.UserSelectable && c.InternalID > 0)
				.OrderBy(c => c.DisplayName)
				.ToList();
		}

		public SelectList GetCountrySelect(string selectLabel)
		{
			var list = CountryList
						.Select(c => new { Key = c.InternalID.ToString(), Value = c.DisplayName })
						.ToList();
			list.Insert(0, new { Key = string.Empty, Value = selectLabel });

			string selection = InputSettings.Country;
			return new SelectList(list, "Key", "Value", selection);
		}

		public string GetCountryJSON()
		{
			StringBuilder json = new StringBuilder("{");
			foreach (CountryInfo countryInfo in CountryList)
			{
				json.AppendFormat(CultureInfo.InvariantCulture, "\"{0}\":{{\"p\":\"{1}\",\"c\":\"{2}\"}},"
					, countryInfo.InternalID
					, countryInfo.PhoneCode.SafeJavascriptStringEncode()
					, countryInfo.CurrencyCode.SafeJavascriptStringEncode()
					);
			}
			json.Remove(json.Length - 1, 1).Append("}");

			return json.ToString();
		}

		public SelectList GetMobilePrefixList(string selectLabel)
		{
			var list = CountryManager.GetAllPhonePrefix().Select(p => new { Key = p, Value = p }).ToList();
			list.Insert(0, new { Key = string.Empty, Value = selectLabel });

			string selection = InputSettings.MobilePrefix;
			return new SelectList(list, "Key", "Value", selection);
		}
	}
}
