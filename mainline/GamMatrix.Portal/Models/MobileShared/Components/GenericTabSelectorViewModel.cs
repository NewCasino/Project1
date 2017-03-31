using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;
using GamMatrix.CMS.Models.Common.Base;

namespace GamMatrix.CMS.Models.MobileShared.Components
{
	public class GenericTabSelectorViewModel : MultiuseView
	{
		public List<GenericTabData> Items { get; private set; }

		public GenericTabSelectorViewModel(List<GenericTabData> items)
		{
			Items = items;
		}

		private string FormatKey(string key)
		{
			return Regex.Replace(key, "[^a-zA-Z_.]+", "", RegexOptions.Compiled).ToLower();
		}

		public string GetItemAttributeHtml(int itemIndex)
		{
			var item = Items[itemIndex];

			if (item.Attributes == null)
				return "";

			StringBuilder formatted = new StringBuilder();
			foreach (KeyValuePair<string, string> attribute in item.Attributes)
			{
				formatted.Append("data-")
							.Append(FormatKey(attribute.Key))
							.Append("=")
							.Append("\"")
							.Append(attribute.Value.SafeHtmlEncode())
							.Append("\" ");
			}

			return formatted.ToString();
		}

		public string GetItemName(int itemIndex)
		{
			return Items[itemIndex].Name;
		}
	}
}
