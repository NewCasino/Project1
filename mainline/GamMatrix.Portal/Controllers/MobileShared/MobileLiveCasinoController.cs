using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using CasinoEngine;

using CM.Content;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.Web;
using GamMatrix.CMS.Models.MobileShared.LiveCasino;
using GmCore;

namespace GamMatrix.CMS.Controllers.MobileShared
{
	[HandleError]
	[MasterPageViewData(Name = "CurrentSectionMarkup", Value = "LiveCasinoSection")]
	[ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{tableID}")]
	public class MobileLiveCasinoController : ControllerEx
	{
		public ViewResult Index()
		{
			var provider = new LiveTableProvider();
			var categories = provider.GetCategories(GameMgr.GetLiveCasinoCategories(SiteManager.Current));

			categories.Insert(0, new LiveTableCategory
			{
				ID = "ALL",
				Name = Metadata.Get("/Metadata/LiveCasino/GameCategory/ALL.Text"),
				Tables = categories.SelectMany(c => c.Tables)
					.OrderByDescending(t => t.IsOpen)
					.ToList()
			});

			return View(categories);
		}

		[RequireLogin]
		public ActionResult Play(string tableID)
		{
			ViewResult errorView;
			if (!IsPlayAllowed(out errorView))
				return errorView;

			string tableUrl = GetTable(tableID).Url;

			string url = string.Format(CultureInfo.InvariantCulture, "{0}{1}_sid={2}&language={3}"
				, tableUrl
				, (tableUrl.IndexOf("?") > 0) ? "&" : "?"
                , CustomProfileEx.Current.SessionID
                , MultilingualMgr.GetCurrentCulture()
                );

            return Redirect(url);
		}

		private bool IsPlayAllowed(out ViewResult errorView)
		{
			if (!CustomProfileEx.Current.IsEmailVerified)
			{
				UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
				cmUser user = ua.GetByID(CustomProfileEx.Current.UserID);
				if (!user.IsEmailVerified)
				{
					errorView = View("EmailNotVerified");
					return false;
				}
			}

			if (CustomProfileEx.Current.IsInRole("Incomplete Profile"))
			{
				errorView = View("IncompleteProfile");
				return false;
			}

			if (CustomProfileEx.Current.IsInRole("Withdraw only"))
			{
				errorView = View("RestrictedCountry");
				return false;
			}

			errorView = null;
			return true;
		}

		private LiveCasinoTable GetTable(string tableID)
		{
			Dictionary<string, LiveCasinoTable> tables = CasinoEngineClient.GetLiveCasinoTables();
			LiveCasinoTable table;

			if (!tables.TryGetValue(tableID, out table))
				throw new HttpException(404, string.Empty);

			return table;
		}

        public ActionResult AllLiveTableDisplay()
        {
            var provider = new LiveTableProvider();
            var categories = provider.GetCategories(GameMgr.GetLiveCasinoCategories(SiteManager.Current));

            categories.Insert(0, new LiveTableCategory
            {
                ID = "ALL",
                Name = Metadata.Get("/Metadata/LiveCasino/GameCategory/ALL.Text"),
                Tables = categories.SelectMany(c => c.Tables)
                    .OrderByDescending(t => t.IsOpen)
                    .ToList()
            });

            return View(categories);
        }
	}
}
