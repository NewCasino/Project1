using System.Collections.Generic;
using System.Linq;
using CasinoEngine;
using CM.Content;
using GamMatrix.CMS.Models.Common.Base;

namespace GamMatrix.CMS.Models.MobileShared.LiveCasino
{
	public class LiveTableProvider : ViewModelBase
	{
		public List<LiveTableCategory> GetCategories(IEnumerable<LiveCasinoCategory> source)
		{
			return source
				.Where(t => t.Tables.Count > 0)
				.Select(t => new LiveTableCategory
				{
					ID = t.CategoryKey,
					Name = t.CategoryName,
					Tables = GetTables(t.Tables)
				})
				.ToList();
		}

		public List<LiveTable> GetTables(IEnumerable<LiveCasinoTable> source)
		{
			return source
				.Select(t => GetTable(t))
				.OrderByDescending(t => t.IsOpen)
				.ToList();
		}

		public LiveTable GetTable(LiveCasinoTable source)
		{
			var table = new LiveTable();

			table.ID = source.ID;
			table.VendorID = source.VendorID.ToString();

			table.Name = source.Name;
			table.LaunchUrl = UrlHelper.RouteUrl("LiveCasinoLobby", new { action = "Play", tableID = table.ID });
			table.ThumbnailUrl = source.ThumbnailUrl;
            string defaultCurrency = Metadata.Get("/Metadata/Settings.LiveCasino_DefaultCurrency").DefaultIfNullOrEmpty("EUR");
            table.Limits = source.GetLimit(Profile.UserCurrency.DefaultIfNullOrEmpty(defaultCurrency));
			table.OpeningHours = source.OpeningHours;

			table.IsOpen = source.IsOpened;

			return table;
		}
	}
}
