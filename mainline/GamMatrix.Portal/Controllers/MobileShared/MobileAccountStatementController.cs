using System;
using System.Collections.Generic;
using System.Globalization;
using System.Web.Mvc;
using CM.Web;
using GamMatrix.CMS.Controllers.Shared;
using GamMatrix.CMS.Domain.AccountStatement;
using GamMatrixAPI;

namespace GamMatrix.CMS.Controllers.MobileShared
{
    [HandleError]
	[RequireLogin]
	[MasterPageViewData(Name = "CurrentSectionMarkup", Value = "AccountStatementSection")]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "")]
    public class MobileAccountStatementController : AccountStatementController
    {
        public override ActionResult Index()
        {
            return View("Index");
        }

		public override ActionResult Search(TransactionStatementType filterType, string filterDateFrom = null, string filterDateTo = null, string pageIndex = "1")
		{
			string transView;
			switch (filterType)
			{
				case TransactionStatementType.CasinoWalletCreditDebit:
				case TransactionStatementType.MicrogamingWalletCreditDebit:
				case TransactionStatementType.ViGWalletCreditDebit:
				case TransactionStatementType.IGTWalletCreditDebit:
					transView = "WalletCreditDebit";
					break;
				default:
					transView = Enum.GetName(typeof(TransactionStatementType), filterType);
					break;
			}

			#region date processing
			DateTime fromDate = DateTime.Now.AddMonths(-1), toDate = DateTime.Now;
			if (!string.IsNullOrEmpty(filterDateFrom))
			{
				if (!DateTime.TryParse(filterDateFrom, CultureInfo.InvariantCulture.DateTimeFormat, DateTimeStyles.None, out fromDate))
				{
					filterDateFrom = null;
				}
			}

			if (!string.IsNullOrEmpty(filterDateTo))
			{
				if (!DateTime.TryParse(filterDateTo, CultureInfo.InvariantCulture.DateTimeFormat, DateTimeStyles.None, out toDate))
				{
					filterDateTo = null;
				}
			}

			if (filterDateFrom == null && filterDateTo == null)
			{
				fromDate = DateTime.Now.AddMonths(-1);
				toDate = DateTime.Now;
			}
			else if (filterDateFrom != null && filterDateTo == null)
			{
				toDate = fromDate.AddMonths(1);
			}
			else if (filterDateFrom == null && filterDateTo != null)
			{
				fromDate = toDate.AddMonths(-1);
			}

			fromDate = fromDate.Date.AddSeconds(-1);
			toDate = toDate.Date.AddDays(1).AddSeconds(-1);
			#endregion

            if (filterType == TransactionStatementType.Gambling)
            {
                this.ViewData["FilterDateFrom"] = fromDate;
                this.ViewData["FilterDateTo"] = toDate;
                return View(transView);
            }

			var provider = new TransactionStatementProvider();
			List<TransInfoRec> transactions = provider.CreateStatement(filterType).GetTransactions(fromDate, toDate);

			return View(transView, transactions);
		}
    }
}