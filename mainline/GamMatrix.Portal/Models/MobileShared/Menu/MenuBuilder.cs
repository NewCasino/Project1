using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using CM.Content;
using GamMatrix.CMS.Models.Common.Base;

namespace GamMatrix.CMS.Models.MobileShared.Menu
{
	public class MenuBuilder : ViewModelBase
	{
		public List<MenuEntry> BuildEntries(List<MenuEntry> entries, string metadataPath)
		{
			return PopulateEntries(entries, metadataPath);
		}

		/// <summary>
		/// Creates a menu list based on the given entries. 
		/// The ID of the entries must match metadata names. 
		/// Does not set urls
		/// </summary>
		public MenuList BuildEntries(List<MenuEntry> entries, string metadataPath, int columns)
		{
			return new MenuList(PopulateEntries(entries, metadataPath), columns);
		}

		private List<MenuEntry> PopulateEntries(List<MenuEntry> entries, string metadataPath)
		{
			var processed = new List<MenuEntry>();

			foreach (string path in Metadata.GetChildrenPaths(metadataPath))
			{
				var id = path.Substring(path.LastIndexOf('/') + 1);
				var entry = entries
					.Where(e => e.ID == id && !e.Restricted)
					.FirstOrDefault();

				if (entry != null)
				{
                    if (!SafeParseBoolString(GetMetadata(string.Format("{0}.Hide", path)), false))
                    {
                        entry.Name = GetMetadata(string.Format("{0}.Name", path));
                        if (entry.CssClass == null)
                            entry.CssClass = string.Format("{0}Page", entry.ID);

                        processed.Add(entry);
                    }
				}	
			}

			return processed;
		}

        private static bool SafeParseBoolString(string text, bool defValue)
        {
            if (string.IsNullOrWhiteSpace(text))
                return defValue;

            text = text.Trim();

            if (Regex.IsMatch(text, @"(YES)|(ON)|(OK)|(TRUE)|(\1)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled))
                return true;

            if (Regex.IsMatch(text, @"(NO)|(OFF)|(FALSE)|(\0)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled))
                return false;

            return defValue;
        }
	}
}
