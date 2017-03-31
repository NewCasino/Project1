using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Web.Mvc;
using CM.Sites;
using CM.State;
using CM.Web;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Controllers.PlayAdjara
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index")]
    public class PlayAdjaraProfileController : AsyncControllerEx
    {
        [HttpGet]
        public void GetGammingAccountsAsync(bool? useCache)
        {
            if (CustomProfile.Current.IsAuthenticated)
            {
                if (!useCache.HasValue)
                    useCache = true;

                AsyncManager.OutstandingOperations.Increment();
                GamMatrixClient.GetUserGammingAccountsAsync(CustomProfile.Current.UserID, OnGetGammingAccounts, useCache.Value);
            }
        }

        private void OnGetGammingAccounts(List<AccountData> accounts)
        {
            AsyncManager.Parameters["accounts"] = accounts;
            AsyncManager.OutstandingOperations.Decrement();
        }

        public JsonResult GetGammingAccountsCompleted(List<AccountData> accounts)
        {
            try
            {
                if (!CustomProfile.Current.IsAuthenticated)
                    return this.Json(new { @success = false, @error = "Your session has timed out, please login again.", @isSessionTimedOut = true }, JsonRequestBehavior.AllowGet);

                if (accounts == null)
                    return this.Json(new { @success = false, @error = string.Empty }, JsonRequestBehavior.AllowGet);

                decimal total = accounts.Where(a => a.Record.ActiveStatus == GamMatrixAPI.ActiveStatus.Active && a.IsBalanceAvailable)
                    .Sum(a => Finance.MoneyHelper.TransformCurrency(a.BalanceCurrency, "GEL", a.BalanceAmount));

                return this.Json(new { @success = true
                    , @totalBalanceAmount = total.ToString("F2", CultureInfo.InvariantCulture) 
                }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception exception)
            {
                Logger.Exception(exception);
                return this.Json(new { @success = false, @error = GmException.TryGetFriendlyErrorMsg(exception) }, JsonRequestBehavior.AllowGet);
            }
        }

        
    }
}