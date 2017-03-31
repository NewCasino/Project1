using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web.Mvc;

using CM.db;
using CM.Sites;
using CM.State;
using CM.Web;
using Finance;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Controllers._666bet
{
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{paymentMethodName}/{sid}")]
    public class _666betDepositController : GamMatrix.CMS.Controllers.Shared.DepositController
    {
        /// <summary>
        ///  The list view
        /// </summary>
        /// <returns></returns>
        [HttpGet]
        public override ActionResult Index()
        {
            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
                .FirstOrDefault(p => string.Equals(p.UniqueName, "IPG", StringComparison.InvariantCultureIgnoreCase));
            if (paymentMethod == null)
                throw new ArgumentOutOfRangeException();

            if (!base.CheckPaymentMethod(paymentMethod))
                return View("AccessDenied");

            return Prepare("IPG");
        }

        [HttpPost]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public void ProcessIPGTransactionAsync(string paymentMethodName
            , long gammingAccountID
            , string currency
            , string amount
            , long payCardID
            , string bonusCode
            , string bonusVendor
            , string issuer
            , string paymentType
            , string tempExternalReference
            )
        {
            AsyncManager.Parameters["paymentMethodName"] = paymentMethodName;
            AsyncManager.Parameters["gammingAccountID"] = gammingAccountID;
            AsyncManager.Parameters["currency"] = currency;
            AsyncManager.Parameters["amount"] = amount;
            AsyncManager.Parameters["payCardID"] = payCardID;
            AsyncManager.Parameters["bonusCode"] = bonusCode;
            AsyncManager.Parameters["issuer"] = issuer;
            AsyncManager.Parameters["outRange"] = "0";

            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
                .FirstOrDefault(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.InvariantCultureIgnoreCase));
            if (paymentMethod == null)
                throw new ArgumentOutOfRangeException();
            Range rgAmount = paymentMethod.GetDepositLimitation(currency);
            decimal decCurrent = 0;
            decimal.TryParse(Regex.Replace(amount, @"[^\d\.]", string.Empty)
                            , NumberStyles.Number | NumberStyles.AllowDecimalPoint
                            , CultureInfo.InvariantCulture
                            , out decCurrent);

            AsyncManager.Parameters["paymentMethod"] = paymentMethod;

            if (CustomProfile.Current.IsAuthenticated)
            {

                decimal requestAmount = decimal.Parse(Regex.Replace(amount, @"[^\d\.]", string.Empty), CultureInfo.InvariantCulture);
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    if (decCurrent > 0 &&
                        ((rgAmount.MinAmount >= rgAmount.MaxAmount && decCurrent >= rgAmount.MinAmount) ||
                        (decCurrent >= rgAmount.MinAmount && decCurrent <= rgAmount.MaxAmount)))
                    {
                        PrepareTransRequest prepareTransRequest = new PrepareTransRequest()
                        {
                            Record = new PreTransRec()
                            {
                                TransType = TransType.Deposit,
                                DebitPayCardID = payCardID,
                                CreditAccountID = gammingAccountID,
                                RequestAmount = requestAmount,
                                RequestCurrency = currency,
                                UserID = CustomProfile.Current.UserID,
                                UserIP = Request.GetRealUserAddress(),
                                PaymentType = paymentType,
                                TempExternalReference = tempExternalReference,
                            },
                            IsWindowOwner = false,
                            IsRequiredRedirectForm = true,
                            RedirectFormName = "depositForm",
                            RedirectFormTarget = "_self",
                            IsRequiredRedirectURL = false,
                            PostBackURL = this.Url.RouteUrlEx("Deposit", new { @action = "Postback", @paymentMethodName = paymentMethodName }),
                            PostBackURLTarget = "_self",
                            CancelURL = this.Url.RouteUrlEx("Deposit", new { @action = "Cancel" }),
                            CancelURLTarget = "_self",
                            ReturnURL = this.Url.RouteUrlEx("Deposit", new { @action = "Return" }),
                            ReturnURLTarget = "_self",
                            //DepositSource = DepositSource.MainDepositPage,
                        };



                        if (!string.IsNullOrWhiteSpace(bonusCode))
                        {
                            List<AccountData> accounts = GamMatrixClient.GetUserGammingAccounts(CustomProfile.Current.UserID);
                            AccountData account = accounts.FirstOrDefault(a => a.ID == gammingAccountID);
                            if (account != null)
                            {
                                VendorID bonusVendorID = VendorID.Unknown;
                                if (!string.IsNullOrWhiteSpace(bonusVendor))
                                {
                                    Enum.TryParse(bonusVendor, out bonusVendorID);
                                }
                                if (bonusVendorID == VendorID.Unknown)
                                    bonusVendorID = account.Record.VendorID;

                                prepareTransRequest.ApplyBonusVendorID = bonusVendorID;
                                prepareTransRequest.ApplyBonusCode = bonusCode.Trim();
                            }
                        }

                        GamMatrixClient.SingleRequestAsync<PrepareTransRequest>(prepareTransRequest
                            , OnProcessIPGTransactionCompleted
                            );
                        AsyncManager.OutstandingOperations.Increment();
                    }
                    else
                    {
                        AsyncManager.Parameters["outRange"] = "1";
                    }

                }// using
            }//if
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
            , PaymentMethod paymentMethod
            )
        {
            try
            {
                if (string.Compare("1", AsyncManager.Parameters["outRange"].ToString(), false) == 0)
                {
                    throw new Exception("OUTRANGE");
                    //return this.Json(new
                    //{
                    //    @success = false,
                    //    @error = "OUTRANGE",
                    //});
                }
                if (!CustomProfile.Current.IsAuthenticated)
                    throw new UnauthorizedAccessException();

                if (exception != null)
                    throw exception;

                string receiptUrl = this.Url.RouteUrlEx("Deposit", new { @action = "Receipt", @paymentMethodName = paymentMethodName, @sid = prepareTransRequest.Record.Sid });

                CustomProfile.Current.Set("ReceiptUrl", receiptUrl);

                cmTransParameter.SaveObject<PrepareTransRequest>(prepareTransRequest.Record.Sid
                    , "PrepareTransRequest"
                    , prepareTransRequest
                    );
                cmTransParameter.SaveObject<string>(prepareTransRequest.Record.Sid
                    , "UserID"
                    , CustomProfile.Current.UserID.ToString()
                    );
                cmTransParameter.SaveObject<string>(prepareTransRequest.Record.Sid
                    , "SessionID"
                    , CustomProfile.Current.SessionID
                    );
                cmTransParameter.SaveObject<string>(prepareTransRequest.Record.Sid
                    , "SuccessUrl"
                    , prepareTransRequest.ReturnURL
                    );
                cmTransParameter.SaveObject<string>(prepareTransRequest.Record.Sid
                    , "CancelUrl"
                    , prepareTransRequest.CancelURL
                    );
                //bool showTC = prepareTransRequest.IsFirstDepositBonusAvailableAndRequireTC;
                //if (showTC)
                //{
                //    string cookieName = string.Format("GM_{0}", gammingAccountID);
                //    HttpCookie cookie = Request.Cookies[cookieName];
                //    if (cookie != null && !string.IsNullOrWhiteSpace(cookie.Value))
                //    {
                //        bool accepted = true;
                //        if (bool.TryParse(cookie.Value, out accepted))
                //        {
                //            cmTransParameter.SaveObject<bool>(prepareTransRequest.Record.Sid, "BonusAccepted", accepted);
                //            showTC = false;
                //        }
                //    }
                //}
                //return this.Json(new
                //{
                //    @success = true,
                //    @sid = prepareTransRequest.Record.Sid,
                //    @showTC = showTC
                //});
                this.ViewData["FormHtml"] = prepareTransRequest.RedirectForm;
                return View("PaymentFormPost");
            }
            catch (Exception ex)
            {
                //Logger.Exception(ex);
                //return this.Json(new
                //{
                //    @success = false,
                //    @error = GmException.TryGetFriendlyErrorMsg(ex),
                //});
                Logger.Exception(ex);
                string friendlyError = GmException.TryGetFriendlyErrorMsg(ex);
                this.ViewData["ErrorMessage"] = friendlyError;
                return View("Error");
            }
        }

    }
}
