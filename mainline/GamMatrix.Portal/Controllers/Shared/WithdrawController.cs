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

namespace GamMatrix.CMS.Controllers.Shared
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{paymentMethodName}/{sid}")]
    public class WithdrawController : AsyncControllerEx
    {
        private const string DISALLOWED_ROLE_NAME = "Staked Player";
        /// <summary>
        ///  The list view
        /// </summary>
        /// <returns></returns>
        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        public virtual ActionResult Index()
        {
            try
            {
                if (!CustomProfile.Current.IsAuthenticated)
                    return View("Anonymous");

                if (!CustomProfile.Current.IsEmailVerified)
                {
                    UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                    cmUser user = ua.GetByID(CustomProfile.Current.UserID);
                    if (!user.IsEmailVerified)
                        return View("EmailNotVerified");
                    else
                    {
                        CustomProfile.Current.IsEmailVerified = true;
                    }
                }
                if (CustomProfile.Current.IsInRole(DISALLOWED_ROLE_NAME))
                {
                    return View("AccessDenied");
                }

                this.ViewData["Currency"] = CustomProfile.Current.UserCurrency;

                return View("Index");
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return this.View("Error");
            }
        }

        // [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        public virtual ActionResult Prepare(string paymentMethodName)
        {
            try
            {
                if (!CustomProfile.Current.IsAuthenticated)
                    return View("Anonymous");

                if (!CustomProfile.Current.IsEmailVerified)
                {
                    UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                    cmUser user = ua.GetByID(CustomProfile.Current.UserID);
                    if (!user.IsEmailVerified)
                        return View("EmailNotVerified");
                    else
                        CustomProfile.Current.IsEmailVerified = true;
                }

                PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
                    .FirstOrDefault(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.InvariantCultureIgnoreCase));
                if (paymentMethod == null)
                    throw new ArgumentOutOfRangeException("paymentMethodName");

                //check the payment method
                if (!CheckPaymentMethod(paymentMethod))
                    return View("BankNotSupport");

                //if (paymentMethod.VendorID == VendorID.APX)
                //{
                //    if (!paymentMethod.SupportWithdraw)
                //        return Redirect(Url.RouteUrl("Withdraw", new { action = "Index" }));
                //}
                //else if (paymentMethod.VendorID == VendorID.ArtemisBank
                //    || paymentMethod.VendorID == VendorID.TurkeyBank)
                //{
                //    PaymentMethod apx = PaymentMethodManager.GetPaymentMethods()
                //    .FirstOrDefault(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.InvariantCultureIgnoreCase));
                //    if (apx != null && apx.SupportWithdraw && IsAPXAvailableFromGmCore())
                //        return Redirect(Url.RouteUrl("Withdraw", new { action = "Index" }));
                //}

                switch (paymentMethod.VendorID)
                {
                    case VendorID.PaymentTrust:
                        this.ViewData["PayCardView"] = "PaymentTrustPayCard";
                        return View("Prepare", paymentMethod);

                    case VendorID.Moneybookers:
                        this.ViewData["PayCardView"] = "MoneybookersPayCard";
                        return View("Prepare", paymentMethod);

                    case VendorID.Neteller:
                        this.ViewData["PayCardView"] = "NetellerPayCard";
                        return View("Prepare", paymentMethod);

                    case VendorID.Trustly:
                        this.ViewData["PayCardView"] = "TrustlyPayCard";
                        return View("Prepare", paymentMethod);

                    case VendorID.Envoy:
                        {
                            // Envoy One-Click Services
                            if (string.Equals(paymentMethodName, "Envoy_WebMoney", StringComparison.OrdinalIgnoreCase) ||
                                string.Equals(paymentMethodName, "Envoy_Moneta", StringComparison.OrdinalIgnoreCase) ||
                                string.Equals(paymentMethodName, "Envoy_InstaDebit", StringComparison.OrdinalIgnoreCase) ||
                                 string.Equals(paymentMethodName, "Envoy_SpeedCard", StringComparison.OrdinalIgnoreCase))
                            {
                                this.ViewData["PayCardView"] = "EnvoyOneClickServicePayCard";
                            }
                            return View("Prepare", paymentMethod);
                        }

                    case VendorID.Bank:
                        this.ViewData["PayCardView"] = "BankPayCard";
                        return View("Prepare", paymentMethod);

                    case VendorID.Intercash:
                        this.ViewData["PayCardView"] = "IntercashPayCard";
                        return View("Prepare", paymentMethod);

                    case VendorID.EcoCard:
                        this.ViewData["PayCardView"] = "EcoCardPayCard";
                        return View("Prepare", paymentMethod);

                    case VendorID.Ukash:
                        this.ViewData["PayCardView"] = "UkashPayCard";
                        return View("Prepare", paymentMethod);

                    case VendorID.ArtemisBank:
                        this.ViewData["PayCardView"] = "ArtemisBankPayCard";
                        return View("Prepare", paymentMethod);

                    case VendorID.TurkeyBank:
                        this.ViewData["PayCardView"] = "TurkeyBankPayCard";
                        return View("Prepare", paymentMethod);

                    case VendorID.TLNakit:
                        this.ViewData["PayCardView"] = "TLNakitPayCard";
                        return View("Prepare", paymentMethod);

                    case VendorID.GeorgianCard:
                        {
                            if (string.Equals(paymentMethod.UniqueName, "GeorgianCard_ATM", StringComparison.InvariantCultureIgnoreCase))
                                return View("GeorgianCardATM", paymentMethod);

                            this.ViewData["PayCardView"] = "GeorgianCardPayCard";
                            return View("Prepare", paymentMethod);
                        }

                    case VendorID.PayAnyWay:
                        {
                            this.ViewData["PayCardView"] = "PayAnyWayPayCard";
                            return View("Prepare", paymentMethod);
                        }

                    case VendorID.IPSToken:
                        {
                            this.ViewData["PayCardView"] = "IPSTokenPayCard";
                            return View("Prepare", paymentMethod);
                        }
                    case VendorID.EnterCash:
                        {
                            this.ViewData["PayCardView"] = "EnterCashPayCard";
                            return View("Prepare", paymentMethod);
                        }
                    case VendorID.LocalBank:
                        {
                            this.ViewData["PayCardView"] = "LocalBankPayCard";
                            return View("Prepare", paymentMethod);
                        }

                    case VendorID.UiPas:
                        this.ViewData["PayCardView"] = "UiPasPayCard";
                        return View("Prepare", paymentMethod);

                    case VendorID.IPG:
                        this.ViewData["PayCardView"] = "IPGPayCard";
                        return View("Prepare", paymentMethod);

                    case VendorID.APX:
                        this.ViewData["PayCardView"] = "APXPayCard";
                        return View("Prepare", paymentMethod);

                    case VendorID.MoneyMatrix:
                        if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix", StringComparison.InvariantCultureIgnoreCase))
                        {
                            this.ViewData["PayCardView"] = "MoneyMatrixPayCard";
                        }
                        else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Trustly", StringComparison.InvariantCultureIgnoreCase))
                        {
                            this.ViewData["PayCardView"] = "MoneyMatrix_TrustlyPayCard";
                        }
                        else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_PayKasa", StringComparison.InvariantCultureIgnoreCase))
                        {
                            this.ViewData["PayCardView"] = "MoneyMatrix_PayKasaPayCard";
                        }
                        else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_IBanq", StringComparison.InvariantCultureIgnoreCase))
                        {
                            this.ViewData["PayCardView"] = "MoneyMatrix_IBanqPayCard";
                        }
                        else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_GPaySafe_BankTransfer", StringComparison.InvariantCultureIgnoreCase))
                        {
                            this.ViewData["PayCardView"] = "MoneyMatrix_GPaySafe_BankTransferPayCard";
                        }
                        else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Offline_Nordea", StringComparison.InvariantCultureIgnoreCase))
                        {
                            this.ViewData["PayCardView"] = "MoneyMatrix_Offline_NordeaPayCard";
                        }
                        else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Offline_LocalBank", StringComparison.InvariantCultureIgnoreCase))
                        {
                            this.ViewData["PayCardView"] = "MoneyMatrix_Offline_LocalBankPayCard";
                        }
                        else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Skrill", StringComparison.InvariantCultureIgnoreCase))
                        {
                            this.ViewData["PayCardView"] = "MoneyMatrix_SkrillPayCard";
                        }
                        else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_EcoPayz", StringComparison.InvariantCultureIgnoreCase))
                        {
                            this.ViewData["PayCardView"] = "MoneyMatrix_EcoPayzPayCard";
                        }
                        else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_TLNakit", StringComparison.InvariantCultureIgnoreCase))
                        {
                            this.ViewData["PayCardView"] = "MoneyMatrix_TLNakitPayCard";
                        }
                        else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_PaySafeCard", StringComparison.InvariantCultureIgnoreCase))
                        {
                            this.ViewData["PayCardView"] = "MoneyMatrix_PaySafeCardPayCard";
                        }
                        else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Neteller", StringComparison.InvariantCultureIgnoreCase))
                        {
                            this.ViewData["PayCardView"] = "MoneyMatrix_NetellerPayCard";
                        }
                        else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Adyen_SEPA", StringComparison.InvariantCultureIgnoreCase))
                        {
                            this.ViewData["PayCardView"] = "MoneyMatrix_Adyen_SEPAPayCard";
                        }
                        else if (paymentMethod.UniqueName.StartsWith("MoneyMatrix_EnterPays", StringComparison.InvariantCultureIgnoreCase))
                        {
                            this.ViewData["PayCardView"] = string.Format("{0}PayCard", paymentMethod.UniqueName);
                        }
                        else if (paymentMethod.UniqueName.StartsWith("MoneyMatrix_PPro", StringComparison.InvariantCultureIgnoreCase))
                        {
                            this.ViewData["PayCardView"] = string.Format("{0}PayCard", paymentMethod.UniqueName);
                        }
                        else if (paymentMethod.UniqueName.StartsWith("MoneyMatrix_UPayCard", StringComparison.InvariantCultureIgnoreCase))
                        {
                            this.ViewData["PayCardView"] = string.Format("{0}PayCard", paymentMethod.UniqueName);
                        }
                        else if (paymentMethod.UniqueName.Equals("MoneyMatrix_Visa", StringComparison.InvariantCultureIgnoreCase))
                        {
                           this.ViewData["PayCardView"] = string.Format("{0}PayCard", paymentMethod.UniqueName);
                        }
                        else if (paymentMethod.UniqueName.Equals("MoneyMatrix_MasterCard", StringComparison.InvariantCultureIgnoreCase))
                        {
                            this.ViewData["PayCardView"] = string.Format("{0}PayCard", paymentMethod.UniqueName);
                        }
                        else if (paymentMethod.UniqueName.Equals("MoneyMatrix_Dankort", StringComparison.InvariantCultureIgnoreCase))
                        {
                            this.ViewData["PayCardView"] = string.Format("{0}PayCard", paymentMethod.UniqueName);
                        }
                        else if (paymentMethod.UniqueName.Equals("MoneyMatrix_InPay", StringComparison.InvariantCultureIgnoreCase))
                        {
                            this.ViewData["PayCardView"] = string.Format("{0}PayCard", paymentMethod.UniqueName);
                        }
                        else if (paymentMethod.UniqueName.Equals("MoneyMatrix_Paysera_Wallet", StringComparison.InvariantCultureIgnoreCase))
                        {
                            this.ViewData["PayCardView"] = string.Format("{0}PayCard", paymentMethod.UniqueName);
                        }
                        else if (paymentMethod.UniqueName.Equals("MoneyMatrix_Paysera_BankTransfer", StringComparison.InvariantCultureIgnoreCase))
                        {
                            this.ViewData["PayCardView"] = string.Format("{0}PayCard", paymentMethod.UniqueName);
                        }

                        return View("Prepare", paymentMethod);

                    case VendorID.Nets:
                        this.ViewData["PayCardView"] = "NetsPayCard";
                        return View("Prepare", paymentMethod);
                }

                throw new NotSupportedException();
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return this.View("Error");
            }
        }

        #region PrepareTransaction
        /// <summary>
        /// Prepare the transaction
        /// </summary>
        /// <param name="paymentMethodName"></param>
        /// <param name="gammingAccountID"></param>
        /// <param name="currency"></param>
        /// <param name="amount"></param>
        /// <param name="payCardID"></param>
        /// <returns></returns>
        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [OutputCache(Duration = 0, VaryByParam = "None")]

        public void PrepareTransactionAsync(string paymentMethodName
            , long gammingAccountID
            , string currency
            , string amount
            , long payCardID
            , string requestCreditCurrency
            , string iovationBlackbox = null
            )
        {
            string bankName = null;
            //// EnterCash
            //if (paymentMethodName.Equals("EnterCashBank"))
            //{
            //    bankName = GetEnterCashBankName(payCardID);
            //}

            var iovationResult = IovationCheck(iovationBlackbox);
            if (iovationResult != null)
            {
                AsyncManager.Parameters["iovationResult"] = iovationResult;
                return;
            }

            if (paymentMethodName == "MoneyMatrix_IBanq")
            {
                AsyncManager.Parameters["BanqUserId"] = Request.Form["BanqUserId"];
            }

            if (paymentMethodName == "MoneyMatrix_Skrill")
            {
                AsyncManager.Parameters["SkrillEmailAddress"] = Request.Form["SkrillEmailAddress"];
            }

            if (paymentMethodName == "MoneyMatrix_Skrill_1Tap")
            {
                AsyncManager.Parameters["SkrillEmailAddress"] = Request.Form["SkrillEmailAddress"];
            }

            if (paymentMethodName == "MoneyMatrix_EcoPayz")
            {
                AsyncManager.Parameters["EcoPayzCustomerAccountId"] = Request.Form["EcoPayzCustomerAccountId"];
            }

            if (paymentMethodName == "MoneyMatrix_TLNakit")
            {
                AsyncManager.Parameters["TlNakitAccountId"] = Request.Form["TlNakitAccountId"];
            }

            if (paymentMethodName == "MoneyMatrix_Adyen_SEPA")
            {
                AsyncManager.Parameters["Iban"] = Request.Form["Iban"];
            }

            if (paymentMethodName == "MoneyMatrix_PaySafeCard")
            {
                AsyncManager.Parameters["PaySafeCardAccountId"] = Request.Form["PaySafeCardAccountId"];
            }

            if (paymentMethodName == "MoneyMatrix_Neteller")
            {
                AsyncManager.Parameters["NetellerEmailAddressOrAccountId"] = Request.Form["NetellerEmailAddressOrAccountId"];
            }

            if (paymentMethodName == "MoneyMatrix_EnterPays_BankTransfer")
            {
                AsyncManager.Parameters["Iban"] = Request.Form["Iban"];
                AsyncManager.Parameters["BankSwiftCode"] = Request.Form["BankSwiftCode"];
                AsyncManager.Parameters["BankSortCode"] = Request.Form["BankSortCode"];
            }

            if (paymentMethodName == "MoneyMatrix_PPro_Qiwi")
            {
                AsyncManager.Parameters["PProQiwiMobilePhone"] = Request.Form["PProQiwiMobilePhone"];
            }

            if (paymentMethodName == "MoneyMatrix_PPro_Sepa")
            {
                AsyncManager.Parameters["Iban"] = Request.Form["Iban"];
            }

            if (paymentMethodName == "MoneyMatrix_UPayCard")
            {
                AsyncManager.Parameters["UPayCardReceiverAccount"] = Request.Form["UPayCardReceiverAccount"];
            }

            if (paymentMethodName == "MoneyMatrix_InPay")
            {
                var country = CountryManager.GetAllCountries().FirstOrDefault(c => c.InternalID == CustomProfile.Current.UserCountryID).ISO_3166_Alpha2Code;
                var paymentMethodDetails = GamMatrixClient.GetPaymentSolutionDetails(paymentMethodName.ToMoneyMatrixPaymentMethodName(), country, TransType.Withdraw);
                foreach (var field in paymentMethodDetails.Metadata.Fields.Where(f => f.ForWithdraw))
                {
                    AsyncManager.Parameters[field.Key] = Request.Form[field.Key];
                }
            }

            if (paymentMethodName.Equals("MoneyMatrix_Offline_Nordea") || paymentMethodName.Equals("MoneyMatrix_Offline_LocalBank"))
            {
                var paymentMethodDetails = GamMatrixClient.GetPaymentSolutionDetails(paymentMethodName.ToMoneyMatrixPaymentMethodName());
                foreach (var field in paymentMethodDetails.Metadata.Fields.Where(f => f.ForWithdraw && f.RequiresUserInput))
                {
                    AsyncManager.Parameters[field.Key] = Request.Form[field.Key];
                }
            }

            if (paymentMethodName == "MoneyMatrix_Paysera_Wallet")
            {
                AsyncManager.Parameters["PaymentParameterPayseraAccount"] = Request.Form["PaymentParameterPayseraAccount"];
                AsyncManager.Parameters["PaymentParameterBeneficiaryName"] = Request.Form["PaymentParameterBeneficiaryName"];
            }

            if (paymentMethodName == "MoneyMatrix_Paysera_BankTransfer")
            {
                AsyncManager.Parameters["PaymentParameterIban"] = Request.Form["PaymentParameterIban"];
                AsyncManager.Parameters["PaymentParameterBeneficiaryName"] = Request.Form["PaymentParameterBeneficiaryName"];
            }

            InternalPrepareTransactionAsync(paymentMethodName
                , gammingAccountID
                , currency
                , amount
                , payCardID
                , requestCreditCurrency
                , false
                , bankName
                , iovationBlackbox
                );
        }

        private string GetEnterCashBankName(long payCardID)
        {
            var payCard = GamMatrixClient.GetPayCards(VendorID.EnterCash).FirstOrDefault(p => !p.IsDummy && p.ID == payCardID);
            if (payCard == null && payCard.DisplaySpecificFields.Exists(f => f.Key.Equals("bankid", StringComparison.InvariantCultureIgnoreCase)))
                throw new ArgumentException("invalid pay card");

            List<EnterCashRequestBankInfo> list = GamMatrixClient.GetEnterCashBankInfo();

            long registeredBankID = 0;
            long.TryParse(payCard.DisplaySpecificFields.FirstOrDefault(f => f.Key.Equals("bankid", StringComparison.InvariantCultureIgnoreCase)).Value, out registeredBankID);
            EnterCashRequestBankInfo bankInfo = list.FirstOrDefault(b => b.Id == registeredBankID);
            if (bankInfo == null)
                throw new ArgumentException("invalid bank");

            return bankInfo.Name;
        }


        protected void InternalPrepareTransactionAsync(string paymentMethodName
            , long gammingAccountID
            , string currency
            , string amount
            , long payCardID
            , string requestCreditCurrency
            , bool isMobile
            , string bankName = null
            , string iovationBlackbox = null
            )
        {
            AsyncManager.Parameters["paymentMethodName"] = paymentMethodName;
            AsyncManager.Parameters["gammingAccountID"] = gammingAccountID;
            AsyncManager.Parameters["currency"] = currency;
            AsyncManager.Parameters["amount"] = amount;
            AsyncManager.Parameters["payCardID"] = payCardID;
            AsyncManager.Parameters["requestCreditCurrency"] = requestCreditCurrency;

            if (Settings.IovationDeviceTrack_Enabled && iovationBlackbox == null)
            {
                //get again.
                iovationBlackbox = Request.Form["iovationBlackBox"];
            }
            try
            {
                string pid = Guid.NewGuid().ToString("N");
                AsyncManager.Parameters["pid"] = pid;

                if (CustomProfile.Current.IsAuthenticated)
                {
                    if (!CustomProfile.Current.IsEmailVerified)
                    {
                        UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                        cmUser user = ua.GetByID(CustomProfile.Current.UserID);
                        if (!user.IsEmailVerified)
                            throw new Exception("Email not verified!");
                        else
                            CustomProfile.Current.IsEmailVerified = true;
                    }
                    decimal requestAmount = decimal.Parse(Regex.Replace(amount, @"[^\d\.]", string.Empty), CultureInfo.InvariantCulture);

                    PrepareTransRequest prepareTransRequest = new PrepareTransRequest()
                    {
                        Record = new PreTransRec()
                        {
                            Type = PreTransType.Pending,
                            TransType = TransType.Withdraw,
                            DebitAccountID = gammingAccountID,
                            CreditPayCardID = payCardID,
                            RequestAmount = requestAmount,
                            RequestCurrency = currency,
                            UserID = CustomProfile.Current.UserID,
                            UserIP = Request.GetRealUserAddress(),
                            RequestCreditCurrency = requestCreditCurrency,
                            IsMobile = isMobile,

                        },
                        IovationBlackBox = iovationBlackbox,
                        IsRequiredRedirectForm = true,
                        IsWindowOwner = false,
                        RedirectFormName = "withdrawForm",
                        RedirectFormTarget = "_self",
                        IsRequiredRedirectURL = false,
                        PostBackURL = this.Url.RouteUrlEx("Withdraw", new { @action = "Postback", @paymentMethodName = paymentMethodName, pid = pid }),
                        PostBackURLTarget = "_self",
                        CancelURL = this.Url.RouteUrlEx("Withdraw", new { @action = "Cancel", @paymentMethodName = paymentMethodName, pid = pid }),
                        CancelURLTarget = "_self",
                        ReturnURL = this.Url.RouteUrlEx("Withdraw", new { @action = "Return", @paymentMethodName = paymentMethodName, pid = pid }),
                        ReturnURLTarget = "_self",
                    };

                    var payCard = GamMatrixClient.GetPayCard(payCardID, false, true);

                    if (payCard.VendorID == VendorID.EnterCash)
                        prepareTransRequest.PaymentMethods = new List<string> { payCard.BankName };

                    if (payCard.VendorID == VendorID.MoneyMatrix)
                    {
                        var paymentMethod = string.Empty;
                        if (prepareTransRequest.RequestFields == null)
                        {
                            prepareTransRequest.RequestFields = new Dictionary<string, string>();
                        }

                        switch (paymentMethodName)
                        {
                            case "MoneyMatrix":
                                paymentMethod = "CreditCard";
                                break;
                            case "MoneyMatrix_Trustly":
                                paymentMethod = "Trustly";
                                break;
                            case "MoneyMatrix_PayKasa":
                                paymentMethod = "PayKasa";
                                break;
                            case "MoneyMatrix_IBanq":
                                prepareTransRequest.RequestFields["BanqUserId"] = AsyncManager.Parameters["BanqUserId"] as string;

                                paymentMethod = "i-Banq";
                                break;
                            case "MoneyMatrix_Skrill":
                                prepareTransRequest.RequestFields["SkrillEmailAddress"] = AsyncManager.Parameters["SkrillEmailAddress"] as string;
                                paymentMethod = "Skrill";
                                break;

                            case "MoneyMatrix_Skrill_1Tap":
                                prepareTransRequest.RequestFields["SkrillEmailAddress"] = AsyncManager.Parameters["SkrillEmailAddress"] as string;
                                paymentMethod = "Skrill";
                                break;

                            case "MoneyMatrix_EcoPayz":
                                prepareTransRequest.RequestFields["EcoPayzCustomerAccountId"] = AsyncManager.Parameters["EcoPayzCustomerAccountId"] as string;
                                paymentMethod = "EcoPayz";
                                break;
                            case "MoneyMatrix_TLNakit":
                                prepareTransRequest.RequestFields["TlNakitAccountId"] = AsyncManager.Parameters["TlNakitAccountId"] as string;
                                paymentMethod = "TlNakit";
                                break;
                            case "MoneyMatrix_PaySafeCard":
                                prepareTransRequest.RequestFields["PaySafeCardAccountId"] = AsyncManager.Parameters["PaySafeCardAccountId"] as string;
                                paymentMethod = "PaySafeCard";
                                break;
                            case "MoneyMatrix_Neteller":
                                prepareTransRequest.RequestFields["NetellerEmailAddressOrAccountId"] = AsyncManager.Parameters["NetellerEmailAddressOrAccountId"] as string;
                                paymentMethod = "Neteller";
                                break;
                            case "MoneyMatrix_Offline_Nordea":
                                paymentMethod = "Offline.Nordea";
                                var nordeaPaymentMethodDetails = GamMatrixClient.GetPaymentSolutionDetails(paymentMethod);
                                foreach (var field in nordeaPaymentMethodDetails.Metadata.Fields.Where(f => f.RequiresUserInput && f.ForWithdraw))
                                {
                                    prepareTransRequest.RequestFields[field.Key] = AsyncManager.Parameters[field.Key] as string;
                                }
                                break;
                            case "MoneyMatrix_Offline_LocalBank":
                                paymentMethod = "Offline.LocalBank";
                                var localBankPaymentMethodDetails = GamMatrixClient.GetPaymentSolutionDetails(paymentMethod);
                                foreach (var field in localBankPaymentMethodDetails.Metadata.Fields.Where(f => f.RequiresUserInput && f.ForWithdraw))
                                {
                                    prepareTransRequest.RequestFields[field.Key] = AsyncManager.Parameters[field.Key] as string;
                                }
                                break;
                            case "MoneyMatrix_Adyen_SEPA":
                                prepareTransRequest.RequestFields["Iban"] = AsyncManager.Parameters["Iban"] as string;
                                paymentMethod = "Adyen.SEPA";
                                break;
                            case "MoneyMatrix_EnterPays_BankTransfer":
                                prepareTransRequest.RequestFields["Iban"] = AsyncManager.Parameters["Iban"] as string;
                                prepareTransRequest.RequestFields["BankSwiftCode"] = AsyncManager.Parameters["BankSwiftCode"] as string;
                                prepareTransRequest.RequestFields["BankSortCode"] = AsyncManager.Parameters["BankSortCode"] as string;
                                paymentMethod = "EnterPays.BankTransfer";
                                break;
                            case "MoneyMatrix_PPro_Qiwi":
                                prepareTransRequest.RequestFields["PProQiwiMobilePhone"] = AsyncManager.Parameters["PProQiwiMobilePhone"] as string;
                                paymentMethod = "PPro.Qiwi";
                                break;
                            case "MoneyMatrix_PPro_Sepa":
                                prepareTransRequest.RequestFields["Iban"] = AsyncManager.Parameters["Iban"] as string;
                                paymentMethod = "PPro.Sepa";
                                break;
                            case "MoneyMatrix_UPayCard":
                                prepareTransRequest.RequestFields["UPayCardReceiverAccount"] = AsyncManager.Parameters["UPayCardReceiverAccount"] as string;
                                paymentMethod = "UPayCard";
                                break;
                            case "MoneyMatrix_InPay":
                                paymentMethod = "InPay";
                                var country = CountryManager.GetAllCountries().FirstOrDefault(c => c.InternalID == CustomProfile.Current.UserCountryID).ISO_3166_Alpha2Code;
                                var inPayPaymentMethodDetails = GamMatrixClient.GetPaymentSolutionDetails(paymentMethod, country, TransType.Withdraw);
                                foreach (var field in inPayPaymentMethodDetails.Metadata.Fields.Where(f => f.ForWithdraw))
                                {
                                    prepareTransRequest.RequestFields[field.Key] = AsyncManager.Parameters[field.Key] as string;
                                }
                                break;
                            case "MoneyMatrix_Visa":
                            case "MoneyMatrix_MasterCard":
                            case "MoneyMatrix_Dankort":
                                paymentMethod = "CreditCard";
                                break;
                            case "MoneyMatrix_Paysera_Wallet":
                                prepareTransRequest.RequestFields["PaymentParameterPayseraAccount"] = AsyncManager.Parameters["PaymentParameterPayseraAccount"] as string;
                                prepareTransRequest.RequestFields["PaymentParameterBeneficiaryName"] = AsyncManager.Parameters["PaymentParameterBeneficiaryName"] as string;
                                paymentMethod = "Paysera.Wallet";
                                break;
                            case "MoneyMatrix_Paysera_BankTransfer":
                                prepareTransRequest.RequestFields["PaymentParameterIban"] = AsyncManager.Parameters["PaymentParameterIban"] as string;
                                prepareTransRequest.RequestFields["PaymentParameterBeneficiaryName"] = AsyncManager.Parameters["PaymentParameterBeneficiaryName"] as string;
                                paymentMethod = "Paysera.BankTransfer";
                                break;

                        }

                        prepareTransRequest.PaymentMethods = new List<string> { paymentMethod };
                    }

                    GamMatrixClient.SingleRequestAsync<PrepareTransRequest>(prepareTransRequest
                            , OnPrepareTransactionCompleted
                            );
                    AsyncManager.OutstandingOperations.Increment();
                }
            }
            catch (Exception ex)
            {
                AsyncManager.Parameters["exception"] = ex;
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

        public JsonResult PrepareTransactionCompleted(PrepareTransRequest prepareTransRequest
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
                    cmTransParameter.SaveObject<string>(pid
                                , "Sid"
                                , prepareTransRequest.Record.Sid
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
                        var account = GamMatrixClient.GetUserGammingAccounts(CustomProfile.Current.UserID).FirstOrDefault(a => a.ID == gammingAccountID);
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
                var paymentMethod = PaymentMethodManager.GetPaymentMethods().FirstOrDefault(p => p.UniqueName == paymentMethodName);
                return this.Json(new
                {
                    @success = false,
                    @error = GmException.TryGetFriendlyErrorMsg(ex),
                });
            }
        }


        public JsonResult ProcessLocalBankTransaction(string paymentMethodName
            , long gammingAccountID
            , string currency
            , string amount
            , long payCardID
            , string requestCreditCurrency
            , string iovationBlackbox = null
            )
        {

            var iovResult = IovationCheck(iovationBlackbox);
            if (iovResult != null)
                return iovResult;

            if (!CustomProfile.Current.IsAuthenticated)
                throw new UnauthorizedAccessException();
            try
            {
                try
                {
                    decimal requestAmount = decimal.Parse(Regex.Replace(amount, @"[^\d\.]", string.Empty), CultureInfo.InvariantCulture);

                    LocalBankPaymentRequest request = new LocalBankPaymentRequest()
                    {
                        Payment = new LocalBankRec
                        {
                            TransType = TransType.Withdraw,
                            AccountID = gammingAccountID,
                            PaycardID = payCardID,
                            Amount = requestAmount,
                            Currency = currency,
                            UserID = CustomProfile.Current.UserID,
                            IsMobile = false,
                        }
                    };
                    using (GamMatrixClient client = new GamMatrixClient())
                    {
                        request = client.SingleRequest(request);
                    }

                    cmTransParameter.SaveObject<LocalBankPaymentRequest>(request.Payment.ID.ToString()
                            , "localBankPaymentRequest"
                            , request
                            );

                    return this.Json(new
                    {
                        @success = true,
                        @sid = request.Payment.PreTransID,
                        @url = this.Url.Action("LocalBankReceipt", new { @paymentMethodName = "LocalBank", @pid = request.Payment.ID })
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
                        var account = GamMatrixClient.GetUserGammingAccounts(CustomProfile.Current.UserID).FirstOrDefault(a => a.ID == gammingAccountID);
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
        #endregion


        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult Confirmation(string paymentMethodName, string sid)
        {
            PrepareTransRequest prepareTransRequest = cmTransParameter.ReadObject<PrepareTransRequest>(sid, "PrepareTransRequest");
            if (prepareTransRequest == null)
                throw new ArgumentOutOfRangeException("sid");

            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
                .First(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.OrdinalIgnoreCase));

            this.ViewData["paymentMethod"] = paymentMethod;
            return View("Confirmation", prepareTransRequest);
        }

        #region Confirm

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


        [CustomValidateAntiForgeryToken]
        public void ConfirmAsync(string paymentMethodName, string sid)
        {
            AsyncManager.Parameters["paymentMethodName"] = paymentMethodName;
            AsyncManager.Parameters["sid"] = sid;
            if (CustomProfile.Current.IsAuthenticated)
            {

                PrepareTransRequest prepareTransRequest = cmTransParameter.ReadObject<PrepareTransRequest>(sid, "PrepareTransRequest");
                if (prepareTransRequest == null)
                    throw new ArgumentOutOfRangeException("sid");
                AsyncManager.Parameters["prepareTransRequest"] = prepareTransRequest;


                if (prepareTransRequest.Record.Status == PreTransStatus.Setup)
                {
                    ProcessTransRequest processTransRequest = new ProcessTransRequest()
                    {
                        SID = sid
                    };

                    GamMatrixClient.SingleRequestAsync<ProcessTransRequest>(processTransRequest, OnProcessTransactionCompleted);
                    AsyncManager.OutstandingOperations.Increment();
                }
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

        public ActionResult ConfirmCompleted(PrepareTransRequest prepareTransRequest
            , ProcessTransRequest processTransRequest
            , string paymentMethodName
            , string sid
            , Exception exception
            )
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return View("Anonymous");

            try
            {
                if (exception != null)
                    throw exception;

                if (processTransRequest != null)
                {
                    cmTransParameter.SaveObject<ProcessTransRequest>(prepareTransRequest.Record.Sid
                                , "ProcessTransRequest"
                                , processTransRequest
                                );
                }

                if (prepareTransRequest.Record.Status == PreTransStatus.Setup)
                {
                    cmTransParameter.SaveObject<ProcessTransRequest>(prepareTransRequest.Record.Sid
                        , "ProcessTransRequest"
                        , processTransRequest
                        );

                    string url = this.Url.RouteUrl("Withdraw", new { @action = "Receipt", @paymentMethodName = paymentMethodName, @sid = sid });
                    return Redirect(url);
                }
                else if (prepareTransRequest.Record.Status == PreTransStatus.AsyncSent)
                {
                    this.ViewData["FormHtml"] = prepareTransRequest.RedirectForm;
                    return View("PaymentFormPost");
                }
                else
                    throw new NotImplementedException();
            }
            catch (Exception ex)
            {
                string friendlyError = GmException.TryGetFriendlyErrorMsg(ex);
                cmTransParameter.SaveObject<string>(sid, "LastError", friendlyError);
                this.ViewData["ErrorMessage"] = friendlyError;
                return View("Error");
            }
        }
        #endregion

        /// <summary>
        /// The receipt page
        /// </summary>
        /// <param name="paymentMethodName"></param>
        /// <param name="sid"></param>
        /// <returns></returns>
        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult Receipt(string paymentMethodName, string sid)
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return View("Anonymous");

            PrepareTransRequest prepareTransRequest = cmTransParameter.ReadObject<PrepareTransRequest>(sid, "PrepareTransRequest");
            if (prepareTransRequest == null)
                throw new ArgumentOutOfRangeException("sid");

            ProcessTransRequest processTransRequest = cmTransParameter.ReadObject<ProcessTransRequest>(sid, "ProcessTransRequest");

            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
                .First(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.OrdinalIgnoreCase));

            Logger.Information("Receipt", "In receipt Before call getTransInfoRequest");

            GetTransInfoRequest getTransInfoRequest;
            using (GamMatrixClient client = GamMatrixClient.Get())
            {
                getTransInfoRequest = client.SingleRequest<GetTransInfoRequest>(new GetTransInfoRequest()
                {
                    SID = sid,
                    NoDetails = true,
                });
            }

            Logger.Information("Receipt", "In receipt after call getTransInfoRequest");

            this.ViewData["paymentMethod"] = paymentMethod;
            this.ViewData["prepareTransRequest"] = prepareTransRequest;
            if (processTransRequest != null)
                this.ViewData["processTransRequest"] = processTransRequest;
            this.ViewData["getTransInfoRequest"] = getTransInfoRequest;

            PreTransStatus preTransStatus = getTransInfoRequest.TransData.Status;
            TransStatus transStatus = getTransInfoRequest.TransData.TransStatus;
            
            var lastError = cmTransParameter.ReadObject<string>(sid, "LastError");

            if (preTransStatus == PreTransStatus.Failed ||
                transStatus == TransStatus.Failed ||
                transStatus == TransStatus.DebitFailed ||
                transStatus == TransStatus.CreditFailed ||
                !string.IsNullOrEmpty(lastError))
            {
                Logger.Information("Receipt", "In receipt .preTransStatus={0} transStatus={1}", preTransStatus, transStatus);

                if (string.IsNullOrEmpty(lastError))
                {
                    var transLastErrorCode = getTransInfoRequest.TransData.GetLastErrorCode();

                    if (!string.IsNullOrEmpty(transLastErrorCode))
                    {
                        this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(transLastErrorCode);
                    }
                }
                else
                {
                    this.ViewData["ErrorMessage"] = lastError;
                }

                return View("Error");
            }

            return View("Receipt", paymentMethod);
        }

        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult LocalBankReceipt(string paymentMethodName, string pid)
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return View("Anonymous");

            LocalBankPaymentRequest localBankPaymentRequest = cmTransParameter.ReadObject<LocalBankPaymentRequest>(pid, "LocalBankPaymentRequest");

            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
                .First(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.OrdinalIgnoreCase));

            this.ViewData["paymentMethod"] = paymentMethod;
            this.ViewData["localBankPaymentRequest"] = localBankPaymentRequest;

            return View("LocalBankReceipt", paymentMethod);
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult RegisterArtemisBankPayCard(string bankName
            , string branchCode
            , string accountNumber
            , string tcNumber
            , string iban
            )
        {
            if (!CustomProfile.Current.IsAuthenticated)
                throw new UnauthorizedAccessException();

            PayCardRec payCard = new PayCardRec();
            payCard.VendorID = VendorID.ArtemisBank;
            payCard.BankName = bankName;
            payCard.BankBranchCode = branchCode;
            payCard.BankAccountNo = accountNumber;
            payCard.BankIBAN = iban.DefaultIfNullOrEmpty("").ToUpper();
            payCard.BankAdditionalInfo = tcNumber;
            payCard.IdentityNumber = payCard.BankIBAN.DefaultIfNullOrEmpty(payCard.BankAccountNo);

            long newPayCardID = GamMatrixClient.RegisterPayCard(payCard);

            return this.Json(new { @success = true, @payCardID = newPayCardID.ToString() });
        }


        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult RegisterTurkeyBankPayCard(string bankName
            , string branchCode
            , string accountNumber
            , string tcNumber
            , string iban
            )
        {
            if (!CustomProfile.Current.IsAuthenticated)
                throw new UnauthorizedAccessException();

            PayCardRec payCard = new PayCardRec();
            payCard.VendorID = VendorID.TurkeyBank;
            payCard.BankName = bankName;
            payCard.BankBranchCode = branchCode;
            payCard.BankAccountNo = accountNumber;
            payCard.BankIBAN = iban.DefaultIfNullOrEmpty("").ToUpper();
            payCard.BankAdditionalInfo = tcNumber;
            payCard.IdentityNumber = payCard.BankIBAN.DefaultIfNullOrEmpty(payCard.BankAccountNo);

            long newPayCardID = GamMatrixClient.RegisterPayCard(payCard);

            return this.Json(new { @success = true, @payCardID = newPayCardID.ToString() });
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult RegisterAPXBankPayCard(string bankName
            , string branchAddress
            , string iban
            , string tcNumber
            , string swift
            , string bankBranchCode
            , string dateOfBirth
            , string cellPhoneNumber
            )
        {
            if (!CustomProfile.Current.IsAuthenticated)
                throw new UnauthorizedAccessException();

            PayCardRec payCard = new PayCardRec();
            payCard.VendorID = VendorID.APX;
            payCard.BankName = bankName;
            payCard.BankAddress = branchAddress;
            payCard.BankIBAN = iban.DefaultIfNullOrEmpty("").ToUpper();
            payCard.BankSWIFT = swift.DefaultIfNullOrEmpty("").ToUpperInvariant();
            payCard.BankAdditionalInfo = tcNumber;
            payCard.IdentityNumber = payCard.BankIBAN.DefaultIfNullOrEmpty(payCard.BankAccountNo);
            payCard.BankBranchCode = bankBranchCode.ToString();

            long newPayCardID = GamMatrixClient.RegisterPayCard(payCard, new Dictionary<string, string>
            {
                { "birth_date", dateOfBirth },
                { "phone_num", cellPhoneNumber }
            });

            return this.Json(new { @success = true, @payCardID = newPayCardID.ToString() });
        }

        /// <summary>
        /// The receipt page
        /// </summary>
        /// <param name="paymentMethodName"></param>
        /// <param name="sid"></param>
        /// <returns></returns>
        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult RegisterBankPayCard(VendorID vendorID
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
            , string currency
            )
        {
            try
            {
                if (!CustomProfile.Current.IsAuthenticated)
                    throw new UnauthorizedAccessException();

                PayCardRec payCard = new PayCardRec();
                payCard.VendorID = vendorID;
                payCard.BankCountryID = countryID;
                payCard.BankName = bankName;
                payCard.BankAddress = branchAddress;
                payCard.BankCode = bankCode;
                payCard.BankBranchCode = branchCode;
                payCard.OwnerName = payee;
                payCard.BankBeneficiaryName = payee;
                payCard.BankBeneficiaryAddress = payeeAddress;
                payCard.BankAccountNo = accountNumber.DefaultIfNullOrEmpty("").ToUpperInvariant();
                payCard.BankIBAN = iban.DefaultIfNullOrEmpty("").ToUpperInvariant();
                payCard.BankSWIFT = swift.DefaultIfNullOrEmpty("").ToUpperInvariant();
                payCard.BankCheckDigits = checkDigits;
                payCard.BankAdditionalInfo = additionalInformation;
                payCard.IdentityNumber = payCard.BankIBAN.DefaultIfNullOrEmpty(payCard.BankAccountNo);

                if (!string.IsNullOrWhiteSpace(currency))
                    payCard.Currency = currency;

                if (payCard.BankIBAN.Length <= 2)
                    payCard.BankIBAN = "";

                Dictionary<string, string> requestDynamicFields = null;
                PrepareEnterCashPayCard(payCard, ref requestDynamicFields);
                long newPayCardID = GamMatrixClient.RegisterPayCard(payCard, requestDynamicFields);

                return this.Json(new { @success = true, @payCardID = newPayCardID.ToString() });
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = GmException.TryGetFriendlyErrorMsg(ex) });
            }
        }

        protected void PrepareEnterCashPayCard(PayCardRec payCard, ref Dictionary<string, string> requestDynamicFields)
        {
            if (payCard.VendorID != VendorID.EnterCash)
            {
                requestDynamicFields = null;
                return;
            }

            List<EnterCashRequestBankInfo> enterCashGetBankInfoRequest = GamMatrixClient.GetEnterCashBankInfo();
            var banks = enterCashGetBankInfoRequest.Where(b => b.WithdrawalSupport && string.Equals(b.Type, "bank", StringComparison.InvariantCultureIgnoreCase));

            string countryCode = null;
            if (payCard.BankCountryID == 79) // Finland
            {
                countryCode = "FI";
            }
            else if (payCard.BankCountryID == 211) // Sweden
            {
                countryCode = "SE";
            }
            else
                throw new NotSupportedException();

            EnterCashRequestBankInfo bank = null;

            // find the bank via BIC / SWIFT, the first 6 charactors match with the input
            if (!string.IsNullOrWhiteSpace(payCard.BankSWIFT))
            {
                string prefix = payCard.BankSWIFT.Substring(0, 6);
                bank = banks.FirstOrDefault(b => b.DomesticDepositInfo != null
                    && b.DomesticDepositInfo.ContainsKey("clearing_number")
                    && b.DomesticDepositInfo["clearing_number"].StartsWith(prefix, StringComparison.InvariantCultureIgnoreCase)
                    );
            }

            // if no matched bank found, choose Nordea
            if (bank == null && payCard.BankCountryID == 79)
            {
                bank = banks.FirstOrDefault(b => string.Equals(b.Name, "Nordea", StringComparison.InvariantCultureIgnoreCase));
            }
            // if no matched bank found, choose one from the same country
            if (bank == null)
            {
                bank = banks.FirstOrDefault(b => string.Equals(b.ClearingHouse, countryCode, StringComparison.InvariantCultureIgnoreCase));
            }
            if (bank == null)
            {
                throw new NotSupportedException();
            }

            if (string.IsNullOrWhiteSpace(payCard.BankName))
                payCard.BankName = bank.Name;

            requestDynamicFields = new Dictionary<string, string>();
            requestDynamicFields.Add("bankid", bank.Id.ToString());
            requestDynamicFields.Add("transfer_type", "DOMESTIC");
            requestDynamicFields.Add("clearing_house", bank.ClearingHouse);

            if (!string.IsNullOrWhiteSpace(payCard.BankSWIFT))
                requestDynamicFields.Add("bic", payCard.BankSWIFT);

            if (!string.IsNullOrWhiteSpace(payCard.BankIBAN))
                requestDynamicFields.Add("iban", payCard.BankIBAN);

            if (!string.IsNullOrWhiteSpace(payCard.BankCode))
                requestDynamicFields.Add("clearing_number", payCard.BankCode);

            if (!string.IsNullOrWhiteSpace(payCard.BankAccountNo))
                requestDynamicFields.Add("account_number", payCard.BankAccountNo);

            if (!string.IsNullOrWhiteSpace(payCard.BankBeneficiaryName))
                requestDynamicFields.Add("beneficiary_name", payCard.OwnerName);
        }

        /// <summary>
        /// Register EnterCash Pay Card
        /// </summary>
        /// <param name="paymentMethodName"></param>
        /// <param name="sid"></param>
        /// <returns></returns>
        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult RegisterEnterCashPayCard(VendorID vendorID
            , long bankID
            , string bic
            , string iban
            , string clearingNumber
            , string accountNumber
            , string beneficiaryName
            , string beneficiaryAddress
            , string transferType = "DOMESTIC"
            )
        {
            try
            {
                if (!CustomProfile.Current.IsAuthenticated)
                    throw new UnauthorizedAccessException();

                List<EnterCashRequestBankInfo> list = GamMatrixClient.GetEnterCashBankInfo();
                EnterCashRequestBankInfo bankInfo = list.FirstOrDefault(b => b.Id == bankID);

                if (bankInfo == null)
                    throw new ArgumentException("invalid bank");
                if (!bankInfo.WithdrawalSupport)
                    throw new ArgumentException("invalid withdrawal bank");

                long countryID = 0;
                if (bankInfo.ClearingHouse == "FI") //Finland
                    countryID = 79;
                else if (bankInfo.ClearingHouse == "SE") //Sweden
                    countryID = 211;
                else
                    throw new NotSupportedException();

                PayCardRec payCard = new PayCardRec();
                payCard.UserID = CustomProfile.Current.UserID;
                payCard.Type = PayCardType.Ordinary;
                payCard.ActiveStatus = ActiveStatus.Active;
                payCard.VendorID = vendorID;
                payCard.IdentityNumber = string.Format("{0}-{1}", bankInfo.Id, iban.DefaultIfNullOrWhiteSpace(accountNumber)); //MANDATORY in order to pass GmCore validation
                payCard.BankCountryID = countryID;

                var requestFields = new Dictionary<string, string>();
                requestFields.Add("bankid", bankInfo.Id.ToString());
                requestFields.Add("transfer_type", transferType);
                requestFields.Add("clearing_house", bankInfo.ClearingHouse);

                foreach (string info in transferType.Equals("DOMESTIC", StringComparison.InvariantCultureIgnoreCase) ?
                    bankInfo.DomesticWithdrawalInfo :
                    bankInfo.InternationalWithdrawalInfo)
                {
                    switch (info.ToLowerInvariant())
                    {
                        case "bic":
                            requestFields.Add("bic", bic);
                            payCard.BankSWIFT = bic;
                            break;
                        case "iban":
                            requestFields.Add("iban", iban);
                            payCard.BankIBAN = iban;
                            break;
                        case "clearing_number":
                            requestFields.Add("clearing_number", clearingNumber);
                            payCard.BankCode = clearingNumber;
                            break;
                        case "account_number":
                            requestFields.Add("account_number", accountNumber);
                            payCard.BankAccountNo = accountNumber;
                            break;
                        case "beneficiary_name":
                            requestFields.Add("beneficiary_name", beneficiaryName);
                            payCard.OwnerName = beneficiaryAddress;
                            break;
                        case "beneficiary_address":
                            requestFields.Add("beneficiary_address", beneficiaryAddress);
                            break;
                        default:
                            break;
                    }

                    if (!requestFields.Keys.Contains(info))
                        throw new ArgumentException("EnterCash - lack of parameter");

                    if (string.IsNullOrWhiteSpace(requestFields[info]))
                        throw new ArgumentException("EnterCash - invalid parameter");
                }

                RegisterPayCardRequest request;
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    request = client.SingleRequest<RegisterPayCardRequest>(
                        new RegisterPayCardRequest()
                        {
                            Record = payCard,
                            RequestDynamicFields = requestFields,
                        });
                }

                long newPayCardID = 0;
                if (request != null)
                    newPayCardID = request.Record.ID;

                return this.Json(new { @success = true, @payCardID = newPayCardID.ToString() });
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = GmException.TryGetFriendlyErrorMsg(ex) });
            }
        }


        [HttpGet]
        public JsonResult GetBankPayCards()
        {
            try
            {
                if (!CustomProfile.Current.IsAuthenticated)
                    throw new UnauthorizedAccessException();

                var payCards = GamMatrixClient.GetPayCards()
                    .Where(p => !p.IsDummy &&
                        (p.VendorID == VendorID.Bank ||
                            p.VendorID == VendorID.InPay ||
                            (p.VendorID == VendorID.Envoy &&
                            !string.Equals(p.BankName, "WEBMONEY", StringComparison.OrdinalIgnoreCase) &&
                            !string.Equals(p.BankName, "MONETA", StringComparison.OrdinalIgnoreCase) &&
                            !string.Equals(p.BankName, "INSTADEBIT", StringComparison.OrdinalIgnoreCase) &&
                            !string.Equals(p.BankName, "SPEEDCARD", StringComparison.OrdinalIgnoreCase)) ||
                            p.VendorID == VendorID.EnterCash))
                    // Exclude Turkey Envoy PayCard
                    .Where(p => ((p.VendorID == VendorID.Envoy && p.BankCountryID != 223) ||
                                p.VendorID == VendorID.Bank ||
                                p.VendorID == VendorID.InPay ||
                                p.VendorID == VendorID.EnterCash))
                    .OrderByDescending(p => p.Ins)
                    .ToList();

                if (payCards.Any(p => p.VendorID == VendorID.EnterCash && !p.IsDummy && p.ActiveStatus == ActiveStatus.Active))
                {
                    var payCardsToRemove = new List<PayCardInfoRec>();
                    var banks = GamMatrixClient.GetEnterCashBankInfo(false);
                    foreach (var payCard in payCards.Where(p => p.VendorID == VendorID.EnterCash && !p.IsDummy && p.ActiveStatus == ActiveStatus.Active))
                    {
                        var exists = false;
                        if (payCard.DisplaySpecificFields != null)
                        {
                            var field = payCard.DisplaySpecificFields.FirstOrDefault(dsf => dsf.Key == "bankid");
                            if (field != null)
                            {
                                long bankID;
                                if (long.TryParse(field.Value, out bankID))
                                {
                                    if (banks.Any(b => b.Id == bankID))
                                        exists = true;
                                }
                            }
                        }

                        if (!exists)
                            payCardsToRemove.Add(payCard);
                    }
                    foreach (var payCard in payCardsToRemove)
                    {
                        try
                        {
                            GamMatrixClient.UpdatePayCardStatus(payCard.ID, ActiveStatus.InActive);
                        }
                        catch (Exception ex)
                        {
                            Logger.Exception(ex);
                        }
                        payCards.Remove(payCard);
                    }
                }

                var payCards2 = payCards
                    .Select(p => new
                    {
                        ID = p.ID.ToString(),
                        p.BankName,
                        p.BankCode,
                        BranchAddress = p.BankAddress,
                        BranchCode = p.BankBranchCode,
                        Payee = p.BankBeneficiaryName,
                        PayeeAddress = p.BankBeneficiaryAddress,
                        IBAN = p.BankIBAN,
                        SWIFT = p.BankSWIFT,
                        AccountNumber = p.BankAccountNo,
                        DisplayName = p.BankIBAN.DefaultIfNullOrEmpty(p.BankAccountNo),
                        Currency = p.Currency.DefaultIfNullOrEmpty(string.Empty),
                        BankAdditionalInfo = p.BankAdditionalInfo,
                        VendorID = p.VendorID.ToString(),
                    }).ToArray();
                return this.Json(new { @success = true, @payCards = payCards2 }, JsonRequestBehavior.AllowGet);
            }
            catch (GmException ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = GmException.TryGetFriendlyErrorMsg(ex) }, JsonRequestBehavior.AllowGet);
            }
        }


        [HttpGet]
        public JsonResult GetArtemisBankPayCards()
        {
            try
            {
                if (!CustomProfile.Current.IsAuthenticated)
                    throw new UnauthorizedAccessException();

                var payCards = GamMatrixClient.GetPayCards()
                    .Where(p => !p.IsDummy && p.VendorID == VendorID.ArtemisBank)
                    .OrderByDescending(p => p.Ins)
                    .Select(p => new
                    {
                        ID = p.ID.ToString(),
                        p.BankName,
                        BranchCode = p.BankBranchCode,
                        IBAN = p.BankIBAN,
                        AccountNumber = p.BankAccountNo,
                        BankAdditionalInfo = p.BankAdditionalInfo,
                        DisplayName = p.BankIBAN.DefaultIfNullOrEmpty(p.BankAccountNo),
                    }).ToArray();
                return this.Json(new { @success = true, @payCards = payCards }, JsonRequestBehavior.AllowGet);
            }
            catch (GmException ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = GmException.TryGetFriendlyErrorMsg(ex) }, JsonRequestBehavior.AllowGet);
            }
        }

        [HttpGet]
        public JsonResult GetTurkeyBankPayCards()
        {
            try
            {
                if (!CustomProfile.Current.IsAuthenticated)
                    throw new UnauthorizedAccessException();

                var payCards = GamMatrixClient.GetPayCards()
                    .Where(p => !p.IsDummy && p.VendorID == VendorID.TurkeyBank)
                    .OrderByDescending(p => p.Ins)
                    .Select(p => new
                    {
                        ID = p.ID.ToString(),
                        p.BankName,
                        BranchCode = p.BankBranchCode,
                        IBAN = p.BankIBAN,
                        AccountNumber = p.BankAccountNo,
                        BankAdditionalInfo = p.BankAdditionalInfo,
                        DisplayName = p.BankIBAN.DefaultIfNullOrEmpty(p.BankAccountNo),
                    }).ToArray();
                return this.Json(new { @success = true, @payCards = payCards }, JsonRequestBehavior.AllowGet);
            }
            catch (GmException ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = GmException.TryGetFriendlyErrorMsg(ex) }, JsonRequestBehavior.AllowGet);
            }
        }

        [HttpGet]
        public JsonResult GetAPXBankPayCards()
        {
            try
            {
                if (!CustomProfile.Current.IsAuthenticated)
                    throw new UnauthorizedAccessException();

                var payCards = GamMatrixClient.GetPayCards()
                    .Where(p => !p.IsDummy && p.VendorID == VendorID.APX)
                    .OrderByDescending(p => p.Ins)
                    .Select(p => new
                    {
                        ID = p.ID.ToString(),
                        BankName = p.BankName,
                        BranchAddress = p.BankAddress,
                        IBAN = p.BankIBAN,
                        SWIFT = p.BankSWIFT,
                        BankAdditionalInfo = p.BankAdditionalInfo,
                        DisplayName = p.BankIBAN.DefaultIfNullOrEmpty(p.BankAccountNo),
                        BankBranchCode = p.BankBranchCode,
                        BirthDate =
                            p.DisplaySpecificFields.Exists(f => string.Equals(f.Key, "birth_date", StringComparison.OrdinalIgnoreCase)) ?
                                p.DisplaySpecificFields.First(f => string.Equals(f.Key, "birth_date", StringComparison.OrdinalIgnoreCase)).Value : string.Empty,

                        PhoneNumber =
                p.DisplaySpecificFields.Exists(f => string.Equals(f.Key, "phone_num", StringComparison.OrdinalIgnoreCase)) ?
                        p.DisplaySpecificFields.First(f => string.Equals(f.Key, "phone_num", StringComparison.OrdinalIgnoreCase)).Value : string.Empty
                    }).ToArray();

                return this.Json(new { @success = true, @payCards = payCards }, JsonRequestBehavior.AllowGet);
            }
            catch (GmException ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = GmException.TryGetFriendlyErrorMsg(ex) }, JsonRequestBehavior.AllowGet);
            }
        }

        [HttpGet]
        public JsonResult GetLocalBankPayCards()
        {
            try
            {
                if (!CustomProfile.Current.IsAuthenticated)
                    throw new UnauthorizedAccessException();

                var payCards = GamMatrixClient.GetPayCards()
                    .Where(p => !p.IsDummy && p.VendorID == VendorID.LocalBank)
                    .OrderByDescending(p => p.Ins)
                    .Select(p => new
                    {
                        ID = p.ID.ToString(),
                        DisplayNumber = p.DisplayNumber,
                        BankName = p.BankName,
                        OwnerName = p.OwnerName,
                        BankAccountNo = p.BankAccountNo,
                        BankCountryID = p.BankCountryID,
                    }).ToArray();
                return this.Json(new { @success = true, @payCards = payCards }, JsonRequestBehavior.AllowGet);
            }
            catch (GmException ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = GmException.TryGetFriendlyErrorMsg(ex) }, JsonRequestBehavior.AllowGet);
            }
        }

        private class ClientPayCard
        {
            public string ID { get; set; }
            public string BankID { get; set; }
            public string BankName { get; set; }
            public string ClearingHouse { get; set; }
            public string BIC { get; set; }
            public string IBAN { get; set; }
            public string AccountNumber { get; set; }
            public string ClearingNumber { get; set; }
            public string Currency { get; set; }
            public string BeneficiaryName { get; set; }
            public string BeneficiaryAddress { get; set; }
            public string DisplayName { get; set; }
        }

        [HttpGet]
        public JsonResult GetEnterCashPayCards()
        {
            try
            {
                if (!CustomProfile.Current.IsAuthenticated)
                    throw new UnauthorizedAccessException();

                Func<List<KeyValueOfstringstring>, EnterCashRequestBankInfo, bool> func = (displaySpecificFields, bank) =>
                    {
                        foreach (string s in bank.DomesticWithdrawalInfo)
                        {
                            if (!displaySpecificFields.Exists(f => f.Key.Equals(s, StringComparison.InvariantCultureIgnoreCase)))
                                return false;
                        }
                        return true;
                    };

                var payCards = new List<ClientPayCard>();

                List<EnterCashRequestBankInfo> banks = GamMatrixClient.GetEnterCashBankInfo();
                EnterCashRequestBankInfo bankInfo;

                var originalPayCards = GamMatrixClient.GetPayCards()
                    .Where(p => !p.IsDummy && p.VendorID == VendorID.EnterCash).ToList();

                if (originalPayCards != null && originalPayCards.Count > 0)
                {
                    foreach (PayCardInfoRec payCard in originalPayCards)
                    {
                        ClientPayCard c = new ClientPayCard()
                        {
                            ID = payCard.ID.ToString(),
                            AccountNumber = "",
                            BankID = "",
                            BankName = "",
                            BeneficiaryName = "",
                            BIC = "",
                            ClearingHouse = "",
                            ClearingNumber = "",
                            Currency = "",
                            DisplayName = "",
                            IBAN = "",
                            BeneficiaryAddress = ""
                        };

                        foreach (KeyValueOfstringstring kv in payCard.DisplaySpecificFields)
                        {
                            switch (kv.Key)
                            {
                                case "bankid":
                                    c.BankID = kv.Value;
                                    break;

                                case "clearing_house":
                                    c.ClearingHouse = kv.Value;
                                    break;

                                case "transfer_type":

                                    break;

                                case "bic":
                                    c.BIC = kv.Value;
                                    break;

                                case "iban":
                                    c.IBAN = kv.Value;
                                    break;

                                case "clearing_number":
                                    c.ClearingNumber = kv.Value;
                                    break;

                                case "account_number":
                                    c.AccountNumber = kv.Value;
                                    break;

                                case "beneficiary_name":
                                    c.BeneficiaryName = kv.Value;
                                    break;
                                case "beneficiary_address":
                                    c.BeneficiaryAddress = kv.Value;
                                    break;
                            }
                        }
                        bankInfo = banks.FirstOrDefault(b => b.Id == int.Parse(c.BankID));
                        if (bankInfo != null && func(payCard.DisplaySpecificFields, bankInfo))
                        {
                            c.DisplayName = c.IBAN.DefaultIfNullOrWhiteSpace(c.AccountNumber);
                            c.BankName = bankInfo.Name;
                            payCards.Add(c);
                        }
                    }
                }

                return this.Json(new { @success = true, @payCards = payCards }, JsonRequestBehavior.AllowGet);
            }
            catch (GmException ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = GmException.TryGetFriendlyErrorMsg(ex) }, JsonRequestBehavior.AllowGet);
            }
        }


        [HttpGet]
        public JsonResult GetPayCards(VendorID vendorID, string paymentMethodName)
        {
            try
            {
                if (!CustomProfile.Current.IsAuthenticated)
                    throw new UnauthorizedAccessException();

                // handle Envoy sub types
                if (!string.IsNullOrWhiteSpace(paymentMethodName) && vendorID == VendorID.Envoy)
                {
                    PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods().FirstOrDefault(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.OrdinalIgnoreCase));
                    if (paymentMethod != null)
                    {
                        var payCards = GamMatrixClient.GetPayCards(vendorID)
                            .Where(p => !p.IsDummy && string.Equals(p.BankName, paymentMethod.SubCode, StringComparison.OrdinalIgnoreCase))
                            .OrderByDescending(p => p.Ins)
                            .Select(p => new
                            {
                                ID = p.ID.ToString(),
                                DisplayNumber = p.DisplayName,
                                BankName = p.BankName,
                            })
                            .ToArray();
                        return this.Json(new { @success = true, @payCards = payCards }, JsonRequestBehavior.AllowGet);
                    }
                }

                var payCardInfoRecs = vendorID == VendorID.MoneyMatrix
                    ? GamMatrixClient.GetPayCards(vendorID).Where(p => true)
                    : GamMatrixClient.GetPayCards(vendorID);

                var payCards2 = payCardInfoRecs
                    .Where(p => !p.IsDummy)
                    .OrderByDescending(p => p.Ins)
                    .Select(p => new
                    {
                        ID = p.ID.ToString(),
                        DisplayNumber = p.DisplayName,
                        BankName = p.BankName,
                    })
                    .ToArray();
                return this.Json(new { @success = true, @payCards = payCards2 }, JsonRequestBehavior.AllowGet);
            }
            catch (GmException ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = GmException.TryGetFriendlyErrorMsg(ex) }, JsonRequestBehavior.AllowGet);
            }
        }


        public JsonResult RegisterEnvoyOnClickPayCard(string paymentMethodName, string identityNumber)
        {
            if (!CustomProfile.Current.IsAuthenticated)
                throw new UnauthorizedAccessException();

            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods().First(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.OrdinalIgnoreCase));
            if (paymentMethod.VendorID != VendorID.Envoy)
                throw new ArgumentException("paymentMethodName");

            PayCardRec payCard = new PayCardRec();
            payCard.VendorID = VendorID.Envoy;
            payCard.BankName = paymentMethod.SubCode;
            payCard.InternalAccountNo = paymentMethod.SubCode;
            payCard.IdentityNumber = identityNumber;
            payCard.DisplayName = identityNumber;
            payCard.DisplayNumber = identityNumber;
            payCard.ActiveStatus = ActiveStatus.Active;
            payCard.UserID = CustomProfile.Current.UserID;

            long newPayCardID = GamMatrixClient.RegisterPayCard(payCard);

            return this.Json(new { @success = true, @payCardID = newPayCardID.ToString() });
        }

        [HttpGet]
        public ActionResult WithdrawPlus()
        {
            return this.View("WithdrawPlus");
        }


        public ActionResult GeorgianCardATMCodeList(int? pageIndex, int? pageSize)
        {
            if (!CustomProfile.Current.IsAuthenticated)
                throw new UnauthorizedAccessException();

            if (!pageSize.HasValue || pageSize.Value <= 0)
                pageSize = 10;
            if (!pageIndex.HasValue || pageIndex.Value < 0)
                pageIndex = 0;

            using (GamMatrixClient client = GamMatrixClient.Get())
            {
                GeorgianCardATMGetCodesRequest request = new GeorgianCardATMGetCodesRequest
                {
                    SelectionCriteria = new GeorgianCardATMGetCodesSelectParams
                    {
                        ByUserID = true,
                        ParamUserID = CustomProfile.Current.UserID,
                    },

                    PagedData = new PagedDataOfGeorgianCardATMCodeInfoRec
                    {
                        PageNumber = pageIndex.Value,
                        PageSize = pageSize.Value,
                    }
                };
                request = client.SingleRequest<GeorgianCardATMGetCodesRequest>(request);

                this.ViewData["PageNumber"] = request.PagedData.PageNumber;
                this.ViewData["TotalPages"] = request.PagedData.TotalPages;
                return View("GeorgianCardATM_CodeList", request.PagedData.Records);
            }
        }


        [HttpGet]
        public ActionResult GenerateGeorgianCardATMCode(bool? ignoreBalance)
        {
            try
            {
                if (!CustomProfile.Current.IsAuthenticated)
                    throw new UnauthorizedAccessException();

                List<PaymentMethod> allPaymentMethods = PaymentMethodManager.GetPaymentMethods();
                PaymentMethod paymentMethod = allPaymentMethods.First(p => p.UniqueName == "GeorgianCard_ATM");

                // check the min limitation
                if (!ignoreBalance.HasValue || !ignoreBalance.Value)
                {
                    List<AccountData> accounts = GamMatrixClient.GetUserGammingAccounts(CustomProfile.Current.UserID, false);
                    AccountData account = accounts.FirstOrDefault(a => a.Record.VendorID == VendorID.System);
                    if (account != null)
                    {
                        Range range = paymentMethod.GetWithdrawLimitation(account.BalanceCurrency);
                        if (range.MinAmount > 0.00M && account.BalanceAmount < range.MinAmount)
                        {
                            return this.View("GeorgianCardATM_BalanceWarning", range);
                        }
                    }
                }

                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    GeorgianCardATMGetCodesRequest rq = new GeorgianCardATMGetCodesRequest
                    {
                        SelectionCriteria = new GeorgianCardATMGetCodesSelectParams
                        {
                            ByUserID = true,
                            ParamUserID = CustomProfile.Current.UserID,
                        },

                        PagedData = new PagedDataOfGeorgianCardATMCodeInfoRec
                        {
                            PageNumber = 0,
                            PageSize = long.MaxValue,
                        }
                    };
                    rq = client.SingleRequest<GeorgianCardATMGetCodesRequest>(rq);

                    GeorgianCardATMCodeInfoRec rec = null;
                    if (rq.PagedData != null && rq.PagedData.Records != null)
                        rec = rq.PagedData.Records.FirstOrDefault(c => c.Status == GeorgianCardATMCodeStatus.Setup || c.Status == GeorgianCardATMCodeStatus.Pending);
                    if (rec != null)
                    {
                        this.ViewData["NewCode"] = rec.Code;
                    }
                    else
                    {
                        GeorgianCardATMGenerateCodeRequest request = new GeorgianCardATMGenerateCodeRequest()
                        {
                            UserID = CustomProfile.Current.UserID,
                        };
                        request = client.SingleRequest<GeorgianCardATMGenerateCodeRequest>(request);
                        this.ViewData["NewCode"] = request.Code; ;
                    }

                    return View("GeorgianCardATM_NewCode");
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return this.View("GeorgianCardATM_Error");
            }
        }


        public JsonResult CancelGeorgianCardATMCode(string code)
        {
            try
            {
                if (!CustomProfile.Current.IsAuthenticated)
                    throw new UnauthorizedAccessException();
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    GeorgianCardATMCancelCodeRequest request = new GeorgianCardATMCancelCodeRequest()
                    {
                        UserID = CustomProfile.Current.UserID,
                        Code = code,
                    };
                    request = client.SingleRequest<GeorgianCardATMCancelCodeRequest>(request);

                    return this.Json(new
                    {
                        @success = false
                    });
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new
                {
                    @success = false,
                    @error = GmException.TryGetFriendlyErrorMsg(ex)
                });
            }
        }

        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult Cancel(string paymentMethodName, string pid)
        {
            return View("Error");
        }


        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult Return(string paymentMethodName, string pid)
        {
            if (string.IsNullOrWhiteSpace(pid))
                throw new ArgumentNullException("pid");

            string sid = cmTransParameter.ReadObject<string>(pid, "Sid");
            if (string.IsNullOrWhiteSpace(sid))
                throw new ArgumentNullException("sid");

            string url = this.Url.RouteUrl("Withdraw", new { @action = "Receipt", @paymentMethodName = paymentMethodName, @sid = sid });
            return Redirect(url);
        }

        public ActionResult Postback(string paymentMethodName, string pid)
        {
            throw new NotImplementedException();
            //string sid = cmTransParameter.ReadObject<string>(pid, "Sid");
            //return View("Postback");
        }

        #region Check payment method
        protected bool CheckPaymentMethod(PaymentMethod paymentMethod)
        {
            if (Settings.Withdraw_SkipPaymentMethodCheck)
                return true;

            List<PaymentMethod> allPaymentMethods = PaymentMethodManager.GetPaymentMethods().Where(p => p.SupportWithdraw
            && GmCore.DomainConfigAgent.IsWithdrawEnabled(p)
            && p.WithdrawSupportedCountries.Exists(CustomProfile.Current.UserCountryID)
            ).ToList();
            List<PayCardInfoRec> payCards = GamMatrixClient.GetPayCards();

            List<string> paymentMethodNames = new List<string>();


            bool isAvailable = false;

            // PT
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

            // MB
            if (payCards.Exists(p => p.VendorID == VendorID.Moneybookers &&
                p.SuccessDepositNumber > 0))
            {
                paymentMethodNames.Add("Moneybookers");
            }
            else if (CustomProfile.Current.IsInRole("Affiliate"))
            {
                paymentMethodNames.Add("Moneybookers");
            }
            else if (SiteManager.Current.DistinctName.Equals("IntraGame", StringComparison.InvariantCultureIgnoreCase)
                && CustomProfile.Current.UserCountryID == 166) // Norway
            {
                paymentMethodNames.Add("Moneybookers");
            }


            // Intercash
            if (payCards.Exists(p => p.VendorID == VendorID.Intercash))
            {
                if (payCards.Exists(p => p.VendorID == VendorID.Intercash && !p.IsDummy))
                {
                    paymentMethodNames.Add("Intercash");
                }
                else if (CustomProfile.Current.IsInRole("Affiliate"))
                {
                    paymentMethodNames.Add("Intercash");
                }
            }

            // EcoCard
            if (payCards.Exists(p => p.VendorID == VendorID.EcoCard && !p.IsDummy))
            {
                paymentMethodNames.Add("EcoCard");
            }

            // NETELLER
            bool isNetEllerAvailable = true;
            if (CustomProfile.Current.UserCountryID == 28
                && (SiteManager.Current.DistinctName.Equals("jetbull", StringComparison.InvariantCultureIgnoreCase)
                    || SiteManager.Current.DistinctName.Equals("jetbullmobile", StringComparison.InvariantCultureIgnoreCase)
                    || SiteManager.Current.DistinctName.Equals("jetbullRD", StringComparison.InvariantCultureIgnoreCase))
                ) //Belgium
            {
                isNetEllerAvailable = false;
            }

            if (isNetEllerAvailable)
            {
                if (payCards.Exists(p => p.VendorID == VendorID.Neteller &&
                    p.SuccessDepositNumber > 0))
                {
                    paymentMethodNames.Add("Neteller");
                }
                else if (CustomProfile.Current.IsInRole("Affiliate"))
                {
                    paymentMethodNames.Add("Neteller");
                }
            }

            // TLNakit
            if (payCards.Exists(p => p.VendorID == VendorID.TLNakit && p.IsDummy && p.SuccessDepositNumber > 0))
            {
                paymentMethodNames.Add("TLNakit");
            }


            //if (allPaymentMethods.Exists(p => p.IsAvailable && p.UniqueName.Equals("EnterCashBank", StringComparison.InvariantCultureIgnoreCase)))
            //{
            //    var enterCashBank = allPaymentMethods.FirstOrDefault(p => p.IsAvailable && p.UniqueName.Equals("EnterCashBank", StringComparison.InvariantCultureIgnoreCase));
            //    if (enterCashBank.SupportedCountries.Exists(Profile.UserCountryID))
            //    {
            //        paymentMethodNames.Add("EnterCashBank");
            //    }
            //}

            // Local Bank, CMS-2208
            paymentMethodNames.Add("LocalBank");

            // Envoy One-Click Services
            if (payCards.Exists(p => p.VendorID == VendorID.Envoy &&
                string.Equals(p.BankName, "WEBMONEY", StringComparison.InvariantCultureIgnoreCase) &&
                p.SuccessDepositNumber > 0))
            {
                paymentMethodNames.Add("Envoy_WebMoney");
            }
            else if (CustomProfile.Current.IsInRole("Affiliate"))
            {
                paymentMethodNames.Add("Envoy_WebMoney");
            }

            if (payCards.Exists(p => p.VendorID == VendorID.Envoy &&
                string.Equals(p.BankName, "MONETA", StringComparison.InvariantCultureIgnoreCase) &&
                p.SuccessDepositNumber > 0))
            {
                paymentMethodNames.Add("Envoy_Moneta");
            }
            if (payCards.Exists(p => p.VendorID == VendorID.Envoy &&
                string.Equals(p.BankName, "INSTADEBIT", StringComparison.InvariantCultureIgnoreCase) &&
                p.SuccessDepositNumber > 0))
            {
                paymentMethodNames.Add("Envoy_InstaDebit");
            }
            if (payCards.Exists(p => p.VendorID == VendorID.Envoy &&
                string.Equals(p.BankName, "SPEEDCARD", StringComparison.InvariantCultureIgnoreCase) &&
                p.SuccessDepositNumber > 0))
            {
                paymentMethodNames.Add("Envoy_SpeedCard");
            }

            // UKash
            if (IsUkashAllowed(payCards))
            {
                paymentMethodNames.Add("Ukash");
            }

            // GEOGIAN CARD
            if (payCards.Exists(p => p.VendorID == VendorID.GeorgianCard &&
                p.SuccessDepositNumber > 0))
            {
                paymentMethodNames.Add("GeorgianCard");
            }
            else if (string.Equals(SiteManager.Current.DistinctName, "PlayAdjara", StringComparison.InvariantCultureIgnoreCase))
            {
                paymentMethodNames.Add("GeorgianCard");
            }

            // MENOTA
            if (payCards.Exists(p => p.VendorID == VendorID.PayAnyWay &&
                p.SuccessDepositNumber > 0))
            {
                paymentMethodNames.Add("PayAnyWay_Moneta");
                paymentMethodNames.Add("PayAnyWay_Yandex");
                paymentMethodNames.Add("PayAnyWay_WebMoney");
            }

            if (payCards.Exists(p => p.VendorID == VendorID.IPSToken &&
                p.SuccessDepositNumber > 0))
            {
                paymentMethodNames.Add("IPSToken");
            }


            isAvailable = allPaymentMethods.Exists(p =>
                string.Equals(p.UniqueName, "GeorgianCard_ATM", StringComparison.InvariantCultureIgnoreCase)
                && p.IsAvailable
                );
            if (isAvailable)
                paymentMethodNames.Add("GeorgianCard_ATM");

            isAvailable = allPaymentMethods.Exists(p =>
                    string.Equals(p.UniqueName, "APX_BankTransfer", StringComparison.InvariantCultureIgnoreCase)
                    && p.IsAvailable
                    && p.SupportedCountries.Exists(CustomProfile.Current.UserCountryID)
                    );
            if (isAvailable)
            {
                paymentMethodNames.Add("APX_BankTransfer");
            }

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



            isAvailable = allPaymentMethods.Exists(p =>
                string.Equals(p.UniqueName, "Trustly", StringComparison.InvariantCultureIgnoreCase)
                && p.IsAvailable
                && p.SupportedCountries.Exists(CustomProfile.Current.UserCountryID)
                );
            if (isAvailable)
                paymentMethodNames.Add("Trustly");

            isAvailable = allPaymentMethods.Exists(p =>
                    string.Equals(p.UniqueName, "BankTransfer", StringComparison.InvariantCultureIgnoreCase)
                    && p.IsAvailable
                    && p.SupportedCountries.Exists(CustomProfile.Current.UserCountryID)
                    );
            if (isAvailable)
                paymentMethodNames.Add("BankTransfer");

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

            // MM
            isAvailable = allPaymentMethods.Exists(p =>
                string.Equals(p.UniqueName, "MoneyMatrix", StringComparison.InvariantCultureIgnoreCase)
                && p.IsAvailable
                );
            if (isAvailable)
                isAvailable = payCards.Exists(p => p.VendorID == VendorID.MoneyMatrix && p.SuccessDepositNumber > 0);
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix");

            isAvailable = allPaymentMethods.Exists(p =>
                string.Equals(p.UniqueName, "MoneyMatrix_Trustly", StringComparison.InvariantCultureIgnoreCase)
                && p.IsAvailable
                );
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_Trustly");

            isAvailable = allPaymentMethods.Exists(p =>
                string.Equals(p.UniqueName, "MoneyMatrix_PayKasa", StringComparison.InvariantCultureIgnoreCase)
                && p.IsAvailable
                );
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_PayKasa");

            isAvailable = allPaymentMethods.Exists(p =>
                string.Equals(p.UniqueName, "MoneyMatrix_IBanq", StringComparison.InvariantCultureIgnoreCase)
                && p.IsAvailable
                );
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_IBanq");

            isAvailable = allPaymentMethods.Exists(p =>
                string.Equals(p.UniqueName, "MoneyMatrix_GPaySafe_BankTransfer", StringComparison.InvariantCultureIgnoreCase)
                && p.IsAvailable
                );
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_GPaySafe_BankTransfer");

            isAvailable = allPaymentMethods.Exists(p =>
                string.Equals(p.UniqueName, "MoneyMatrix_Offline_Nordea", StringComparison.InvariantCultureIgnoreCase)
                && p.IsAvailable
                );
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_Offline_Nordea");

            isAvailable = allPaymentMethods.Exists(p =>
                string.Equals(p.UniqueName, "MoneyMatrix_Offline_LocalBank", StringComparison.InvariantCultureIgnoreCase)
                && p.IsAvailable
                );
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_Offline_LocalBank");

            isAvailable = allPaymentMethods.Exists(p =>
                string.Equals(p.UniqueName, "MoneyMatrix_Skrill", StringComparison.InvariantCultureIgnoreCase)
                && p.IsAvailable
                );
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_Skrill");

            isAvailable = allPaymentMethods.Exists(p =>
                string.Equals(p.UniqueName, "MoneyMatrix_Skrill_1Tap", StringComparison.InvariantCultureIgnoreCase)
                && p.IsAvailable
                );
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_Skrill_1Tap");

            isAvailable = allPaymentMethods.Exists(p =>
                string.Equals(p.UniqueName, "MoneyMatrix_EcoPayz", StringComparison.InvariantCultureIgnoreCase)
                && p.IsAvailable
                );
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_EcoPayz");

            isAvailable = allPaymentMethods.Exists(p =>
                string.Equals(p.UniqueName, "MoneyMatrix_TLNakit", StringComparison.InvariantCultureIgnoreCase)
                && p.IsAvailable
                );
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_TLNakit");

            isAvailable = allPaymentMethods.Exists(p =>
                string.Equals(p.UniqueName, "MoneyMatrix_Neteller", StringComparison.InvariantCultureIgnoreCase)
                && p.IsAvailable
                );
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_Neteller");

            isAvailable = allPaymentMethods.Exists(p =>
                string.Equals(p.UniqueName, "MoneyMatrix_PaySafeCard", StringComparison.InvariantCultureIgnoreCase)
                && p.IsAvailable
                );
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_PaySafeCard");

            isAvailable = allPaymentMethods.Exists(p =>
                string.Equals(p.UniqueName, "MoneyMatrix_Adyen_SEPA", StringComparison.InvariantCultureIgnoreCase)
                && p.IsAvailable
                );
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_Adyen_SEPA");
            
            isAvailable = allPaymentMethods.Exists(p =>
                string.Equals(p.UniqueName, "MoneyMatrix_EnterPays_BankTransfer", StringComparison.InvariantCultureIgnoreCase)
                && p.IsAvailable);
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_EnterPays_BankTransfer");

            isAvailable = allPaymentMethods.Exists(p =>
               string.Equals(p.UniqueName, "MoneyMatrix_PPro_Qiwi", StringComparison.InvariantCultureIgnoreCase)
               && p.IsAvailable);
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_PPro_Qiwi");

            isAvailable = allPaymentMethods.Exists(p =>
                string.Equals(p.UniqueName, "MoneyMatrix_PPro_Sepa", StringComparison.InvariantCultureIgnoreCase)
                && p.IsAvailable);
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_PPro_Sepa");

            isAvailable = allPaymentMethods.Exists(p =>
               string.Equals(p.UniqueName, "MoneyMatrix_UPayCard", StringComparison.InvariantCultureIgnoreCase)
               && p.IsAvailable);
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_UPayCard");

            isAvailable = allPaymentMethods.Exists(p =>
               string.Equals(p.UniqueName, "MoneyMatrix_Visa", StringComparison.InvariantCultureIgnoreCase)
               && p.IsAvailable);
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_Visa");

            isAvailable = allPaymentMethods.Exists(p =>
              string.Equals(p.UniqueName, "MoneyMatrix_MasterCard", StringComparison.InvariantCultureIgnoreCase)
              && p.IsAvailable);
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_MasterCard");

            isAvailable = allPaymentMethods.Exists(p =>
              string.Equals(p.UniqueName, "MoneyMatrix_Dankort", StringComparison.InvariantCultureIgnoreCase)
              && p.IsAvailable);
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_Dankort");

            isAvailable = allPaymentMethods.Exists(p =>
             string.Equals(p.UniqueName, "MoneyMatrix_InPay", StringComparison.InvariantCultureIgnoreCase)
             && p.IsAvailable);
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_InPay");

            isAvailable = allPaymentMethods.Exists(p =>
               string.Equals(p.UniqueName, "MoneyMatrix_Paysera_Wallet", StringComparison.InvariantCultureIgnoreCase)
               && p.IsAvailable);
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_Paysera_Wallet");

            isAvailable = allPaymentMethods.Exists(p =>
               string.Equals(p.UniqueName, "MoneyMatrix_Paysera_BankTransfer", StringComparison.InvariantCultureIgnoreCase)
               && p.IsAvailable);
            if (isAvailable)
                paymentMethodNames.Add("MoneyMatrix_Paysera_BankTransfer");

            var paymentMethods = paymentMethodNames.Select(n => allPaymentMethods.FirstOrDefault(p =>
                string.Equals(p.UniqueName, n, StringComparison.InvariantCultureIgnoreCase)))
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
