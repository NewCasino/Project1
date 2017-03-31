using System;
using System.Linq;
using System.Web.Mvc;

using CM.Content;
using CM.db;
using CM.State;
using CM.Web;
using Finance;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Controllers._666betMobile
{
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{paymentMethodName}/{sid}")]
    public class _666betMobileWithdrawController : GamMatrix.CMS.Controllers.MobileShared.MobileWithdrawController
    {
        /// <summary>
        ///  The list view
        /// </summary>
        /// <returns></returns>
        [HttpGet]
        public override ActionResult Index()
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return View("Anonymous");

            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
                .FirstOrDefault(p => string.Equals(p.UniqueName, "IPG", StringComparison.InvariantCultureIgnoreCase));
            if (paymentMethod == null)
                throw new ArgumentOutOfRangeException();

            if (!base.CheckPaymentMethod(paymentMethod))
                return View("NotAllowed");

            return Account("IPG");
        }

        [HttpPost]
        public void ProcessIPGTransactionAsync(string paymentMethodName
            , long gammingAccountID
            , string currency
            , string amount
            , long? payCardID
            )
        {
            try
            {
                PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
                    .FirstOrDefault(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.InvariantCultureIgnoreCase));
                if (paymentMethod == null)
                    throw new ArgumentOutOfRangeException("paymentMethodName");

                if (!payCardID.HasValue)
                    payCardID = 0;

                if (!payCardID.HasValue || payCardID <= 0)
                {
                    var payCard = GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.IPG)
                                  .FirstOrDefault(e => e.IsDummy);
                    if (payCard == null)
                        throw new Exception("IPG is not configrured in GmCore correctly, missing dummy pay card.");
                    payCardID = payCard.ID;
                }

                base.InternalPrepareTransactionAsync(paymentMethodName
                    , gammingAccountID
                    , currency
                    , amount
                    , payCardID.Value
                    , null
                    , true
                    );
            }
            catch (Exception ex)
            {
                AsyncManager.Parameters["exception"] = ex;
            }
        }

        public ActionResult ProcessIPGTransactionCompleted(PrepareTransRequest prepareTransRequest
            , Exception exception
            , string paymentMethodName
            , long gammingAccountID
            , string pid
            )
        {
            try
            {
                try
                {
                    if (exception != null)
                        throw exception;

                    cmTransParameter.SaveObject<PrepareTransRequest>(prepareTransRequest.Record.Sid
                                , "PrepareTransRequest"
                                , prepareTransRequest
                                );

                    if (pid != null)
                    {
                        cmTransParameter.SaveObject<string>(pid
                                    , "Sid"
                                    , prepareTransRequest.Record.Sid
                                    );
                    }

                    if (prepareTransRequest.Record.Status != PreTransStatus.AsyncSent)
                        throw new NotSupportedException();

                    this.ViewData["FormHtml"] = prepareTransRequest.RedirectForm;
                    return View("PaymentFormPost");
                }
                catch (GmException gex)
                {
                    // Withdrawals from $ACCOUNT_NAME$ are not allowed while you have an active bonus. 
                    // In order to make a transfer or withdrawal from your $ACCOUNT_NAME$ account, 
                    // the remaining bonus wagering requirements must be met.
                    if (string.Equals(gex.ReplyResponse.ErrorCode, "SYS_1114", StringComparison.InvariantCulture))
                    {
                        string message = Metadata.Get("/Metadata/GmCoreErrorCodes/SYS_1114.UserMessage");
                        var account = GamMatrixClient.GetUserGammingAccounts(CustomProfile.Current.UserID).FirstOrDefault(a => a.ID == gammingAccountID);
                        if (account != null)
                        {
                            string accountName = Metadata.Get(string.Format("/Metadata/GammingAccount/{0}.Display_Name", account.Record.VendorID));
                            message = message.Replace("$ACCOUNT_NAME$", accountName);
                            this.ViewData["ErrorMessage"] = message;
                            return this.View("Error");
                        }
                    }
                    throw;
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return this.View("Error");
            }
        }


    }
}
