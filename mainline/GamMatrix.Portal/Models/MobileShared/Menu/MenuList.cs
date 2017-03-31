using System;
using System.Collections.Generic;
using System.Linq;

namespace GamMatrix.CMS.Models.MobileShared.Menu
{
	public class MenuList
	{
		public List<MenuEntry> Entries { get; private set; }
		public int Columns { get; private set; }

		public MenuList(List<MenuEntry> entries, int columns)
		{
			Entries = entries;
			Columns = columns;
		}

		public List<MenuEntry> GetEntriesForColumn(int column)
		{
			if (column < 0 || column > Columns - 1)
				throw new ArgumentOutOfRangeException("column");

			int itemsPerColumn = (int)Math.Ceiling((double)Entries.Count() / Columns);
			return Entries.Skip(itemsPerColumn * column).Take(itemsPerColumn).ToList();
		}
	}
}
