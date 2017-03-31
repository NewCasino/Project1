using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web.Mvc;
using CM.Content;
using CM.db;
using CM.Sites;
using CM.State;
using CM.Web;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Controllers.Shared
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl="{sid}")]
    public class TransferController : AsyncControllerEx
    {
        
        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        [HttpGet]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        public ActionResult Index()
        {
            if (CustomProfile.Current.IsAuthenticated && CustomProfile.Current.IsInRole("Withdraw only"))
                return View("GamblingRegulationsRestriction");

            return View("Index");
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public void PrepareTransactionAsync(long debitGammingAccountID
            , long creditGammingAccountID
            , string currency
            , string amount
            , string bonusCode
            )
        {
            AsyncManager.Parameters["debitGammingAccountID"] = debitGammingAccountID;
            AsyncManager.Parameters["creditGammingAccountID"] = creditGammingAccountID;
            AsyncManager.Parameters["currency"] = currency;
            AsyncManager.Parameters["amount"] = amount;
            AsyncManager.Parameters["bonusCode"] = bonusCode;

            if (CustomProfile.Current.IsAuthenticated)
            {

                decimal requestAmount = decimal.Parse(Regex.Replace(amount, @"[^\.\d]", string.Empty, RegexOptions.ECMAScript), CultureInfo.InvariantCulture);
                PrepareTransRequest prepareTransRequest = new PrepareTransRequest()
                {
                    Record = new PreTransRec()
                    {
                        TransType = TransType.Transfer,
                        DebitAccountID = debitGammingAccountID,
                        CreditAccountID = creditGammingAccountID,
                        RequestAmount = requestAmount,
                        RequestCurrency = currency,
                        UserID = CustomProfile.Current.UserID,
                        UserIP = Request.GetRealUserAddress(),
                    }
                };

                if (!string.IsNullOrWhiteSpace(bonusCode))
                {
                    List<AccountData> accounts = GamMatrixClient.GetUserGammingAccounts(CustomProfile.Current.UserID);
                    AccountData account = accounts.FirstOrDefault(a => a.ID == creditGammingAccountID);
                    if (account != null)
                    {
                        prepareTransRequest.ApplyBonusVendorID = account.Record.VendorID;
                        prepareTransRequest.ApplyBonusCode = bonusCode.Trim();
                    }
                }

                GamMatrixClient.SingleRequestAsync<PrepareTransRequest>(prepareTransRequest
                        , OnPrepareTransactionCompleted
                        );
                AsyncManager.OutstandingOperations.Increment();
            }
        }

        private void OnPrepareTransactionCompleted(AsyncResult reply)
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

        public virtual ActionResult PrepareTransactionCompleted(PrepareTransRequest prepareTransRequest
            , Exception exception
            , string paymentMethodName
            , long debitGammingAccountID
            )
        {
            try
            {
                if (!CustomProfile.Current.IsAuthenticated)
                    throw new UnauthorizedAccessException();

                try
                {
                    if (exception != null)
                        throw exception;

                    cmTransParameter.SaveObject<PrepareTransRequest>(prepareTransRequest.Record.Sid
                        , "PrepareTransRequest"
                        , prepareTransRequest
                        );

                    return this.Json(new
                    {
                        @success = true,
                        @sid = prepareTransRequest.Record.Sid
                    });
                }
                catch (GmException gex)
                {
                    // Withdrawals from $ACCOUNT_NAME$ are not allowed while you have an active bonus. 
                    // In order to make a transfer or withdrawal from your $ACCOUNT_NAME$ account, 
                    // the remaining bonus wagering requirements must be met.
                    if (string.Equals(gex.ReplyResponse.ErrorCode, "SYS_1114", StringComparison.InvariantCulture))
                    {
                        string message = Metadata.Get("/Metadata/GmCoreErrorCodes/SYS_1114.UserMessage");
                        var account = GamMatrixClient.GetUserGammingAccounts(CustomProfile.Current.UserID).FirstOrDefault(a => a.ID == debitGammingAccountID);
                        if (account != null)
                        {
                            string accountName = Metadata.Get(string.Format("/Metadata/GammingAccount/{0}.Display_Name", account.Record.VendorID));
                            message = message.Replace("$ACCOUNT_NAME$", accountName);
                            return this.Json(new
                            {
                                @success = false,
                                @error = message,
                            });
                        }
                    }
                    throw;
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new
                {
                    @success = false,
                    @error = GmException.TryGetFriendlyErrorMsg(ex),
                });
            }
        }

        [HttpGet]
        public ActionResult Confirmation(string sid)
        {
            try
            {
                if (!CustomProfile.Current.IsAuthenticated)
                    return View("Anonymous");

                PrepareTransRequest prepareTransRequest = cmTransParameter.ReadObject<PrepareTransRequest>(sid, "PrepareTransRequest");
                if (prepareTransRequest == null)
                    throw new ArgumentOutOfRangeException("sid");

                return View("Confirmation", prepareTransRequest);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return View("Error");
            }
        }

        #region Confirm
        public void ConfirmAsync(string sid)
        {
            AsyncManager.Parameters["sid"] = sid;

            if (CustomProfile.Current.IsAuthenticated)
            {
                ProcessTransRequest processTransRequest = new ProcessTransRequest()
                {
                    SID = sid
                };

                GamMatrixClient.SingleRequestAsync<ProcessTransRequest>(processTransRequest, OnProcessTransactionCompleted);
                AsyncManager.OutstandingOperations.Increment();
            }
        }

        private void OnProcessTransactionCompleted(AsyncResult result)
        {
            try
            {
                AsyncManager.Parameters["processTransRequest"] = result.EndSingleRequest().Get<ProcessTransRequest>();
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

        public virtual ActionResult ConfirmCompleted(string sid
            , ProcessTransRequest processTransRequest
            , Exception exception
            )
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return View("Anonymous");

            if (exception != null)
            {
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(exception);
                return View("Error");
            }
            cmTransParameter.SaveObject<ProcessTransRequest>(sid
                , "ProcessTransRequest"
                , processTransRequest
                );

			string url = this.Url.Action("Receipt", new { @sid = sid });
			return this.Redirect(url);
        }
        #endregion


        [HttpGet]
        public virtual ActionResult Receipt(string sid)
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return View("Anonymous");
            try
            {
                PrepareTransRequest prepareTransRequest = cmTransParameter.ReadObject<PrepareTransRequest>(sid, "PrepareTransRequest");
                if (prepareTransRequest == null)
                    throw new ArgumentOutOfRangeException("sid");

                ProcessTransRequest processTransRequest = cmTransParameter.ReadObject<ProcessTransRequest>(sid, "ProcessTransRequest");
                if (processTransRequest == null)
                    throw new ArgumentOutOfRangeException("sid");

                GetTransInfoRequest getTransInfoRequest;
                using (GamMatrixClient client = GamMatrixClient.Get() )
                {
                    getTransInfoRequest = client.SingleRequest<GetTransInfoRequest>(new GetTransInfoRequest()
                    {
                        SID = sid,
                        NoDetails = true,
                    });
                }

                this.ViewData["prepareTransRequest"] = prepareTransRequest;
                this.ViewData["processTransRequest"] = processTransRequest;
                this.ViewData["getTransInfoRequest"] = getTransInfoRequest;

                return View("Receipt");
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return View("Error");
            }
        }

        [HttpGet]
        public ActionResult Dialog()
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return View("Anonymous");

            return this.View("Dialog");
        }

        [HttpGet]
        [MasterPageViewData(Name = "CurrentPageClass", Value = "QuickTransfer")]
        public ActionResult QuickTransfer()
        {
            return this.View("QuickTransfer");
        }
    }
}
