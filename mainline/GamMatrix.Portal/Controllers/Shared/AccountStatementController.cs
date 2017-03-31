using System;
using System.Globalization;
using System.Web.Mvc;
using CM.Sites;
using CM.State;
using CM.Web;
using GamMatrix.CMS.Domain.AccountStatement;
using GamMatrixAPI;

namespace GamMatrix.CMS.Controllers.Shared
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl="")]
    public class AccountStatementController : ControllerEx
    {
        /// <summary>
        ///  The list view
        /// </summary>
        /// <returns></returns>
        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        public virtual ActionResult Index()
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return View("Anonymous");

            return View("Index");
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public virtual ActionResult Search(TransactionStatementType filterType, string filterDateFrom = null, string filterDateTo = null, string pageIndex = "1")
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return View("Anonymous");

            this.ViewData["filterType"] = filterType;
            this.ViewData["pageIndex"] = pageIndex;

            #region
            DateTime dFilterDateFrom = DateTime.Now.AddMonths(-1), dFilterDateTo = DateTime.Now;
            if (!string.IsNullOrEmpty(filterDateFrom))
            {
                if (!DateTime.TryParse(filterDateFrom, CultureInfo.InvariantCulture.DateTimeFormat, DateTimeStyles.None, out dFilterDateFrom))
                {
                    filterDateFrom = null;
                }
            }

            if (!string.IsNullOrEmpty(filterDateTo))
            {
                if (!DateTime.TryParse(filterDateTo, CultureInfo.InvariantCulture.DateTimeFormat, DateTimeStyles.None, out dFilterDateTo))
                {
                    filterDateTo = null;
                }
            }

            if (filterDateFrom == null && filterDateTo == null)
            {
                dFilterDateFrom = DateTime.Now.AddMonths(-1);
                dFilterDateTo = DateTime.Now;
            }
            else if (filterDateFrom != null && filterDateTo == null)
            {
                dFilterDateTo = dFilterDateFrom.AddMonths(1);
            }
            else if (filterDateFrom == null && filterDateTo != null)
            {
                dFilterDateFrom = dFilterDateTo.AddMonths(-1);
            }            

            dFilterDateFrom = dFilterDateFrom.Date.AddSeconds(-1);
            dFilterDateTo = dFilterDateTo.Date.AddDays(1).AddSeconds(-1);
            #endregion

            string viewName = null;
            switch (filterType)
            {
                case TransactionStatementType.CakeNetworkWalletCreditDebit:
                    this.ViewData["VendorID"] = VendorID.CakeNetwork;
                    viewName = "WalletCreditDebit";
                    break;

                case TransactionStatementType.CasinoWalletCreditDebit:
                    this.ViewData["VendorID"] = VendorID.CasinoWallet;
                    viewName = "WalletCreditDebit";
                    break;

                case TransactionStatementType.MergeNetworkWalletCreditDebit:
                    this.ViewData["VendorID"] = VendorID.MergeNetwork;
                    viewName = "WalletCreditDebit";
                    break;

                case TransactionStatementType.MicrogamingWalletCreditDebit:
                    this.ViewData["VendorID"] = VendorID.Microgaming;
                    viewName = "WalletCreditDebit";
                    break;

                case TransactionStatementType.ViGWalletCreditDebit:
                    this.ViewData["VendorID"] = VendorID.ViG;
                    viewName = "WalletCreditDebit";
                    break;

                case TransactionStatementType.IGTWalletCreditDebit:
                    this.ViewData["VendorID"] = VendorID.IGT;
                    viewName = "WalletCreditDebit";
                    break;

                default:
                    viewName = filterType.ToString();
                    break;
            }

            return View(viewName, this.ViewData.Merge(new { FilterDateFrom = dFilterDateFrom, FilterDateTo = dFilterDateTo }));
        }
    }
}
