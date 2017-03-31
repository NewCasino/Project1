using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web.Mvc;
using CM.Content;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.State;
using CM.Web;
using Finance;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Controllers.MobileShared
{
    [HandleError]
    [RequireLogin]
    [MasterPageViewData(Name = "CurrentSectionMarkup", Value = "WithdrawSection")]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{paymentMethodName}/{sid}")]
    public class MobileWithdrawController : GamMatrix.CMS.Controllers.Shared.WithdrawController
    {
        [HttpGet]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        public override ActionResult Index()
        {
            return base.Index();
        }

        [HttpGet]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        public ActionResult Account(string paymentMethodName)
        {
            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
                    .FirstOrDefault(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.InvariantCultureIgnoreCase));
            if (paymentMethod == null)
                throw new ArgumentOutOfRangeException("paymentMethodName");

            if (!CheckPaymentMethod(paymentMethod))
                return RedirectToIndex();

            if (paymentMethod.VendorID == VendorID.APX)
            {
                if (!paymentMethod.SupportWithdraw)
                    return RedirectToIndex();
            }
            // will go to view when ArtemisBank
            //else if (paymentMethod.VendorID == VendorID.ArtemisBank)
            //{

            //}
            else if ( //paymentMethod.VendorID == VendorID.ArtemisBank|| 
                paymentMethod.VendorID == VendorID.TurkeyBank)
            {
                PaymentMethod apx = PaymentMethodManager.GetPaymentMethods()
                    .FirstOrDefault(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.InvariantCultureIgnoreCase));
                if (apx != null && apx.SupportWithdraw)
                    return RedirectToIndex();
            }

            return View(paymentMethod);
        }

        private RedirectResult RedirectToIndex()
        {
            return Redirect(Url.RouteUrl("Withdraw", new { action = "Index" }));
        }

        [HttpGet]
        public RedirectResult Prepare()
        {
            return RedirectToIndex();
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]        
        public override ActionResult Prepare(string paymentMethodName)
        {
            this.ViewData["StateVars"] = new Dictionary<string, string>()
			{
				{ "amount", Request.Form["amount"] },
				{ "currency", Request.Form["currency"] },
				{ "gammingAccountID", Request.Form["gammingAccountID"] },
			};

            return base.Prepare(paymentMethodName);
        }

        [HttpGet]
        public RedirectResult MobilePrepareTransaction()
        {
            return RedirectToIndex();
        }

        private JsonResult IovationCheck(string iovationBlackBox)
        {
            if (!CustomProfile.Current.IsAuthenticated || !Settings.IovationDeviceTrack_Enabled)
                return null;

            string error = null;
            //if (string.IsNullOrEmpty(iovationBlackBox))
            //{
            //    error = GamMatrixClient.GetIovationError(eventType: IovationEventType.Withdrawal);
            //    //"iovationBlackBox requreid !";
            //}
            //else
            //{
                if (!GamMatrixClient.IovationCheck(CustomProfile.Current.UserID, IovationEventType.Withdrawal, iovationBlackBox))
                {
                    error = GamMatrixClient.GetIovationError(false, IovationEventType.Withdrawal); 
                }
            //}

            if (error == null)
                return null;

            return this.Json(new
            {
                @success = false,
                @error = error
            });
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public void MobilePrepareTransactionAsync(string paymentMethodName
            , long gammingAccountID
            , string currency
            , string amount
            , long? payCardID
            , string iovationBlackbox = null
            )
        {

            var iovationResult = IovationCheck(iovationBlackbox);
            if (iovationResult != null)
            {
                AsyncManager.Parameters["iovationResult"] = iovationResult;
                return;
            }

            try
            {
                PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
                    .FirstOrDefault(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.InvariantCultureIgnoreCase));
                if (paymentMethod == null)
                    throw new ArgumentOutOfRangeException("paymentMethodName");

                if (!payCardID.HasValue)
                    payCardID = 0;

                switch (paymentMethod.VendorID)
                {
                    case VendorID.Bank:
                        {
                            int countryID = 0;
                            VendorID vendorID = VendorID.Bank;
                            int.TryParse(Request["countryID"]
                                , NumberStyles.Integer
                                , CultureInfo.InvariantCulture
                                , out countryID
                                );
                            Enum.TryParse<VendorID>(Request["vendorID"], out vendorID);

                            InternalPrepareBankTransactionAsync(paymentMethodName
                                , gammingAccountID
                                , currency
                                , amount
                                , payCardID.Value
                                , vendorID // only available for new bank
                                , countryID // only available for new bank
                                , Request["bankName"]
                                , Request["bankCode"]
                                , Request["branchAddress"]
                                , Request["branchCode"]
                                , Request["payee"]
                                , Request["payeeAddress"]
                                , Request["accountNumber"]
                                , Request["iban"]
                                , Request["swift"]
                                , Request["checkDigits"]
                                , Request["additionalInformation"]
                                , Request["bankCurrency"]
                                );
                            break;
                        }

                    case VendorID.PaymentTrust:
                        {
                            if (!payCardID.HasValue)
                                throw new ArgumentNullException("payCardID");
                            base.InternalPrepareTransactionAsync(paymentMethodName
                                , gammingAccountID
                                , currency
                                , amount
                                , payCardID.Value
                                , null
                                , true
                                );
                            break;
                        }
                    case VendorID.TLNakit:
                        {
                            InternalPrepareTLNakitTransactionAsync(paymentMethodName
                                , gammingAccountID
                                , currency
                                , amount
                                , payCardID.Value
                                , Request.Form["identityNumber"]
                                );
                            break;
                        }
                    case VendorID.Moneybookers:
                        {
                            InternalPrepareMoneybookersTransactionAsync(paymentMethodName
                                , gammingAccountID
                                , currency
                                , amount
                                , payCardID.Value
                                , Request.Form["identityNumber"]
                                );
                            break;
                        }
                    case VendorID.Neteller:
                        {
                            InternalPrepareNetellerTransactionAsync(paymentMethodName
                                , gammingAccountID
                                , currency
                                , amount
                                , payCardID.Value
                                , Request.Form["identityNumber"]
                                );
                            break;
                        }
                    case VendorID.LocalBank:
                        {
                            InternalPrepareLocalBankTransactionAsync(paymentMethodName
                                , gammingAccountID
                                , currency
                                , amount
                                , payCardID);
                            break;
                        }
                    case VendorID.UiPas:
                        {
                            InternalPrepareUiPasTransactionAsync(paymentMethodName
                                , gammingAccountID
                                , currency
                                , amount
                                , payCardID.Value
                                , Request.Form["identityNumber"]
                                );
                            break;
                        }
                    case VendorID.Trustly:
                        {
                            if (!payCardID.HasValue || payCardID <= 0)
                            {
                                var payCard = GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.Trustly)
                                              .FirstOrDefault(e => e.IsDummy);
                                if (payCard == null)
                                    throw new Exception("Trustly is not configrured in GmCore correctly, missing dummy pay card.");
                                payCardID = payCard.ID;
                            }
                            InternalPrepareTrustlyTransactionAsync(paymentMethodName
                                , gammingAccountID
                                , currency
                                , amount
                                , payCardID.Value
                                );
                            break;
                        }
                    case VendorID.IPG:
                        {
                            if (!payCardID.HasValue || payCardID <= 0)
                            {
                                var payCard = GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.IPG)
                                              .FirstOrDefault(e => e.IsDummy);
                                if (payCard == null)
                                    throw new Exception("IPG is not configrured in GmCore correctly, missing dummy pay card.");
                                payCardID = payCard.ID;
                            }
                            InternalPrepareIPGTransactionAsync(paymentMethodName
                                , gammingAccountID
                                , currency
                                , amount
                                , payCardID.Value
                                );
                            break;
                        }
                    case VendorID.Nets:
                        {
                            if (!payCardID.HasValue || payCardID <= 0)
                            {
                                var payCard = GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.Nets)
                                              .FirstOrDefault(e => e.IsDummy);
                                if (payCard == null)
                                    throw new Exception("Nets is not configrured in GmCore correctly, missing dummy pay card.");
                                payCardID = payCard.ID;
                            }
                            InternalPrepareNetsTransactionAsync(paymentMethodName
                                , gammingAccountID
                                , currency
                                , amount
                                , payCardID.Value
                                );
                            break;
                        }
                    case VendorID.APX:
                        {
                            InternalPrepareAPXBankTransactionAsync(paymentMethodName
                                , gammingAccountID
                                , currency
                                , amount
                                , payCardID.Value
                                , Request["bankName"]
                                , Request["branchAddress"]
                                , Request["iban"]
                                , Request["swift"]
                                , Request["tcNumber"]
                                );
                            break;
                        }
                    case VendorID.ArtemisBank:
                        {
                            InternalPrepareArtemisBankTransactionAsync(
                                paymentMethodName
                                , gammingAccountID
                                , currency
                                , amount
                                , payCardID.Value
                                , Request["bankName"]
                                , Request["branchCode"]
                                , Request["accountNumber"]
                                , Request["tcNumber"]
                                , Request["iban"]);
                            break;
                        }
                    case VendorID.MoneyMatrix:
                        {
                            if (!payCardID.HasValue || payCardID <= 0)
                            {
                                if (paymentMethod.SubCode != "CreditCard")
                                {
                                    var payCard = GamMatrixClient.GetPayCards(VendorID.MoneyMatrix)
                                        .Where(p => p.IsDummy)
                                        .FirstOrDefault();

                                    if (payCard == null)
                                        throw new Exception(
                                            "MoneyMatrix is not configrured in GmCore correctly, missing dummy pay card.");

                                    payCardID = payCard.ID;
                                }
                                else
                                {
                                    throw new ArgumentNullException("payCardID");
                                }
                            }
                            
                            this.InternalPrepareMoneyMatrixTransactionAsync(
                                paymentMethodName
                                , gammingAccountID
                                , currency
                                , amount
                                , payCardID.Value);
                            break;
                        }
                    case VendorID.EcoCard:
                        {
                            if (Settings.Withdraw_SkipPaymentMethodCheck && payCardID == 0)
                                payCardID = RegisterPayCard(VendorID.EcoCard, Request.Form["identityNumber"]);
                            base.InternalPrepareTransactionAsync(
                                paymentMethodName
                                , gammingAccountID
                                , currency
                                , amount
                                , payCardID.Value
                                , null
                                , true);
                            break;
                        }
                    default:
                        throw new NotImplementedException();
                }
            }
            catch (Exception ex)
            {
                AsyncManager.Parameters["exception"] = ex;
            }
        }

        public ActionResult MobilePrepareTransactionCompleted(PrepareTransRequest prepareTransRequest
            , Exception exception
            , string paymentMethodName
            , long gammingAccountID
            , string pid
           , JsonResult iovationResult = null
            )
        {
            if (iovationResult != null)
                return iovationResult;

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

                    string url = this.Url.Action("Confirmation", new { paymentMethodName = paymentMethodName, sid = prepareTransRequest.Record.Sid });
                    return this.Redirect(url);
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

        private void DeactivatePayCards(VendorID vendorID)
        {
            var payCards = GamMatrixClient.GetPayCards(vendorID)
                    .Where(p => !p.IsDummy)
                    .OrderByDescending(p => p.Ins)
                    .ToArray();

            if (payCards.Any())
            {
                var translations = GamMatrixClient.GetTransactions(new[] { TransType.Withdraw }, new[] { TransStatus.Pending }, vendorID);
                if (translations.Any())
                {
                    var translationPayCard = payCards.FirstOrDefault(p => p.ID == translations.FirstOrDefault().CreditPayCardID);
                    if (translationPayCard == null)
                        translationPayCard = payCards.FirstOrDefault();
                    throw new InvalidOperationException(string.Format("You have pending withdrawals linked to existing {0} TLNakit account hence you cannot request withdraw to another account for the moment. Please try again once all pending withdrawals have been processed.", translationPayCard.DisplayName));
                }

                var payCardIDs = payCards.Select(p => p.ID).ToArray();
                foreach (var payCardID in payCardIDs)
                    GamMatrixClient.UpdatePayCardStatus(payCardID, ActiveStatus.InActive);
            }
        }

        private long RegisterPayCard(VendorID vendorID, string identityNumber, string bankName = null)
        {
            PayCardRec payCard = new PayCardRec();
            payCard.VendorID = vendorID;
            payCard.ActiveStatus = ActiveStatus.Active;
            payCard.UserID = CustomProfile.Current.UserID;
            payCard.IdentityNumber = identityNumber;
            payCard.DisplayName = identityNumber;
            payCard.DisplayNumber = identityNumber;
            if (!string.IsNullOrWhiteSpace(bankName))
                payCard.BankName = bankName;

            return GamMatrixClient.RegisterPayCard(payCard);
        }

        private void InternalPrepareLocalBankTransactionAsync(
                string paymentMethodName
                , long gammingAccountID
                , string currency
                , string amount
                , long? payCardID)
        {

            long payCardIDValue;
            if (payCardID.HasValue && payCardID.Value != 0)
            {
                payCardIDValue = payCardID.Value;
            }
            else
            {
                payCardIDValue = RegisterLocalBankPayCard(
                    Request.Form["bankName"]
                    , Request.Form["nameOnAccount"]
                    , Request.Form["bankAccountNo"]);
            }

            base.InternalPrepareTransactionAsync(paymentMethodName
                , gammingAccountID
                , currency
                , amount
                , payCardIDValue
                , null
                , true
                );
        }

        private long RegisterLocalBankPayCard(
            string bankName
            , string nameOnAccount
            , string bankAccountNo)
        {
            if (string.IsNullOrWhiteSpace(bankName)
                || string.IsNullOrWhiteSpace(nameOnAccount)
                || string.IsNullOrWhiteSpace(bankAccountNo))
                throw new ArgumentException();

            if (!CustomProfile.Current.IsAuthenticated)
                throw new UnauthorizedAccessException();

            if (CustomProfile.Current.UserCountryID != 223 && CustomProfile.Current.UserCountryID != 202)
                throw new ArgumentException("your country did not allowed the bank.");

            string displayNumber = "";
            string identityNumber = "";
            if (CustomProfile.Current.UserCountryID == 202) // Korea
            {
                displayNumber = bankAccountNo;
                identityNumber = bankAccountNo;
            }

            List<PayCardInfoRec> payCards = GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.LocalBank);
            if (payCards.Exists(p => p.OwnerName.Equals(nameOnAccount, StringComparison.InvariantCultureIgnoreCase)
                && p.BankName.Equals(bankName, StringComparison.InvariantCultureIgnoreCase)
                && (p.BankAccountNo.Equals(bankAccountNo, StringComparison.InvariantCultureIgnoreCase))))
            {
                //return this.Json(new { @success = false, @error = "Multi card with same details is not allowed" });
                throw new ArgumentException("Multi card with same details is not allowed");
            }

            PayCardRec payCard = new PayCardRec();
            payCard.VendorID = VendorID.LocalBank;
            payCard.ActiveStatus = ActiveStatus.Active;
            payCard.UserID = CustomProfile.Current.UserID;
            payCard.BankAccountNo = bankAccountNo;
            payCard.IdentityNumber = identityNumber;
            payCard.DisplayNumber = displayNumber;
            payCard.DisplayName = displayNumber;
            payCard.OwnerName = nameOnAccount;
            payCard.BankName = bankName;
            payCard.BankCountryID = CustomProfile.Current.UserCountryID;

            long newPayCardID = GamMatrixClient.RegisterPayCard(payCard);

            return newPayCardID;
        }

        private void InternalPrepareTLNakitTransactionAsync(string paymentMethodName
            , long gammingAccountID
            , string currency
            , string amount
            , long payCardID // 0 if register new card
            , string identityNumber
            )
        {
            if (payCardID == 0)
            {
                DeactivatePayCards(VendorID.TLNakit);
                payCardID = RegisterPayCard(VendorID.TLNakit, identityNumber);
            }

            base.InternalPrepareTransactionAsync(paymentMethodName
                , gammingAccountID
                , currency
                , amount
                , payCardID
                , null
                , true
                );
        }

        private void InternalPrepareMoneybookersTransactionAsync(string paymentMethodName
            , long gammingAccountID
            , string currency
            , string amount
            , long payCardID // 0 if register new card
            , string identityNumber
            )
        {
            if (payCardID == 0)
                payCardID = RegisterPayCard(VendorID.Moneybookers, identityNumber);

            base.InternalPrepareTransactionAsync(paymentMethodName
                , gammingAccountID
                , currency
                , amount
                , payCardID
                , null
                , true
                );
        }

        private void InternalPrepareNetellerTransactionAsync(string paymentMethodName
            , long gammingAccountID
            , string currency
            , string amount
            , long payCardID // 0 if register new card
            , string identityNumber)
        {
            if (payCardID == 0)
                payCardID = RegisterPayCard(VendorID.Neteller, identityNumber);

            base.InternalPrepareTransactionAsync(paymentMethodName
                , gammingAccountID
                , currency
                , amount
                , payCardID
                , null
                , true
                );
        }

        private void InternalPrepareUiPasTransactionAsync(string paymentMethodName
            , long gammingAccountID
            , string currency
            , string amount
            , long payCardID // 0 if register new card
            , string identityNumber)
        {
            if (payCardID == 0)
                payCardID = RegisterPayCard(VendorID.UiPas, identityNumber);

            base.InternalPrepareTransactionAsync(paymentMethodName
                , gammingAccountID
                , currency
                , amount
                , payCardID
                , null
                , true
                );
        }

        private void InternalPrepareTrustlyTransactionAsync(string paymentMethodName
            , long gammingAccountID
            , string currency
            , string amount
            , long payCardID
            )
        {
            base.InternalPrepareTransactionAsync(paymentMethodName
                , gammingAccountID
                , currency
                , amount
                , payCardID
                , null
                , true
                );
        }

        private void InternalPrepareNetsTransactionAsync(string paymentMethodName
            , long gammingAccountID
            , string currency
            , string amount
            , long payCardID
            )
        {
            base.InternalPrepareTransactionAsync(paymentMethodName
                , gammingAccountID
                , currency
                , amount
                , payCardID
                , null
                , true
                );
        }

        private void InternalPrepareIPGTransactionAsync(string paymentMethodName
            , long gammingAccountID
            , string currency
            , string amount
            , long payCardID
            )
        {
            base.InternalPrepareTransactionAsync(paymentMethodName
                , gammingAccountID
                , currency
                , amount
                , payCardID
                , null
                , true
                );
        }

        #region InternalPrepareBankTransactionAsync
        private void InternalPrepareBankTransactionAsync(string paymentMethodName
            , long gammingAccountID
            , string currency
            , string amount
            , long payCardID // 0 if register new card
            , VendorID vendorID
            , int countryID
            , string bankName
            , string bankCode
            , string branchAddress
            , string branchCode
            , string payee
            , string payeeAddress
            , string accountNumber
            , string iban
            , string swift
            , string checkDigits
            , string additionalInformation
            , string bankCurrency
            )
        {
            if (payCardID == 0)
            {
                try
                {
                    PayCardRec payCard = new PayCardRec();
                    payCard.VendorID = vendorID;
                    payCard.BankCountryID = countryID;
                    payCard.BankName = bankName;
                    payCard.BankAddress = branchAddress;
                    payCard.BankCode = bankCode;
                    payCard.BankBranchCode = branchCode;
                    payCard.OwnerName = payee;
                    payCard.BankBeneficiaryAddress = payeeAddress;
                    payCard.BankBeneficiaryName = payee;
                    payCard.BankAccountNo = accountNumber.DefaultIfNullOrEmpty("").ToUpperInvariant();
                    payCard.BankIBAN = iban.DefaultIfNullOrEmpty("").ToUpperInvariant();
                    payCard.BankSWIFT = swift.DefaultIfNullOrEmpty("").ToUpperInvariant();
                    payCard.BankCheckDigits = checkDigits;
                    payCard.BankAdditionalInfo = additionalInformation;
                    payCard.IdentityNumber = payCard.BankIBAN.DefaultIfNullOrEmpty(payCard.BankAccountNo);

                    if (!string.IsNullOrWhiteSpace(bankCurrency))
                        payCard.Currency = bankCurrency;

                    if (payCard.BankIBAN.Length <= 2)
                        payCard.BankIBAN = "";

                    Dictionary<string, string> requestDynamicFields = null;
                    PrepareEnterCashPayCard(payCard, ref requestDynamicFields);
                    payCardID = GamMatrixClient.RegisterPayCard(payCard, requestDynamicFields);
                }
                catch (GmException ex)
                {
                    // SYS_1021 - Duplicated payCardID
                    // find the previous card
                    if (ex.ReplyResponse.ErrorCode == "SYS_1021")
                    {
                        Match m = Regex.Match(ex.ReplyResponse.ErrorSysMessage, @"(\d{6,})", RegexOptions.ECMAScript);
                        if (m.Success)
                            payCardID = long.Parse(m.Value, CultureInfo.InvariantCulture);
                    }
                    else
                        throw;
                }
            }

            base.InternalPrepareTransactionAsync(paymentMethodName
                , gammingAccountID
                , currency
                , amount
                , payCardID
                , null
                , true
                );
        }
        #endregion

        #region InternalPrepareAPXBankTransactionAsync
        private void InternalPrepareAPXBankTransactionAsync(string paymentMethodName
            , long gammingAccountID
            , string currency
            , string amount
            , long payCardID // 0 if register new card
            , string bankName
            , string branchAddress
            , string iban
            , string swift
            , string additionalInformation
            )
        {
            if (payCardID == 0)
            {
                try
                {
                    PayCardRec payCard = new PayCardRec();
                    payCard.VendorID = VendorID.APX;
                    payCard.BankName = bankName;
                    payCard.BankAddress = branchAddress;
                    payCard.BankIBAN = iban.DefaultIfNullOrEmpty("").ToUpperInvariant();
                    payCard.BankSWIFT = swift.DefaultIfNullOrEmpty("").ToUpperInvariant();
                    payCard.BankAdditionalInfo = additionalInformation;
                    payCard.IdentityNumber = payCard.BankIBAN.DefaultIfNullOrEmpty(payCard.BankAccountNo);

                    if (payCard.BankIBAN.Length <= 2)
                        payCard.BankIBAN = "";

                    payCardID = GamMatrixClient.RegisterPayCard(payCard);
                }
                catch (GmException ex)
                {
                    // SYS_1021 - Duplicated payCardID
                    // find the previous card
                    if (ex.ReplyResponse.ErrorCode == "SYS_1021")
                    {
                        Match m = Regex.Match(ex.ReplyResponse.ErrorSysMessage, @"(\d{6,})", RegexOptions.ECMAScript);
                        if (m.Success)
                            payCardID = long.Parse(m.Value, CultureInfo.InvariantCulture);
                    }
                    else
                        throw;
                }
            }

            base.InternalPrepareTransactionAsync(paymentMethodName
                , gammingAccountID
                , currency
                , amount
                , payCardID
                , null
                , true
                );
        }
        #endregion

        #region InternalPrepareArtemisBankTransactionAsync
        private void InternalPrepareArtemisBankTransactionAsync(string paymentMethodName
           , long gammingAccountID
           , string currency
           , string amount
           , long payCardID // 0 if register new card
           , string bankName
           , string branchCode
           , string accountNumber
           , string tcNumber
           , string iban
           )
        {
            if (payCardID == 0)
            {
                PayCardRec payCard = new PayCardRec();
                payCard.VendorID = VendorID.ArtemisBank;
                payCard.BankName = bankName;
                payCard.BankBranchCode = branchCode;
                payCard.BankAccountNo = accountNumber;
                payCard.BankIBAN = iban.DefaultIfNullOrEmpty("").ToUpper();
                payCard.BankAdditionalInfo = tcNumber;
                payCard.IdentityNumber = payCard.BankIBAN.DefaultIfNullOrEmpty(payCard.BankAccountNo);

                payCardID = GamMatrixClient.RegisterPayCard(payCard);
            }

            base.InternalPrepareTransactionAsync(paymentMethodName
                , gammingAccountID
                , currency
                , amount
                , payCardID
                , null
                , true
                );
        }
        #endregion

        #region InternalPrepareMoneyMatrixTransactionAsync
        private void InternalPrepareMoneyMatrixTransactionAsync(
            string paymentMethodName
           , long gammingAccountID
           , string currency
           , string amount
           , long payCardID
           )
        {
            switch (paymentMethodName)
            {
                case "MoneyMatrix_IBanq":
                    AsyncManager.Parameters["BanqUserId"] = Request.Form["BanqUserId"];
                    break;
                case "MoneyMatrix_Skrill":
                    AsyncManager.Parameters["SkrillEmailAddress"] = Request.Form["SkrillEmailAddress"];
                    break;
                case "MoneyMatrix_EcoPayz":
                    AsyncManager.Parameters["EcoPayzCustomerAccountId"] = Request.Form["EcoPayzCustomerAccountId"];
                    break;
                case "MoneyMatrix_EnterPays_BankTransfer":
                    AsyncManager.Parameters["Iban"] = Request.Form["Iban"];
                    AsyncManager.Parameters["BankSwiftCode"] = Request.Form["BankSwiftCode"];
                    AsyncManager.Parameters["BankSortCode"] = Request.Form["BankSortCode"];
                    break;
                case "MoneyMatrix_TLNakit":
                    AsyncManager.Parameters["TlNakitAccountId"] = Request.Form["TlNakitAccountId"];
                    break;
                case "MoneyMatrix_Adyen_SEPA":
                    AsyncManager.Parameters["Iban"] = Request.Form["Iban"];
                    break;
                case "MoneyMatrix_PaySafeCard":
                    AsyncManager.Parameters["PaySafeCardAccountId"] = Request.Form["PaySafeCardAccountId"];
                    break;
                case "MoneyMatrix_Neteller":
                    AsyncManager.Parameters["NetellerEmailAddressOrAccountId"] = Request.Form["NetellerEmailAddressOrAccountId"];
                    break;
                case "MoneyMatrix_PPro_Qiwi":
                    AsyncManager.Parameters["PProQiwiMobilePhone"] = Request.Form["PProQiwiMobilePhone"];
                    break;
                case "MoneyMatrix_PPro_Sepa":
                    AsyncManager.Parameters["Iban"] = Request.Form["Iban"];
                    break;
                case "MoneyMatrix_UPayCard":
                    AsyncManager.Parameters["UPayCardReceiverAccount"] = Request.Form["UPayCardReceiverAccount"];
                    break;
                case "MoneyMatrix_Offline_Nordea":
                case "MoneyMatrix_Offline_LocalBank":
                    var paymentMethodDetails = GamMatrixClient.GetPaymentSolutionDetails(paymentMethodName.ToMoneyMatrixPaymentMethodName());
                    foreach (var field in paymentMethodDetails.Metadata.Fields.Where(f => f.ForWithdraw && f.RequiresUserInput))
                    {
                        AsyncManager.Parameters[field.Key] = Request.Form[field.Key];
                    }
                    break;
                case "MoneyMatrix_InPay":
                    var country = CountryManager.GetAllCountries().FirstOrDefault(c => c.InternalID == CustomProfile.Current.UserCountryID).ISO_3166_Alpha2Code;
                    var inPayPaymentMethodDetails = GamMatrixClient.GetPaymentSolutionDetails(paymentMethodName.ToMoneyMatrixPaymentMethodName(), country, TransType.Withdraw);
                    foreach (var field in inPayPaymentMethodDetails.Metadata.Fields.Where(f => f.ForWithdraw))
                    {
                        AsyncManager.Parameters[field.Key] = Request.Form[field.Key];
                    }
                    break;
                case "MoneyMatrix":
                case "MoneyMatrix_PayKasa":
                case "MoneyMatrix_Trustly":
                case "MoneyMatrix_Visa":
                case "MoneyMatrix_MasterCard":
                case "MoneyMatrix_Dankort":
                    break;
                case "MoneyMatrix_Paysera_Wallet":
                    AsyncManager.Parameters["PaymentParameterBeneficiaryName"] = Request.Form["PaymentParameterBeneficiaryName"];
                    AsyncManager.Parameters["PaymentParameterPayseraAccount"] = Request.Form["PaymentParameterPayseraAccount"];
                    break;
                case "MoneyMatrix_Paysera_BankTransfer":
                    AsyncManager.Parameters["PaymentParameterBeneficiaryName"] = Request.Form["PaymentParameterBeneficiaryName"];
                    AsyncManager.Parameters["PaymentParameterIban"] = Request.Form["PaymentParameterIban"];
                    break;
                default:
                    throw new NotImplementedException();
            }

            base.InternalPrepareTransactionAsync(paymentMethodName
                , gammingAccountID
                , currency
                , amount
                , payCardID
                , null
                , true
                );
        }
        #endregion

        #region Check payment method
        private new bool CheckPaymentMethod(PaymentMethod paymentMethod)
        {
            if (Settings.Withdraw_SkipPaymentMethodCheck)
                return true;

            List<PaymentMethod> allPaymentMethods = PaymentMethodManager.GetPaymentMethods().Where(p => p.SupportWithdraw
            && GmCore.DomainConfigAgent.IsWithdrawEnabled(p)
            && p.WithdrawSupportedCountries.Exists(CustomProfile.Current.UserCountryID)
            ).ToList();
            List<PayCardInfoRec> payCards = GamMatrixClient.GetPayCards();

            List<string> paymentMethodNames = new List<string>();

            if (payCards.Exists(p => p.IsBelongsToPaymentMethod("PT_VISA") && IsCreditCardWithdrawable(p)))
                paymentMethodNames.Add("PT_VISA");
            if (payCards.Exists(p => p.IsBelongsToPaymentMethod("PT_VISA_Debit") && IsCreditCardWithdrawable(p)))
                paymentMethodNames.Add("PT_VISA_Debit");
            if (payCards.Exists(p => p.IsBelongsToPaymentMethod("PT_VISA_Electron") && IsCreditCardWithdrawable(p)))
                paymentMethodNames.Add("PT_VISA_Electron");
            if (payCards.Exists(p => p.IsBelongsToPaymentMethod("PT_EntroPay") && IsCreditCardWithdrawable(p)))
                paymentMethodNames.Add("PT_EntroPay");
            if (payCards.Exists(p => p.IsBelongsToPaymentMethod("PT_MasterCard") && IsCreditCardWithdrawable(p)))
                paymentMethodNames.Add("PT_MasterCard");

            if (payCards.Exists(p => p.VendorID == VendorID.Moneybookers
                && p.SuccessDepositNumber > 0))
            {
                paymentMethodNames.Add("Moneybookers");
            }
            else if (CustomProfile.Current.IsInRole("Affiliate"))
            {
                paymentMethodNames.Add("Moneybookers");
            }

            // UKash
            if (IsUkashAllowed(payCards))
            {
                paymentMethodNames.Add("Ukash");
            }

            // EcoCard
            if (payCards.Exists(p => p.VendorID == VendorID.EcoCard && !p.IsDummy))
            {
                paymentMethodNames.Add("EcoCard");
            }

            if (payCards.Exists(p => p.VendorID == VendorID.Neteller &&
                p.SuccessDepositNumber > 0))
            {
                paymentMethodNames.Add("Neteller");
            }
            else if (CustomProfile.Current.IsInRole("Affiliate"))
            {
                paymentMethodNames.Add("Neteller");
            }

            bool isAvailable = allPaymentMethods.Exists(p =>
                string.Equals(p.UniqueName, "BankTransfer", StringComparison.InvariantCultureIgnoreCase)
                    // && p.IsAvailable
                && p.SupportedCountries.Exists(CustomProfile.Current.UserCountryID)
                );
            if (isAvailable)
                paymentMethodNames.Add("BankTransfer");

            // TLNakit
            if (payCards.Exists(p => p.VendorID == VendorID.TLNakit && p.IsDummy && p.SuccessDepositNumber > 0))
            {
                paymentMethodNames.Add("TLNakit");
            }

            // UIPAS
            if (payCards.Exists(p => p.VendorID == VendorID.UiPas &&
                p.SuccessDepositNumber > 0))
            {
                paymentMethodNames.Add("UIPAS");
            }
            else if (CustomProfile.Current.IsInRole("Affiliate"))
            {
                paymentMethodNames.Add("UIPAS");
            }

            isAvailable = allPaymentMethods.Exists(p =>
                    string.Equals(p.UniqueName, "APX_BankTransfer", StringComparison.InvariantCultureIgnoreCase)
                    && p.IsAvailable
                    && p.SupportedCountries.Exists(CustomProfile.Current.UserCountryID)
                    );

            if (!isAvailable)
            {
                // Bank
                isAvailable = allPaymentMethods.Exists(p =>
                    string.Equals(p.UniqueName, "ArtemisBank", StringComparison.InvariantCultureIgnoreCase)
                    && p.IsAvailable
                    );
                if (isAvailable)
                    paymentMethodNames.Add("ArtemisBank");


                isAvailable = allPaymentMethods.Exists(p =>
                    string.Equals(p.UniqueName, "TurkeyBank", StringComparison.InvariantCultureIgnoreCase)
                    && p.IsAvailable
                    && p.SupportedCountries.Exists(CustomProfile.Current.UserCountryID)
                    );
                if (isAvailable)
                    paymentMethodNames.Add("TurkeyBank");
            }
            else
            {
                paymentMethodNames.Add("APX_BankTransfer");
            }
            // Local Bank CMS-2208
            paymentMethodNames.Add("LocalBank");

            //Trustly
            isAvailable = allPaymentMethods.Exists(p =>
                   string.Equals(p.UniqueName, "Trustly", StringComparison.InvariantCultureIgnoreCase)
                   && p.IsAvailable
                   && p.SupportedCountries.Exists(CustomProfile.Current.UserCountryID)
                   );
            if (isAvailable)
                isAvailable = payCards.Exists(p => p.VendorID == VendorID.Trustly && p.IsDummy);
            if (isAvailable)
                paymentMethodNames.Add("Trustly");

            //IPG
            isAvailable = allPaymentMethods.Exists(p =>
                string.Equals(p.UniqueName, "IPG", StringComparison.InvariantCultureIgnoreCase)
                && p.IsAvailable
                && p.SupportedCountries.Exists(CustomProfile.Current.UserCountryID)
                );
            if (isAvailable)
                isAvailable = payCards.Exists(p => p.VendorID == VendorID.IPG && p.SuccessDepositNumber > 0);
            if (isAvailable)
                paymentMethodNames.Add("IPG");

            //Nets
            isAvailable = allPaymentMethods.Exists(p =>
            string.Equals(p.UniqueName, "Nets", StringComparison.InvariantCultureIgnoreCase)
            && p.IsAvailable
            && p.SupportedCountries.Exists(CustomProfile.Current.UserCountryID));
            if (isAvailable)
            {
                UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                cmUser user = ua.GetByID(CustomProfile.Current.UserID);
                isAvailable = !String.IsNullOrEmpty(user.PersonalID);
                if (isAvailable)
                {
                    paymentMethodNames.Add("Nets");
                    paymentMethodNames.Remove("BankTransfer");
                }
            }

            isAvailable = allPaymentMethods.Exists(p =>
                string.Equals(p.UniqueName, "MoneyMatrix_IBanq", StringComparison.InvariantCultureIgnoreCase)
                && p.IsAvailable
                );
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_IBanq");


            /*for MoneyMatrix*/
            isAvailable = allPaymentMethods.Exists(p =>
              string.Equals(p.UniqueName, "MoneyMatrix", StringComparison.InvariantCultureIgnoreCase)
              && p.IsAvailable
              );
            if (isAvailable)
                isAvailable = payCards.Exists(p => p.VendorID == VendorID.MoneyMatrix && p.SuccessDepositNumber > 0);
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix");

            /*for MoneyMatrix_Visa*/
            isAvailable = allPaymentMethods.Exists(p =>
              string.Equals(p.UniqueName, "MoneyMatrix_Visa", StringComparison.InvariantCultureIgnoreCase)
              && p.IsAvailable
              );
            if (isAvailable)
                isAvailable = payCards.Exists(p => p.VendorID == VendorID.MoneyMatrix && p.CardName.Equals("visa", StringComparison.InvariantCultureIgnoreCase) && p.SuccessDepositNumber > 0);
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_Visa");

            /*for MoneyMatrix_MasterCard*/
            isAvailable = allPaymentMethods.Exists(p =>
              string.Equals(p.UniqueName, "MoneyMatrix_MasterCard", StringComparison.InvariantCultureIgnoreCase)
              && p.IsAvailable
              );
            if (isAvailable)
                isAvailable = payCards.Exists(p => p.VendorID == VendorID.MoneyMatrix && p.CardName.Equals("mastercard", StringComparison.InvariantCultureIgnoreCase) && p.SuccessDepositNumber > 0);
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_MasterCard");

            /*for MoneyMatrix_Dankort*/
            isAvailable = allPaymentMethods.Exists(p =>
              string.Equals(p.UniqueName, "MoneyMatrix_Dankort", StringComparison.InvariantCultureIgnoreCase)
              && p.IsAvailable
              );
            if (isAvailable)
                isAvailable = payCards.Exists(p => p.VendorID == VendorID.MoneyMatrix && (p.DisplayName.StartsWith("5019") || p.DisplayName.StartsWith("4571")) && p.SuccessDepositNumber > 0);
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_Dankort");

            /*MoneyMatrix_PayKasa*/
            isAvailable = allPaymentMethods.Exists(p =>
               string.Equals(p.UniqueName, "MoneyMatrix_PayKasa", StringComparison.InvariantCultureIgnoreCase)
               && p.IsAvailable
               );
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_PayKasa");

            /*MoneyMatrix_Offline_Nordea*/
            isAvailable = allPaymentMethods.Exists(p =>
               string.Equals(p.UniqueName, "MoneyMatrix_Offline_Nordea", StringComparison.InvariantCultureIgnoreCase)
               && p.IsAvailable
               );
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_Offline_Nordea");

            /*MoneyMatrix_Offline_LocalBank*/
            isAvailable = allPaymentMethods.Exists(p =>
               string.Equals(p.UniqueName, "MoneyMatrix_Offline_LocalBank", StringComparison.InvariantCultureIgnoreCase)
               && p.IsAvailable
               );
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_Offline_LocalBank");

            /*MoneyMatrix_Skrill*/
            isAvailable = allPaymentMethods.Exists(p =>
               string.Equals(p.UniqueName, "MoneyMatrix_Skrill", StringComparison.InvariantCultureIgnoreCase)
               && p.IsAvailable
               );
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_Skrill");

            /*MoneyMatrix_Skrill_1Tap*/
            isAvailable = allPaymentMethods.Exists(p =>
               string.Equals(p.UniqueName, "MoneyMatrix_Skrill_1Tap", StringComparison.InvariantCultureIgnoreCase)
               && p.IsAvailable
               );
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_Skrill_1Tap");

            /*MoneyMatrix_EcoPayz*/
            isAvailable = allPaymentMethods.Exists(p =>
               string.Equals(p.UniqueName, "MoneyMatrix_EcoPayz", StringComparison.InvariantCultureIgnoreCase)
               && p.IsAvailable
               );
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_EcoPayz");

            /*MoneyMatrix_EnterPays_BankTransfer*/
            isAvailable = allPaymentMethods.Exists(p =>
                string.Equals(p.UniqueName, "MoneyMatrix_EnterPays_BankTransfer", StringComparison.InvariantCultureIgnoreCase)
                && p.IsAvailable);
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_EnterPays_BankTransfer");

            /*MoneyMatrix_TLNakit*/
            isAvailable = allPaymentMethods.Exists(p =>
               string.Equals(p.UniqueName, "MoneyMatrix_TLNakit", StringComparison.InvariantCultureIgnoreCase)
               && p.IsAvailable
               );
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_TLNakit");

            /*MoneyMatrix_Trustly*/
            isAvailable = allPaymentMethods.Exists(p =>
               string.Equals(p.UniqueName, "MoneyMatrix_Trustly", StringComparison.InvariantCultureIgnoreCase)
               && p.IsAvailable);
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_Trustly");

            /*MoneyMatrix_PaySafeCard*/
            isAvailable = allPaymentMethods.Exists(p =>
               string.Equals(p.UniqueName, "MoneyMatrix_PaySafeCard", StringComparison.InvariantCultureIgnoreCase)
               && p.IsAvailable
               );
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_PaySafeCard");

            /*MoneyMatrix_Neteller*/
            isAvailable = allPaymentMethods.Exists(p =>
               string.Equals(p.UniqueName, "MoneyMatrix_Neteller", StringComparison.InvariantCultureIgnoreCase)
               && p.IsAvailable
               );
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_Neteller");

            /*MoneyMatrix_PPro_Qiwi*/
            isAvailable = allPaymentMethods.Exists(p =>
                string.Equals(p.UniqueName, "MoneyMatrix_PPro_Qiwi", StringComparison.InvariantCultureIgnoreCase)
                && p.IsAvailable);
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_PPro_Qiwi");

            /*MoneyMatrix_PPro_Sepa*/
            isAvailable = allPaymentMethods.Exists(p =>
                string.Equals(p.UniqueName, "MoneyMatrix_PPro_Sepa", StringComparison.InvariantCultureIgnoreCase)
                && p.IsAvailable);
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_PPro_Sepa");

            /*MoneyMatrix_Adyen_SEPA*/
            isAvailable = allPaymentMethods.Exists(p =>
               string.Equals(p.UniqueName, "MoneyMatrix_Adyen_SEPA", StringComparison.InvariantCultureIgnoreCase)
               && p.IsAvailable
               );
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_Adyen_SEPA");

            /*MoneyMatrix_UPayCard*/
            isAvailable = allPaymentMethods.Exists(p =>
                string.Equals(p.UniqueName, "MoneyMatrix_UPayCard", StringComparison.InvariantCultureIgnoreCase)
                && p.IsAvailable);
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_UPayCard");

            /*MoneyMatrix_InPay*/
            isAvailable = allPaymentMethods.Exists(p =>
                string.Equals(p.UniqueName, "MoneyMatrix_InPay", StringComparison.InvariantCultureIgnoreCase)
                && p.IsAvailable);
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_InPay");

            /*MoneyMatrix_Paysera_Wallet*/
            isAvailable = allPaymentMethods.Exists(p =>
                string.Equals(p.UniqueName, "MoneyMatrix_Paysera_Wallet", StringComparison.InvariantCultureIgnoreCase)
                && p.IsAvailable);
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_Paysera_Wallet");

            /*MoneyMatrix_Paysera_BankTransfer*/
            isAvailable = allPaymentMethods.Exists(p =>
                string.Equals(p.UniqueName, "MoneyMatrix_Paysera_BankTransfer", StringComparison.InvariantCultureIgnoreCase)
                && p.IsAvailable);
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_Paysera_BankTransfer");

            var paymentMethods = paymentMethodNames.Select(n => allPaymentMethods.FirstOrDefault(p =>
                string.Equals(p.UniqueName, n, StringComparison.OrdinalIgnoreCase)))
                .Where(p => p != null && p.WithdrawSupportedCountries.Exists(CustomProfile.Current.UserCountryID))
                .ToArray();

            return paymentMethods.Contains(paymentMethod);
        }

        private bool IsCreditCardWithdrawable(PayCardInfoRec payCard)
        {
            if (payCard.SuccessDepositNumber <= 0)
                return false;

            if (string.IsNullOrWhiteSpace(payCard.IssuerCountryCode))
                return true;

            var countries = CountryManager.GetAllCountries();
            var country = countries.FirstOrDefault(c => string.Equals(c.ISO_3166_Alpha2Code, payCard.IssuerCountryCode, StringComparison.InvariantCultureIgnoreCase));
            if (country == null)
                return true;

            return !country.RestrictCreditCardWithdrawal;
        }

        private bool IsUkashAllowed(List<PayCardInfoRec> payCards)
        {
            if (string.Equals(SiteManager.Current.DistinctName, "ArtemisBet", StringComparison.InvariantCultureIgnoreCase))
                return false;

            if (payCards.Exists(p => p.VendorID == VendorID.Ukash && p.SuccessDepositNumber > 0))
                return true;

            if (CustomProfile.Current.IsInRole("Verified Identity", "Withdraw only"))
                return true;

            string[] countries = Settings.Ukash_AllowWithdrawalCCIssueCountries;
            if (countries != null && countries.Length > 0)
            {
                if (payCards.Exists(p => p.VendorID == VendorID.PaymentTrust && p.SuccessDepositNumber > 0 && countries.Contains(p.IssuerCountryCode, StringComparer.InvariantCultureIgnoreCase)))
                    return true;
            }

            return false;
        }
        #endregion
    }
}