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

namespace GamMatrix.CMS.Controllers._666bet
{
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{paymentMethodName}/{sid}")]
    public class _666betWithdrawController : GamMatrix.CMS.Controllers.Shared.WithdrawController
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

            return Prepare("IPG");
        }

        [HttpPost]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public void ProcessIPGTransactionAsync(string paymentMethodName
            , long gammingAccountID
            , string currency
            , string amount
            , long payCardID
            , string requestCreditCurrency
            )
        {
            string bankName = null;
            InternalPrepareTransactionAsync(paymentMethodName
                , gammingAccountID
                , currency
                , amount
                , payCardID
                , requestCreditCurrency
                , false
                , bankName
                );
        }

        private void OnProcessIPGTransactionCompleted(AsyncResult reply)
        {
            try
            {
                AsyncManager.Parameters["prepareTransRequest"] = reply.EndSingleRequest().Get<PrepareTransRequest>();
            }
            catch (Exception ex)
            {
                AsyncManager.Parameters["exception"] = ex;
            }
            finally
            {
                AsyncManager.OutstandingOperations.Decrement();
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
                    cmTransParameter.SaveObject<string>(pid
                                , "Sid"
                                , prepareTransRequest.Record.Sid
                                );

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
                            return View("Error");
                        }
                    }
                    throw;
                }
            }
            catch (Exception ex)
            {
                string friendlyError = GmException.TryGetFriendlyErrorMsg(ex);
                if (prepareTransRequest != null && prepareTransRequest.Record != null)
                    cmTransParameter.SaveObject<string>(prepareTransRequest.Record.Sid, "LastError", friendlyError);
                this.ViewData["ErrorMessage"] = friendlyError;
                return View("Error");
            }
        }

    }
}
