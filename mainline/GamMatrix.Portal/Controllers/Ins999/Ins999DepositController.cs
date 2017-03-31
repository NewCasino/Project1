using System;
using System.Collections.Generic;
using System.Web.Mvc;

using CM.Web;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Controllers.Ins999
{
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{paymentMethodName}/{sid}")]
    public class Ins999DepositController: GamMatrix.CMS.Controllers.Shared.DepositController
    {
        /// <summary>
        ///  The list view
        /// </summary>
        /// <returns></returns>
        [HttpGet]
        public override ActionResult Index()
        {
            return Prepare("LocalBank");
        }

        [HttpPost]
        public void VerifyUniqueLocalBankAccountNumberAsync(string bankAccountNumber, string message)
        {
            AsyncManager.Parameters["bankAccountNumber"] = bankAccountNumber;
            AsyncManager.Parameters["isBankAccountNumberAvailable"] = true;
            AsyncManager.Parameters["message"] = message;
            try
            {
                List<PayCardInfoRec> payCards = GamMatrixClient.GetPayCards(VendorID.LocalBank);
                if (payCards != null && payCards.Exists(p => p.BankAccountNo.Equals(bankAccountNumber, StringComparison.InvariantCultureIgnoreCase)))
                    AsyncManager.Parameters["isBankAccountNumberAvailable"] = false;
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }
        }

        public JsonResult VerifyUniqueLocalBankAccountNumberCompleted(string alias, string message)
        {
            try
            {
                bool isAvailable = (bool)AsyncManager.Parameters["isBankAccountNumberAvailable"];

                return this.Json(new
                {
                    @success = isAvailable,
                    @value = AsyncManager.Parameters["bankAccountNumber"],
                    @error = AsyncManager.Parameters["message"],
                });
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new
                {
                    @success = false,
                    @value = alias,
                    @error = GmException.TryGetFriendlyErrorMsg(ex),
                });
            }
        }
    }
}
