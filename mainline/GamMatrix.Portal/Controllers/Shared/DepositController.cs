using System;
using System.Collections.Generic;
using System.Configuration;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Net;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Mvc;
using System.Xml.Linq;
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


    public sealed class TSIData
    {
        public string Code { get; set; }
        public string Amount { get; set; }
        public string Currency { get; set; }
    }
    public sealed class TSIInfo
    {
        public string Type { get; set; }
        public TSIData[] Vouchers { get; set; }
        //{"type" : "TSI", "vouchers" : [{"code" : "FR003874002445", "amount" : 15, "currency" : "EUR"}]}
    }

    public enum TransactionStatus
    {
        success,
        setup,
        error,
        pending,
        incomplete,
        redirection,
        instructions,
        cancel,
        unknown,
    }

    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{paymentMethodName}/{sid}")]
    public class DepositController : AsyncControllerEx
    {
        /// <summary>
        ///  The list view
        /// </summary>
        /// <returns></returns>
        [HttpGet]
        public virtual ActionResult Index()
        {
            return View("Index");
        }

        [HttpGet]
        public virtual ActionResult ConciseIndex()
        {
            return View("ConciseIndex");
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult PaymentMethodListView(int country, string currency)
        {
            return this.PartialView("PaymentMethodList", this.ViewData.Merge(new { @CountryID = country, @Currency = currency }));
        }

        /// <summary>
        /// The prepare view
        /// </summary>
        /// <param name="paymentMethodName"></param>
        /// <returns></returns>
        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        public virtual ActionResult Prepare(string paymentMethodName)
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return View("Anonymous");

            UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
            cmUser user = ua.GetByID(CustomProfile.Current.UserID);

            if (!user.IsEmailVerified)
                return View("EmailNotVerified");
            // if the profile is uncompleted, redirect user to profile page
            if (string.IsNullOrWhiteSpace(user.Address1) ||
                string.IsNullOrWhiteSpace(user.Zip) ||
                string.IsNullOrWhiteSpace(user.Mobile) ||
                string.IsNullOrWhiteSpace(user.SecurityQuestion) ||
                string.IsNullOrWhiteSpace(user.SecurityAnswer) ||
                string.IsNullOrWhiteSpace(user.City) ||
                string.IsNullOrWhiteSpace(user.Title) ||
                string.IsNullOrWhiteSpace(user.FirstName) ||
                string.IsNullOrWhiteSpace(user.Surname) ||
                string.IsNullOrWhiteSpace(user.Currency) ||
                string.IsNullOrWhiteSpace(user.Language) ||
                user.CountryID <= 0 ||
                !user.Birth.HasValue ||
                CustomProfile.Current.IsInRole("Incomplete Profile"))
            {
                return View("IncompleteProfile");
            }

            else if (!CustomProfile.Current.IsEmailVerified)
                CustomProfile.Current.IsEmailVerified = true;

            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
                .FirstOrDefault(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.InvariantCultureIgnoreCase));
            if (paymentMethod == null)
                throw new ArgumentOutOfRangeException();

            //check the payment method
            if (!CheckPaymentMethod(paymentMethod))
                return View("BankNotSupport");
            if (Regex.IsMatch(Metadata.Get("Metadata/Settings/Deposit.AstroPayCard_Ignore_DenyDepositCardRole").DefaultIfNullOrWhiteSpace("NO"), @"(YES)|(ON)|(OK)|(TRUE)|(\1)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled))
            {
                if (CustomProfile.Current.IsInRole(paymentMethod.DenyAccessRoleNames)
                    && !(paymentMethod.UniqueName == "AstroPayCard" && !CustomProfile.Current.IsInRole(paymentMethod.DenyAccessRoleNames.Where(r => !r.Equals("Deny Card Deposit", StringComparison.InvariantCultureIgnoreCase)).ToArray())))
                    return View("AccessDenied");
            }
            else
            {
                if (CustomProfile.Current.IsInRole(paymentMethod.DenyAccessRoleNames))
                    return View("AccessDenied");
            }

            if (CustomProfile.Current.IsInRole("Withdraw only"))
                return View("GamblingRegulationsRestriction");

            if (paymentMethod.SimultaneousDepositLimit > 0)
            {
                if (paymentMethod.SimultaneousDepositLimit <= GamMatrixClient.GetPendingDepositCount(paymentMethod.VendorID, CustomProfile.Current.UserID))
                    return View("SimultaneousDepositDenied");
            }

            switch (paymentMethod.VendorID)
            {

                case VendorID.PaymentTrust:
                    if (string.Equals(paymentMethodName, "PT_VISA_TicketSurf", StringComparison.InvariantCultureIgnoreCase)
                            || string.Equals(paymentMethodName, "PT_MasterCard_TicketSurf", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "TicketTurfDirectPaymentPayCard";
                    }
                    else if (string.Equals(paymentMethodName, "Epro", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "EproPayCard";
                    }
                    else
                        this.ViewData["PayCardView"] = "PaymentTrustPayCard";

                    return View("Prepare", paymentMethod);

                case VendorID.Moneybookers:
                    if (string.Equals("Moneybookers_1Tap", paymentMethod.UniqueName, StringComparison.InvariantCultureIgnoreCase))
                        this.ViewData["PayCardView"] = "Moneybookers1TapPayCard";
                    else
                        this.ViewData["PayCardView"] = "MoneybookersPayCard";
                    return View("Prepare", paymentMethod);

                case VendorID.Neteller:
                    this.ViewData["PayCardView"] = "NetellerPayCard";
                    return View("Prepare", paymentMethod);

                case VendorID.Bank:
                    return View("PrepareBank", paymentMethod);

                case VendorID.Envoy:
                    return View("PrepareEnvoy", paymentMethod);

                case VendorID.Paysafecard:
                    this.ViewData["PayCardView"] = "PaySafeCardPayCard";
                    return View("Prepare", paymentMethod);

                case VendorID.PayGE:
                    this.ViewData["PayCardView"] = "PayGEPayCard";
                    return View("PrepareWithoutConfirmation", paymentMethod);

                case VendorID.ToditoCard:
                    this.ViewData["PayCardView"] = "ToditoCardPayCard";
                    return View("Prepare", paymentMethod);

                case VendorID.Ukash:
                    this.ViewData["PayCardView"] = "UkashPayCard";
                    return View("Prepare", paymentMethod);

                case VendorID.BoCash:
                    this.ViewData["PayCardView"] = "BoCashPayCard";
                    return View("Prepare", paymentMethod);

                case VendorID.Voucher:
                    this.ViewData["PayCardView"] = "VoucherPayCard";
                    return View("Prepare", paymentMethod);

                case VendorID.Dotpay:
                    this.ViewData["PayCardView"] = "DotpayPayCard";
                    return View("Prepare", paymentMethod);

                case VendorID.Intercash:
                    this.ViewData["PayCardView"] = "IntercashPayCard";
                    return View("Prepare", paymentMethod);

                case VendorID.DotpaySMS:
                    return View("PrepareDotpaySMS", paymentMethod);

                case VendorID.EcoCard:
                    this.ViewData["PayCardView"] = "EcoCardPayCard";
                    return View("Prepare", paymentMethod);

                case VendorID.Trustly:
                    this.ViewData["PayCardView"] = "TrustlyPayCard";
                    return View("Prepare", paymentMethod);

                case VendorID.ICEPAY:
                    if (string.Equals(paymentMethod.UniqueName, "ICEPAY_SMS", StringComparison.InvariantCultureIgnoreCase))
                        this.ViewData["PayCardView"] = "ICEPAYSMSPayCard";
                    else
                        this.ViewData["PayCardView"] = "ICEPAYPayCard";
                    return View("Prepare", paymentMethod);

                case VendorID.GeorgianCard:
                    this.ViewData["PayCardView"] = "GeorgianCardPayCard";
                    return View("PrepareWithoutConfirmation", paymentMethod);

                case VendorID.ArtemisSMS:
                    return View("PrepareArtemisSMS", paymentMethod);

                case VendorID.TurkeySMS:
                    return View("PrepareTurkeySMS", paymentMethod);

                case VendorID.TurkeyBankWire:
                    return View("PrepareTurkeyBankWire", paymentMethod);

                case VendorID.TLNakit:
                    this.ViewData["PayCardView"] = "TLNakitPayCard";
                    return View("Prepare", paymentMethod);

                case VendorID.PayAnyWay:
                    this.ViewData["PayCardView"] = "PayAnyWayPayCard";
                    return View("Prepare", paymentMethod);

                case VendorID.IPSToken:
                    this.ViewData["PayCardView"] = "IPSTokenPayCard";
                    //return View("Prepare", paymentMethod);
                    return View("PrepareIPSToken", paymentMethod);

                case VendorID.EnterCash:
                    this.ViewData["PayCardView"] = "EnterCashPayCard";
                    return View("Prepare", paymentMethod);

                case VendorID.LocalBank:
                    this.ViewData["PayCardView"] = "LocalBankPayCard";
                    return View("PrepareLocalBank", paymentMethod);


                case VendorID.Euteller:
                    this.ViewData["PayCardView"] = "EutellerPayCard";
                    return View("Prepare", paymentMethod);

                case VendorID.UiPas:
                    this.ViewData["PayCardView"] = "UiPasPayCard";
                    return View("Prepare", paymentMethod);

                case VendorID.InPay:
                    this.ViewData["PayCardView"] = "InPayPayCard";
                    return View("PrepareInPay", paymentMethod);

                case VendorID.IPG:
                    this.ViewData["PayCardView"] = "IPGPayCard";
                    return View("Prepare", paymentMethod);

                case VendorID.APX:
                    this.ViewData["PayCardView"] = "APXPayCard";
                    return View("Prepare", paymentMethod);

                case VendorID.GCE:
                    this.ViewData["PayCardView"] = "GCEPayCard";
                    return View("Prepare", paymentMethod);

                case VendorID.AstroPay:
                    this.ViewData["PayCardView"] = "AstroPayPayCard";
                    return View("Prepare", paymentMethod);

                case VendorID.PugglePay:
                    this.ViewData["PayCardView"] = "PugglePayPayCard";
                    return View("Prepare", paymentMethod);

                case VendorID.PaymentInside:
                    this.ViewData["PayCardView"] = "PaymentInsidePayCard";
                    return View("Prepare", paymentMethod);
                    
                case VendorID.TxtNation:
                    this.ViewData["PayCardView"] = "TxtNationPayCard";
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
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Epro_Cashlib", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Epro_CashlibPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_PayKasa", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_PayKasaPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_PayKwik", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_PayKwikPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Ochapay", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_OchapayPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_OtoPay", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_OtoPayPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_IBanq", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_IBanqPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_GPaySafe_Visa", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_GPaySafe_VisaPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_GPaySafe_Mastercard", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_GPaySafe_MastercardPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_GPaySafe_PayKasa", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_GPaySafe_PayKasaPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_GPaySafe_CashIxir", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_GPaySafe_CashIxirPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_GPaySafe_EPayCode", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_GPaySafe_EPayCodePayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_GPaySafe_GsCash", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_GPaySafe_GsCashPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_GPaySafe_Jeton", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_GPaySafe_JetonPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_GPaySafe_InstantBankTransfer", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_GPaySafe_InstantBankTransferPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_GPaySafe_CepBank", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_GPaySafe_CepBankPayCard";
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
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Skrill_1Tap", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Skrill_1Tap_PayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Zimpler", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_ZimplerPayCard";
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
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_Wallet", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Paysera_WalletPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_MedicinosBankas", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Paysera_MedicinosBankasPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_SiauliuBankas", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Paysera_SiauliuBankasPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_LithuanianCreditUnion", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Paysera_LithuanianCreditUnionPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_Dnb", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Paysera_DnbPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_CreditCards", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Paysera_CreditCardsPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_WebMoney", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Paysera_WebMoneyPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_InternationalPaymentInEuros", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Paysera_InternationalPaymentInEurosPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_SwedbankLithuania", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Paysera_SwedbankLithuaniaPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_SebLithuania", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Paysera_SebLithuaniaPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_NordeaLithuania", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Paysera_NordeaLithuaniaPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_CitadeleLithuania", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Paysera_CitadeleLithuaniaPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_DanskeLithuania", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Paysera_DanskeLithuaniaPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_Perlas", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Paysera_PerlasPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_SwedbankLatvia", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Paysera_SwedbankLatviaPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_SebLatvia", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Paysera_SebLatviaPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_NordeaLatvia", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Paysera_NordeaLatviaPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_CitadeleLatvia", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Paysera_CitadeleLatviaPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_SwedbankEstonia", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Paysera_SwedbankEstoniaPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_SebEstonia", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Paysera_SebEstoniaPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_DanskeEstonia", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Paysera_DanskeEstoniaPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_NordeaEstonia", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Paysera_NordeaEstoniaPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_Krediidipank", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Paysera_KrediidipankPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_LhvBank", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Paysera_LhvBankPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_BzwbkBank", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Paysera_BzwbkBankPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_PekaoBank", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Paysera_PekaoBankPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_PkoBank", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Paysera_PkoBankPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_mBank", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Paysera_PkoBankPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_AliorBank", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Paysera_AliorBankPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_Easypay", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Paysera_EasypayPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Adyen_Sofort", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Adyen_SofortPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Adyen_Giropay", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Adyen_GiropayPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Adyen_iDeal", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Adyen_iDealPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Adyen_ELV", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Adyen_ELVPayCard";
                    }
                    else if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Adyen_PayPal", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "MoneyMatrix_Adyen_PayPalPayCard";
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

                    return View("Prepare", paymentMethod);

                case GamMatrixAPI.VendorID.Click2Pay:
                case GamMatrixAPI.VendorID.ClickandBuy:
                case GamMatrixAPI.VendorID.QVoucher:
                case GamMatrixAPI.VendorID.NLB:
                    break;

                default:
                    throw new NotSupportedException();
            }

            throw new NotSupportedException();
        }

        protected bool CheckPaymentMethod(PaymentMethod paymentMethod)
        {
            if (Settings.Deposit_SkipPaymentMethodCheck)
                return true;

            PaymentMethod[] paymentMethods = PaymentMethodManager.GetPaymentMethods().ToArray();

            var query = paymentMethods.Where(p => p.IsAvailable &&
                                                  p.SupportDeposit &&
                                                  DomainConfigAgent.IsVendorEnabled(p));

            int countryID = CustomProfile.Current.UserCountryID;
            string currency = CustomProfile.Current.UserCurrency;

            if (countryID > 0)
                query = query.Where(p => p.SupportedCountries.Exists(countryID));

            //if (!string.IsNullOrWhiteSpace(currency))
            //    query = query.Where(p => p.SupportedCurrencies.Exists(currency));

            if (CustomProfile.Current.IsAuthenticated)
            {
                if (Regex.IsMatch(Metadata.Get("Metadata/Settings/Deposit.AstroPayCard_Ignore_DenyDepositCardRole").DefaultIfNullOrWhiteSpace("NO"), @"(YES)|(ON)|(OK)|(TRUE)|(\1)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled))
                {
                    query = query.Where(p => !CustomProfile.Current.IsInRole(p.DenyAccessRoleNames)
                        || (p.UniqueName == "AstroPayCard" && !CustomProfile.Current.IsInRole(p.DenyAccessRoleNames.Where(r => !r.Equals("Deny Card Deposit", StringComparison.InvariantCultureIgnoreCase)).ToArray())));
                }
                else
                {
                    query = query.Where(p => !CustomProfile.Current.IsInRole(p.DenyAccessRoleNames));
                }
            }

            var list = query.ToArray();

            var query2 = list.Where(p => p.RepulsivePaymentMethods == null ||
                p.RepulsivePaymentMethods.Count == 0 ||
                !p.RepulsivePaymentMethods.Exists(p2 => list.FirstOrDefault(p3 => p3.UniqueName == p2) != null)
                );

            paymentMethods = query2.ToArray();

            return paymentMethods.Contains(paymentMethod);
        }


        /// <summary>
        /// Register a paycard
        /// </summary>
        /// <param name="vendorID"></param>
        /// <param name="identityNumber"></param>
        /// <param name="ownerName"></param>
        /// <param name="validFrom"></param>
        /// <param name="expiryDate"></param>
        /// <returns></returns>
        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult RegisterPayCard(VendorID vendorID
            , string identityNumber
            , string ownerName
            , string validFrom
            , string expiryDate
            , string issueNumber
            , string bankName
            , string cardName
            , string cardSecurityCode = null)
        {
            if (!CustomProfile.Current.IsAuthenticated)
                throw new UnauthorizedAccessException();

            try
            {
                // limit the number of card
                if (vendorID == VendorID.Neteller)
                {
                    if (GamMatrixClient.GetPayCards(vendorID).Exists(c => c.ActiveStatus == ActiveStatus.Active))
                        throw new InvalidOperationException("Multi card is not allowed");
                }

                if (vendorID == VendorID.UiPas)
                {
                    const int MAX_CARDS = 1;
                    var payCards = GamMatrixClient.GetPayCards(VendorID.UiPas);
                    int count = payCards.Count(p => p.ActiveStatus == ActiveStatus.Active && !p.IsDummy);
                    if (count >= MAX_CARDS)
                        throw new InvalidOperationException(string.Format("You are only allowed to register at most {0} UiPas account.", MAX_CARDS));
                }

                if (vendorID == VendorID.TLNakit)
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

                DateTime temp;
                PayCardRec payCard = new PayCardRec();
                payCard.VendorID = vendorID;
                payCard.ActiveStatus = ActiveStatus.Active;
                payCard.UserID = CustomProfile.Current.UserID;
                payCard.IssueNumber = issueNumber;
                payCard.BankName = bankName;
                payCard.CardName = cardName;

                if (!string.IsNullOrWhiteSpace(identityNumber))
                {
                    payCard.IdentityNumber = identityNumber;
                }

                // for payment methods except CC, indicate the DisplayName and DisplayNumber
                if (vendorID != VendorID.PaymentTrust &&
                    vendorID != VendorID.PayPoint &&
                    vendorID != VendorID.DirectPayment &&
                    vendorID != VendorID.Skrill
                    //&& 
                    // vendorID != VendorID.Citigate
                    )
                {
                    payCard.DisplayName = identityNumber;
                    payCard.DisplayNumber = identityNumber;
                }
                else
                {
                    payCard.VendorID = VendorID.PaymentTrust;
                }

                if (vendorID == VendorID.MoneyMatrix)
                {
                    payCard.BrandType = Request["cardType"];
                    payCard.IssuerCompany = Request["IssuerCompany"];
                    payCard.IssuerCountry = Request["IssuerCountry"];

                    var displayNumber = Request["displayNumber"];

                    if (!string.IsNullOrEmpty(displayNumber))
                    {
                        payCard.DisplayNumber = identityNumber;
                        payCard.DisplayName = displayNumber;
                    }
                }

                if (!string.IsNullOrWhiteSpace(ownerName))
                    payCard.OwnerName = ownerName;

                if (!string.IsNullOrWhiteSpace(validFrom) &&
                    DateTime.TryParseExact(validFrom, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out temp))
                    payCard.ValidFrom = temp;

                if (!string.IsNullOrWhiteSpace(expiryDate) &&
                    DateTime.TryParseExact(expiryDate, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out temp))
                    payCard.ExpiryDate = temp;

                Dictionary<string, string> requestDynamicFields = null;

                if (vendorID == VendorID.AstroPay)
                {
                    requestDynamicFields = new Dictionary<string, string> { { "cvv", cardSecurityCode } };
                }

                if (vendorID == VendorID.APX)
                {
                    UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                    cmUser user = ua.GetByID(CustomProfile.Current.UserID);
                    string birthDay = user.Birth.HasValue ? user.Birth.Value.ToShortDateString() : "";
                    requestDynamicFields = new Dictionary<string, string>
                    {
                        { "birth_date", birthDay },
                        { "phone_num", user.Phone }
                    };
                }

                long newPayCardID = GamMatrixClient.RegisterPayCard(payCard, requestDynamicFields);

                return this.Json(new { @success = true, @payCardID = newPayCardID.ToString() });
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = ex.Message });
            }
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult RegisterLocalBankPayCard(VendorID vendorID
            , string bankName
            , string nameOnAccount
            , string citizenID
            , string bankAccountNo
            )
        {
            if (string.IsNullOrWhiteSpace(bankName)
                || string.IsNullOrWhiteSpace(nameOnAccount)
                || (string.IsNullOrWhiteSpace(citizenID) && string.IsNullOrWhiteSpace(bankAccountNo)))
                throw new ArgumentException();

            if (!CustomProfile.Current.IsAuthenticated)
                throw new UnauthorizedAccessException();

            string[] bankPaths = Metadata.GetChildrenPaths("Metadata/PaymentMethod/LocalBank/Bank/" + CustomProfile.Current.UserCountryID);
            if (bankPaths == null || bankPaths.Length == 0)
                throw new InvalidOperationException("There is no bank for your country.");

            string displayNumber = string.Empty;
            string identityNumber = string.Empty;
            if (CustomProfile.Current.UserCountryID == 217) //Thailand
            {
                displayNumber = bankAccountNo;
                identityNumber = citizenID;
            }
            if (CustomProfile.Current.UserCountryID == 223) // Turkey
            {
                displayNumber = citizenID;
                identityNumber = citizenID;
            }
            else if (CustomProfile.Current.UserCountryID == 51 || CustomProfile.Current.UserCountryID == 202) // China or Korea
            {
                displayNumber = bankAccountNo;
                identityNumber = bankAccountNo;
            }
            else if (CustomProfile.Current.UserCountryID == 183) // Russia
            {
                displayNumber = bankAccountNo;
                identityNumber = bankAccountNo;
            }

            List<PayCardInfoRec> payCards = GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.LocalBank);

            if (payCards.Exists(p => p.OwnerName.Equals(nameOnAccount, StringComparison.InvariantCultureIgnoreCase)
                && p.BankName.Equals(bankName, StringComparison.InvariantCultureIgnoreCase)
                && (p.BankAccountNo.Equals(citizenID, StringComparison.InvariantCultureIgnoreCase) || p.BankAccountNo.Equals(bankAccountNo, StringComparison.InvariantCultureIgnoreCase))))
            {
                return this.Json(new { @success = false, @error = "Multi card with same details is not allowed" });
            }

            var MAX_ACCOUNTS = 3;
            int count = payCards.Count(p => p.ActiveStatus == ActiveStatus.Active && !p.IsDummy);
            if (count >= MAX_ACCOUNTS)
                return this.Json(new { @success = false, @error = string.Format("You are only allowed to register {0} bank accounts total.", MAX_ACCOUNTS) });

            PayCardRec payCard = new PayCardRec();
            payCard.VendorID = vendorID;
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

            return this.Json(new { @success = true, @payCardID = newPayCardID.ToString() });
        }
        #region


        private JsonResult IovationCheck(string iovationBlackBox)
        {
            if (!CustomProfile.Current.IsAuthenticated || !Settings.IovationDeviceTrack_Enabled)
                return null;

            string error = null;
            //if (string.IsNullOrEmpty(iovationBlackBox))
            //{
            //    error = GamMatrixClient.GetIovationError(eventType: IovationEventType.Deposit);
            //    //"iovationBlackBox requreid !";
            //}
            //else
            //{
                if (!GamMatrixClient.IovationCheck(CustomProfile.Current.UserID, IovationEventType.Deposit, iovationBlackBox))
                {
                    error = GamMatrixClient.GetIovationError(false, IovationEventType.Deposit);
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

        /// <summary>
        /// Prepare the transaction
        /// </summary>
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
            , string bonusCode
            , string bonusVendor
            , string issuer
            , string paymentType
            , string tempExternalReference
            , string iovationBlackBox = null
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

            var iovationResult = IovationCheck(iovationBlackBox);
            if (iovationResult != null)
            {
                //deny ,return ;
                AsyncManager.Parameters["iovationResult"] = iovationResult;
                return; 
            }

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
                            IovationBlackBox = iovationBlackBox,
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



                        // for MB and Dotpay, pass the sub code
                        if (paymentMethod.VendorID == VendorID.Moneybookers ||
                            paymentMethod.VendorID == VendorID.Dotpay ||
                            paymentMethod.VendorID == VendorID.PayAnyWay)
                        {
                            if (!string.IsNullOrEmpty(paymentMethod.SubCode))
                            {
                                prepareTransRequest.PaymentMethods = new List<string>() { paymentMethod.SubCode };
                            }
                        }

                        if (paymentMethod.VendorID == VendorID.EnterCash)
                        {
                            if (!string.IsNullOrEmpty(paymentMethod.SubCode))
                            {
                                if (paymentMethod.UniqueName == "EnterCash_OnlineBank")
                                {
                                    if (CustomProfile.Current.UserCountryID == 79) // FI
                                        prepareTransRequest.PaymentMethods = new List<string>() { "BUTTON" };
                                    else if (CustomProfile.Current.UserCountryID == 211) // SE
                                        prepareTransRequest.PaymentMethods = new List<string>() { "REFCODE" };
                                }
                                else
                                    prepareTransRequest.PaymentMethods = new List<string>() { paymentMethod.SubCode };
                            }
                        }

                        // for ICE, paymentType
                        if (paymentMethod.VendorID == VendorID.ICEPAY)
                        {
                            switch (paymentMethod.UniqueName)
                            {
                                case "ICEPAY_IDeal":
                                    prepareTransRequest.Record.PaymentType = ICEPAYService.IDEAL.ToString();
                                    prepareTransRequest.PaymentMethods = new List<string>() { issuer };
                                    break;

                                case "ICEPAY_AMEX":
                                case "ICEPAY_MASTER":
                                case "ICEPAY_VISA":
                                    prepareTransRequest.Record.PaymentType = ICEPAYService.CREDITCARD.ToString();
                                    prepareTransRequest.PaymentMethods = new List<string>() { paymentMethod.SubCode };
                                    break;

                                case "ICEPAY_PAYPAL":
                                    prepareTransRequest.Record.PaymentType = ICEPAYService.PAYPAL.ToString();
                                    break;

                                case "ICEPAY_PAYSAFECARD":
                                    prepareTransRequest.Record.PaymentType = ICEPAYService.PAYSAFECARD.ToString();
                                    break;

                                case "ICEPAY_MISTERCASH":
                                    prepareTransRequest.Record.PaymentType = ICEPAYService.MISTERCASH.ToString();
                                    break;

                                case "ICEPAY_GIROPAY":
                                    prepareTransRequest.Record.PaymentType = ICEPAYService.GIROPAY.ToString();
                                    break;

                                case "ICEPAY_DDEBIT":
                                    prepareTransRequest.Record.PaymentType = ICEPAYService.DDEBIT.ToString();
                                    break;

                                case "ICEPAY_WIRE":
                                    prepareTransRequest.Record.PaymentType = ICEPAYService.WIRE.ToString();
                                    break;

                                case "ICEPAY_SMS":
                                    prepareTransRequest.Record.PaymentType = ICEPAYService.SMS.ToString();
                                    break;

                                case "ICEPAY_DIRECTEBANK":
                                    prepareTransRequest.Record.PaymentType = ICEPAYService.DIRECTEBANK.ToString();
                                    break;

                                default:
                                    prepareTransRequest.Record.PaymentType = ICEPAYService.PBAR.ToString();
                                    break;
                            }
                        }

                        if (paymentMethod.VendorID == VendorID.PugglePay)
                        {
                            if (prepareTransRequest.RequestFields == null)
                                prepareTransRequest.RequestFields = new Dictionary<string, string>();
                            prepareTransRequest.RequestFields.Add("user_message", Settings.PugglePay_UserMessage);
                        }

                        if (paymentMethod.VendorID == VendorID.MoneyMatrix)
                        {
                            prepareTransRequest.PaymentMethods = new List<string> { paymentMethod.SubCode };

                            if (prepareTransRequest.RequestFields == null)
                            {
                                prepareTransRequest.RequestFields = new Dictionary<string, string>();
                            }

                            prepareTransRequest.RequestFields["UserAgent"] = Request.UserAgent;
                            prepareTransRequest.RequestFields["AcceptHeader"] = string.Join(",", Request.AcceptTypes);

                            if (paymentMethod.SubCode == "PayKasa" || paymentMethod.SubCode == "OtoPay")
                            {
                                prepareTransRequest.RequestFields["VoucherCode"] = Request["VoucherCode"];
                            }

                            if (paymentMethod.SubCode == "CreditCard")
                            {
                                prepareTransRequest.RequestFields["MonitoringSessionId"] = Request["MonitoringSessionId"];
                            }

                            if (paymentMethod.SubCode == "Skrill")
                            {
                                prepareTransRequest.RequestFields["SkrillEmailAddress"] = Request["SkrillEmailAddress"];
                                prepareTransRequest.RequestFields["SkrillReSetupOneTap"] = Request["SkrillReSetupOneTap"];
                                prepareTransRequest.RequestFields["SkrillUseOneTap"] = Request["SkrillUseOneTap"];
                            }

                            if (paymentMethod.SubCode == "TlNakit")
                            {
                                prepareTransRequest.RequestFields["TlNakitCardNumber"] = Request["TlNakitCardNumber"];
                            }

                            if (paymentMethod.SubCode == "Offline.Nordea" || paymentMethod.SubCode == "Offline.LocalBank")
                            {
                                var paymentMethodDetails = GamMatrixClient.GetPaymentSolutionDetails(paymentMethod.SubCode);
                                foreach (var field in paymentMethodDetails.Metadata.Fields.Where(f => f.ForDeposit && f.RequiresUserInput))
                                {
                                    prepareTransRequest.RequestFields[field.Key] = Request[field.Key];
                                }
                            }

                            if (paymentMethod.SubCode == "OtoPay")
                            {
                                prepareTransRequest.RequestFields["SecurityKey"] = Request["SecurityKey"];
                            }

                            if (paymentMethod.SubCode == "Neteller")
                            {
                                prepareTransRequest.RequestFields["NetellerEmailAddressOrAccountId"] = Request["NetellerEmailAddressOrAccountId"];
                                prepareTransRequest.RequestFields["NetellerSecret"] = Request["NetellerSecret"];
                            }

                            if (paymentMethod.SubCode == "i-Banq")
                            {
                                prepareTransRequest.RequestFields["BanqUserId"] = Request["BanqUserId"];
                                prepareTransRequest.RequestFields["BanqUserPassword"] = Request["BanqUserPassword"];
                            }

                            if (paymentMethod.SubCode == "PPro.Sofort")
                            {
                                prepareTransRequest.RequestFields["BankSwiftCode"] = Request["BankSwiftCode"];
                            }
                            
                            if (paymentMethod.SubCode == "PPro.GiroPay")
                            {
                                prepareTransRequest.RequestFields["BankSwiftCode"] = Request["BankSwiftCode"];
                            }

                            if (paymentMethod.SubCode == "PPro.Boleto")
                            {
                                prepareTransRequest.RequestFields["PProBoletoNationalId"] = Request["PProBoletoNationalId"];
                                prepareTransRequest.RequestFields["PProBoletoEmail"] = Request["PProBoletoEmail"];
                                prepareTransRequest.RequestFields["PProBoletoBirthDate"] = Request["PProBoletoBirthDate"];
                            }

                            if (paymentMethod.SubCode == "PPro.Qiwi")
                            {
                                prepareTransRequest.RequestFields["PProQiwiMobilePhone"] = Request["PProQiwiMobilePhone"];
                            }

                            if (paymentMethod.SubCode == "PPro.Przelewy24")
                            {
                                prepareTransRequest.RequestFields["PProPrzelewy24Email"] = Request["PProPrzelewy24Email"];
                            }
                        }

                        GamMatrixClient.SingleRequestAsync<PrepareTransRequest>(prepareTransRequest
                            , OnPrepareTransactionCompleted
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
            , PaymentMethod paymentMethod
            , JsonResult iovationResult = null
            )
        {
            if (iovationResult != null)
                return iovationResult;

            try
            {
                if (string.Compare("1", AsyncManager.Parameters["outRange"].ToString(), false) == 0)
                {
                    return this.Json(new
                    {
                        @success = false,
                        @error = "OUTRANGE",
                    });
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
                bool showTC = prepareTransRequest.IsFirstDepositBonusAvailableAndRequireTC;
                if (showTC)
                {
                    string cookieName = string.Format("GM_{0}", gammingAccountID);
                    HttpCookie cookie = Request.Cookies[cookieName];
                    if (cookie != null && !string.IsNullOrWhiteSpace(cookie.Value))
                    {
                        bool accepted = true;
                        if (bool.TryParse(cookie.Value, out accepted))
                        {
                            cmTransParameter.SaveObject<bool>(prepareTransRequest.Record.Sid, "BonusAccepted", accepted);
                            showTC = false;
                        }
                    }
                }
                return this.Json(new
                {
                    @success = true,
                    @sid = prepareTransRequest.Record.Sid,
                    @showTC = showTC
                });
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
        #endregion PrepareTransaction

        #region IPSToken
        public void ProcessIPSTokenTransactionAsync(string paymentMethodName
            , long gammingAccountID
            , long payCardID
            , string token
            , string checkDigit
            , string iovationBlackBox = null
            )
        {
            var iovationResult = IovationCheck(iovationBlackBox);
            if (iovationResult != null)
            {
                AsyncManager.Parameters["iovationResult"] = iovationResult;
                return;
            }
            AsyncManager.Parameters["paymentMethodName"] = paymentMethodName;
            AsyncManager.Parameters["gammingAccountID"] = gammingAccountID;
            AsyncManager.Parameters["payCardID"] = payCardID;
            AsyncManager.Parameters["token"] = token;
            AsyncManager.Parameters["checkDigit"] = checkDigit;

            IPSTokenDepositNoAmountRequest request = new IPSTokenDepositNoAmountRequest();
            request.AccountId = gammingAccountID;
            request.CheckDigit = checkDigit;
            request.TokenNumber = token;
            request.UserID = CustomProfile.Current.UserID;
            request.PaycardId = payCardID;

            GamMatrixClient.SingleRequestAsync<IPSTokenDepositNoAmountRequest>(request, OnProcessIPSTokenTransactionCompleted);
            AsyncManager.OutstandingOperations.Increment();
        }

        private void OnProcessIPSTokenTransactionCompleted(AsyncResult reply)
        {
            try
            {
                AsyncManager.Parameters["requestIPSTokenDepositNoAmount"] = reply.EndSingleRequest().Get<IPSTokenDepositNoAmountRequest>();
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


        public JsonResult ProcessIPSTokenTransactionCompleted(IPSTokenDepositNoAmountRequest requestIPSTokenDepositNoAmount
            , Exception exception
            , string paymentMethodName
            , long gammingAccountID
            , long payCardID
            , PaymentMethod paymentMethod
            , JsonResult iovationResult = null
            )
        {
            if (iovationResult != null)
                return iovationResult;

            try
            {
                if (!CustomProfile.Current.IsAuthenticated)
                    throw new UnauthorizedAccessException();

                if (exception != null)
                    throw exception;

                if (!requestIPSTokenDepositNoAmount.ResponseStatus)
                {
                    return this.Json(new
                    {
                        @success = false,
                        @responseStatus = false,
                    });
                }

                string receiptUrl = this.Url.RouteUrlEx("Deposit", new { @action = "IPSTokenReceipt", @paymentMethodName = paymentMethodName, @sid = requestIPSTokenDepositNoAmount.Sid });

                //string cacheKey = string.Format("{0}_DepositReceiptUrl", CustomProfile.Current.SessionID);
                CustomProfile.Current.Set("ReceiptUrl", receiptUrl);

                cmTransParameter.SaveObject<IPSTokenDepositNoAmountRequest>(requestIPSTokenDepositNoAmount.Sid
                    , "IPSTokenDepositNoAmountRequest"
                    , requestIPSTokenDepositNoAmount
                    );
                cmTransParameter.SaveObject<string>(requestIPSTokenDepositNoAmount.Sid
                    , "UserID"
                    , CustomProfile.Current.UserID.ToString()
                    );
                cmTransParameter.SaveObject<string>(requestIPSTokenDepositNoAmount.Sid
                    , "SessionID"
                    , CustomProfile.Current.SessionID
                    );

                return this.Json(new
                {
                    @success = true,
                    @sid = requestIPSTokenDepositNoAmount.Sid,
                    @receiptUrl = receiptUrl,
                    @responseStatus = true,
                });
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
        #endregion IPSToken

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult ProcessArtemisSMSTransaction(string paymentMethodName
            , long gammingAccountID
            , string currency
            , string amount
            , string senderPhoneNumber
            , string receiverPhoneNumber
            , string receiverBirthDate
            , string password
            , string referenceNumber
            , string senderTCNumber
            , string receiverTCNumber
            , bool? acceptBonus
            , string iovationBlackBox = null
            )
        {
            if (!CustomProfile.Current.IsAuthenticated)
                throw new UnauthorizedAccessException();

            var iovResult = IovationCheck(iovationBlackBox);
            if (iovResult != null)
                return iovResult;

            SetBonusDefaultOption(acceptBonus.HasValue && acceptBonus.Value);

            decimal requestAmount = decimal.Parse(Regex.Replace(amount, @"[^\d\.]", string.Empty), CultureInfo.InvariantCulture);

            using (GamMatrixClient client = GamMatrixClient.Get())
            {

                ArtemisSMSRec card = new ArtemisSMSRec()
                {
                    TransType = TransType.Deposit,
                    AccountID = gammingAccountID,
                    Amount = requestAmount,
                    Currency = currency,
                    UserID = CustomProfile.Current.UserID,
                    SenderPhoneNumber = senderPhoneNumber,
                    ReceiverPhoneNumber = receiverPhoneNumber,
                    Password = password,
                    ReferenceNumber = referenceNumber,
                    SenderTCNumber = senderTCNumber,
                    ReceiverTCNumber = receiverTCNumber,
                };

                DateTime receiverBirthday;
                if (DateTime.TryParseExact(receiverBirthDate, "dd/MM/yyyy", CultureInfo.InvariantCulture, DateTimeStyles.None, out receiverBirthday))
                {
                    card.ReceiverBirthDate = receiverBirthday;
                }

                switch (paymentMethodName)
                {
                    case "ArtemisSMS_Garanti": card.PaymentMethod = ArtemisSMSPaymentMethod.GARANT; break;
                    case "ArtemisSMS_Akbank": card.PaymentMethod = ArtemisSMSPaymentMethod.AKBANK; break;
                    case "ArtemisSMS_Isbank": card.PaymentMethod = ArtemisSMSPaymentMethod.ISBANK; break;
                    case "ArtemisSMS_YapiKredi": card.PaymentMethod = ArtemisSMSPaymentMethod.YapiKredi; break;
                    default: throw new ArgumentException("paymentMethodName");
                }
                ArtemisSMSPaymentRequest request = new ArtemisSMSPaymentRequest() { Payment = card };

                request = client.SingleRequest<ArtemisSMSPaymentRequest>(request);
            }

            return this.Json(new { @success = true });
        }


        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult ProcessTurkeySMSTransaction(string paymentMethodName
            , long gammingAccountID
            , string currency
            , string amount
            , string senderPhoneNumber
            , string receiverPhoneNumber
            , string receiverBirthDate
            , string password
            , string referenceNumber
            , string senderTCNumber
            , string receiverTCNumber
            , bool? acceptBonus
            , string iovationBlackBox = null
            )
        {
            if (!CustomProfile.Current.IsAuthenticated)
                throw new UnauthorizedAccessException();

            var iovResult = IovationCheck(iovationBlackBox);
            if (iovResult != null)
                return iovResult;

            SetBonusDefaultOption(acceptBonus.HasValue && acceptBonus.Value);

            decimal requestAmount = decimal.Parse(Regex.Replace(amount, @"[^\d\.]", string.Empty), CultureInfo.InvariantCulture);

            using (GamMatrixClient client = GamMatrixClient.Get())
            {
                TurkeySMSRec card = new TurkeySMSRec()
                {
                    TransType = TransType.Deposit,
                    AccountID = gammingAccountID,
                    Amount = requestAmount,
                    Currency = currency,
                    UserID = CustomProfile.Current.UserID,
                    SenderPhoneNumber = senderPhoneNumber,
                    ReceiverPhoneNumber = receiverPhoneNumber,
                    Password = password,
                    ReferenceNumber = referenceNumber,
                    SenderTCNumber = senderTCNumber,
                    ReceiverTCNumber = receiverTCNumber,
                };

                DateTime receiverBirthday;
                if (DateTime.TryParseExact(receiverBirthDate, "dd/MM/yyyy", CultureInfo.InvariantCulture, DateTimeStyles.None, out receiverBirthday))
                {
                    card.ReceiverBirthDate = receiverBirthday;
                }

                switch (paymentMethodName)
                {
                    case "TurkeySMS_Garanti": card.PaymentMethod = TurkeySMSPaymentMethod.GARANT; break;
                    case "TurkeySMS_Yapikredi": card.PaymentMethod = TurkeySMSPaymentMethod.YAPI; break;
                    case "TurkeySMS_Akbank": card.PaymentMethod = TurkeySMSPaymentMethod.AKBANK; break;
                    case "TurkeySMS_Isbank": card.PaymentMethod = TurkeySMSPaymentMethod.ISBANK; break;
                    //case "TurkeySMS_Havalesi": card.PaymentMethod = TurkeySMSPaymentMethod.HAVALESI; break;
                    default: throw new ArgumentException("paymentMethodName");
                }
                TurkeySMSPaymentRequest request = new TurkeySMSPaymentRequest() { Payment = card };

                request = client.SingleRequest<TurkeySMSPaymentRequest>(request);
            }

            return this.Json(new { @success = true });
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult ProcessTurkeyBankWireTransaction(string paymentMethodName
            , long gammingAccountID
            , string currency
            , string amount
            , string fullname
            , string citizenID
            , TurkeyBankWirePaymentMethod paymentMethod
            , string transactionID
            , string iovationBlackBox = null
            )
        {
            if (!CustomProfile.Current.IsAuthenticated)
                throw new UnauthorizedAccessException();

            var iovResult = IovationCheck(iovationBlackBox);
            if (iovResult != null)
                return iovResult;

            decimal requestAmount = decimal.Parse(Regex.Replace(amount, @"[^\d\.]", string.Empty), CultureInfo.InvariantCulture);

            using (GamMatrixClient client = GamMatrixClient.Get())
            {

                TurkeyBankWireRec card = new TurkeyBankWireRec()
                {
                    AccountID = gammingAccountID,
                    Amount = requestAmount,
                    Currency = currency,
                    UserID = CustomProfile.Current.UserID,
                    PaymentMethod = paymentMethod,
                    FullName = fullname,
                    CitizenID = citizenID,
                    TransactionID = transactionID,
                };


                TurkeyBankWirePaymentRequest request = new TurkeyBankWirePaymentRequest() { Payment = card };

                request = client.SingleRequest<TurkeyBankWirePaymentRequest>(request);
            }

            return this.Json(new { @success = true });
        }



        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult ProcessDotpaySMSTransaction(string paymentMethodName, long gammingAccountID, string smsCode, string captcha, string iovationBlackBox = null)
        {
            if (!CustomProfile.Current.IsAuthenticated)
                throw new UnauthorizedAccessException();
            var iovResult = IovationCheck(iovationBlackBox);
            if (iovResult != null)
                return iovResult;
            try
            {
                string captchaToCompare = null;

                captchaToCompare = CustomProfile.Current.Get("captcha");
                CustomProfile.Current.Set("captcha", null);

                if (!string.Equals(captcha.Trim(), captchaToCompare, StringComparison.InvariantCultureIgnoreCase))
                    throw new Exception(Metadata.Get("/Components/_Captcha_ascx.Captcha_Invalid"));

                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    DotpaySMSPaymentRequest dotpaySMSPaymentRequest = new DotpaySMSPaymentRequest()
                    {
                        UserID = CustomProfile.Current.UserID,
                        AccountID = gammingAccountID,
                        SmsCode = smsCode,
                    };
                    dotpaySMSPaymentRequest = client.SingleRequest<DotpaySMSPaymentRequest>(dotpaySMSPaymentRequest);

                    // for ordinary Dotpay SMS
                    if (string.Equals(paymentMethodName, "DotpaySMS", StringComparison.InvariantCultureIgnoreCase))
                    {
                        dotpaySMSPaymentRequest.PaymentMethods = new List<DotpaySMSPaymentMethod> { DotpaySMSPaymentMethod.COINS, DotpaySMSPaymentMethod.MONEYPACKAGE };
                    }
                    else if (string.Equals(paymentMethodName, "Dotpay_PlayCoins", StringComparison.InvariantCultureIgnoreCase))
                    {
                        dotpaySMSPaymentRequest.PaymentMethods = new List<DotpaySMSPaymentMethod> { DotpaySMSPaymentMethod.PLAYCOINS };
                    }
                    else
                    {
                        throw new Exception(string.Format("Unknown Dotpay SMS type : {0}", paymentMethodName));
                    }

                    PrepareTransRequest prepareTransRequest = new PrepareTransRequest()
                    {
                        Record = dotpaySMSPaymentRequest.Record,
                        IovationBlackBox = iovationBlackBox
                    };
                    cmTransParameter.SaveObject<PrepareTransRequest>(prepareTransRequest.Record.Sid, "PrepareTransRequest", prepareTransRequest);

                    ProcessTransRequest processTransRequest = new ProcessTransRequest()
                    {
                        Record = dotpaySMSPaymentRequest.Record,
                        TransRecord = dotpaySMSPaymentRequest.TransRecord,
                        IovationBlackBox = iovationBlackBox
                    };
                    processTransRequest.InputValue1 = cmTransParameter.Mask(prepareTransRequest.Record.Sid, "InputValue1", processTransRequest.InputValue1);
                    processTransRequest.InputValue2 = cmTransParameter.Mask(prepareTransRequest.Record.Sid, "InputValue2", processTransRequest.InputValue2);
                    processTransRequest.SecretKey = cmTransParameter.Mask(prepareTransRequest.Record.Sid, "SecurityKey", processTransRequest.SecretKey);
                    cmTransParameter.SaveObject<ProcessTransRequest>(prepareTransRequest.Record.Sid, "ProcessTransRequest", processTransRequest);
                    cmTransParameter.SaveObject<string>(prepareTransRequest.Record.Sid, "UserID", CustomProfile.Current.UserID.ToString());
                    cmTransParameter.SaveObject<string>(prepareTransRequest.Record.Sid, "SessionID", CustomProfile.Current.SessionID);
                    string url = this.Url.Action("Receipt", new { paymentMethodName = "DotpaySMS", sid = dotpaySMSPaymentRequest.Record.Sid });
                    SendReceiptEmail("DotpaySMS", dotpaySMSPaymentRequest.Record.Sid);
                    return this.Redirect(url);
                }
            }
            catch (Exception ex)
            {
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return this.View("Error");
            }
        }

        #region InPay
        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public void ProcessInPayTransactionAsync(string paymentMethodName
            , long gammingAccountID
            , string currency
            , string amount
            , long payCardID
            , string bonusCode
            , string bonusVendor
            , string issuer
            , string paymentType
            , string tempExternalReference
            , string inPayBankID
            , string iovationBlackBox = null
            )
        {
            var iovResult = IovationCheck(iovationBlackBox);
            if (iovResult != null)
            {
                AsyncManager.Parameters["iovationResult"] = iovResult;
                return;
            }
            try
            {
                int bankID;
                if (!int.TryParse(inPayBankID, out bankID))
                    throw new ArgumentNullException();

                var countries = InPayClient.GetInPayCountryAndBanks();
                var country = countries.FirstOrDefault(c => c.Banks.Any(b => b.ID == bankID));
                if (country == null)
                    throw new ArgumentNullException();

                var bank = country.Banks.FirstOrDefault(b => b.ID == bankID);
                if (bank == null)
                    throw new ArgumentNullException();

                AsyncManager.Parameters["inPayBank"] = bank;

                //use for process trans request
                AsyncManager.Parameters["postBackURL"] = this.Url.RouteUrlEx("Deposit", new { @action = "Postback", @paymentMethodName = paymentMethodName, @sid = "_SID_" });
                AsyncManager.Parameters["returnURL"] = this.Url.RouteUrlEx("Deposit", new { @action = "Return" });
                AsyncManager.Parameters["sessionID"] = GamMatrixClient.GetSessionIDForCurrentOperator();
                AsyncManager.Parameters["userID"] = CustomProfile.Current.UserID;
                AsyncManager.Parameters["userIP"] = global::System.Web.HttpContext.Current.Request.GetRealUserAddress();
                AsyncManager.Parameters["userSessionID"] = CustomProfile.Current.SessionID;

                PrepareInPayTransaction(paymentMethodName
                , gammingAccountID
                , currency
                , amount
                , payCardID
                , bonusCode
                , bonusVendor
                , issuer
                , paymentType
                , tempExternalReference
                , iovationBlackBox);

                AsyncManager.OutstandingOperations.Increment();
            }
            catch (Exception ex)
            {
                AsyncManager.Parameters["exception"] = ex;
            }
        }

        private void PrepareInPayTransaction(string paymentMethodName
            , long gammingAccountID
            , string currency
            , string amount
            , long payCardID
            , string bonusCode
            , string bonusVendor
            , string issuer
            , string paymentType
            , string tempExternalReference
            , string iovationBlackBox
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

            if (!string.IsNullOrEmpty(iovationBlackBox))
                AsyncManager.Parameters["iovationBlackBox"] = iovationBlackBox;

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
                            IovationBlackBox = iovationBlackBox,
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
                            , OnPrepareInPayTransactionCompleted
                            );
                    }
                    else
                    {
                        AsyncManager.Parameters["outRange"] = "1";
                    }

                }// using
            }//if
        }

        private void OnPrepareInPayTransactionCompleted(AsyncResult reply)
        {
            try
            {
                var prepareTransRequest = reply.EndSingleRequest().Get<PrepareTransRequest>();

                if (string.Compare("1", AsyncManager.Parameters["outRange"].ToString(), false) == 0)
                    throw new Exception("OUTRANGE");

                string sid = prepareTransRequest.Record.Sid;

                if (prepareTransRequest.Record.Status != PreTransStatus.Setup)
                    throw new Exception(string.Format("Invalid status for transaction [{0}]", sid));

                cmTransParameter.SaveObject<PrepareTransRequest>(prepareTransRequest.Record.Sid
                    , "PrepareTransRequest"
                    , prepareTransRequest
                    );
                //cmTransParameter.SaveObject<string>(prepareTransRequest.Record.Sid
                //    , "UserID"
                //    , CustomProfile.Current.UserID.ToString()
                //    );
                cmTransParameter.SaveObject<string>(prepareTransRequest.Record.Sid
                    , "UserID"
                    , AsyncManager.Parameters["userID"].ToString()
                    );
                //cmTransParameter.SaveObject<string>(prepareTransRequest.Record.Sid
                //    , "SessionID"
                //    , CustomProfile.Current.SessionID
                //    );
                cmTransParameter.SaveObject<string>(prepareTransRequest.Record.Sid
                    , "SessionID"
                    , AsyncManager.Parameters["userSessionID"].ToString()
                    );
                cmTransParameter.SaveObject<string>(prepareTransRequest.Record.Sid
                    , "SuccessUrl"
                    , prepareTransRequest.ReturnURL
                    );
                cmTransParameter.SaveObject<string>(prepareTransRequest.Record.Sid
                    , "CancelUrl"
                    , prepareTransRequest.CancelURL
                    );

                var paymentMethodName = AsyncManager.Parameters["paymentMethodName"].ToString();
                var inPayBank = AsyncManager.Parameters["inPayBank"] as InPayBank;

                cmTransParameter.SaveObject<InPayBank>(sid, "InPayBank", inPayBank);

                ProcessInPayTransaction(paymentMethodName, sid);
            }
            catch (Exception ex)
            {
                AsyncManager.Parameters["exception"] = ex;
                AsyncManager.OutstandingOperations.Decrement();
            }
        }

        public void ProcessInPayTransaction(string paymentMethodName, string sid)
        {
            try
            {
                AsyncManager.Parameters["paymentMethodName"] = paymentMethodName;
                AsyncManager.Parameters["sid"] = sid;

                PrepareTransRequest prepareTransRequest = cmTransParameter.ReadObject<PrepareTransRequest>(sid, "PrepareTransRequest");
                if (prepareTransRequest == null)
                    throw new ArgumentOutOfRangeException("sid");

                InPayBank inPayBank = cmTransParameter.ReadObject<InPayBank>(sid, "InPayBank");
                if (inPayBank == null)
                    throw new ArgumentOutOfRangeException("sid");

                AsyncManager.Parameters["prepareTransRequest"] = prepareTransRequest;

                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    ProcessTransRequest processTransRequest = new ProcessTransRequest()
                    {
                        SID = sid,
                        IsFirstDepositBonusTCAccepted = true, //cmTransParameter.ReadObject<bool>(sid, "BonusAccepted"),
                        IsRequiredRedirectForm = true,
                        RedirectFormName = "depositForm",
                        RedirectFormTarget = "_self",
                        IsRequiredRedirectURL = false,
                        //PostBackURL = this.Url.RouteUrlEx("Deposit", new { @action = "Postback", @paymentMethodName = paymentMethodName, @sid = sid }),
                        PostBackURL = AsyncManager.Parameters["postBackURL"].ToString().Replace("_SID_", sid),
                        SecretKey = cmTransParameter.ReadObject<string>(sid, "SecurityKey").DefaultDecrypt(),
                        //ReturnURL = this.Url.RouteUrlEx("Deposit", new { @action = "Return" }),
                        ReturnURL = AsyncManager.Parameters["returnURL"].ToString(),
                        RequestFields = new Dictionary<string, string>(),
                        SESSION_ID = AsyncManager.Parameters["sessionID"].ToString(),
                        SESSION_USERID = Convert.ToInt64(AsyncManager.Parameters["userID"]),
                        SESSION_USERIP = AsyncManager.Parameters["userIP"].ToString(),
                        SESSION_USERSESSIONID = AsyncManager.Parameters["userSessionID"].ToString(),
                    };

                    if (AsyncManager.Parameters.ContainsKey("iovationBlackBox"))
                        processTransRequest.IovationBlackBox = AsyncManager.Parameters["iovationBlackBox"].ToString();

                    processTransRequest.RequestFields["bank_id"] = inPayBank.ID.ToString(CultureInfo.InvariantCulture);
                    GamMatrixClient.SingleRequestAsync<ProcessTransRequest>(processTransRequest, OnProcessTransactionCompleted);
                }
            }
            catch (Exception ex)
            {
                AsyncManager.Parameters["exception"] = ex;
            }
        }

        public ActionResult ProcessInPayTransactionCompleted(PrepareTransRequest prepareTransRequest
            , ProcessTransRequest processTransRequest
            , string paymentMethodName
            , string sid
            , Exception exception
            , JsonResult iovationResult = null
            )
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return View("Anonymous");

            if (iovationResult != null)
                return iovationResult;

            try
            {
                if (exception != null)
                    throw exception;

                string receiptUrl = this.Url.RouteUrlEx("Deposit", new { @action = "Receipt", @paymentMethodName = paymentMethodName, @sid = prepareTransRequest.Record.Sid });

                CustomProfile.Current.Set("ReceiptUrl", receiptUrl);

                bool showTC = prepareTransRequest.IsFirstDepositBonusAvailableAndRequireTC;
                if (showTC)
                {
                    string cookieName = string.Format("GM_{0}", AsyncManager.Parameters["gammingAccountID"].ToString());
                    HttpCookie cookie = Request.Cookies[cookieName];
                    if (cookie != null && !string.IsNullOrWhiteSpace(cookie.Value))
                    {
                        bool accepted = true;
                        if (bool.TryParse(cookie.Value, out accepted))
                        {
                            cmTransParameter.SaveObject<bool>(prepareTransRequest.Record.Sid, "BonusAccepted", accepted);
                            showTC = false;
                        }
                    }
                }

                //processTransRequest.InputValue1 = cmTransParameter.Mask(sid, "InputValue1", processTransRequest.InputValue1);
                //processTransRequest.InputValue2 = cmTransParameter.Mask(sid, "InputValue2", processTransRequest.InputValue2);
                processTransRequest.SecretKey = cmTransParameter.Mask(sid, "SecurityKey", processTransRequest.SecretKey);
                cmTransParameter.SaveObject<ProcessTransRequest>(sid, "ProcessTransRequest", processTransRequest);

                if (processTransRequest.Record.Status == PreTransStatus.AsyncSent)
                {
                    var xml = processTransRequest.ResponseFields["api_response"];
                    if (string.IsNullOrWhiteSpace(xml))
                        throw new Exception("Empty [api_response] from GmCore.");

                    cmTransParameter.SaveObject<string>(sid, "InPayApiResponseXml", xml);

                    return this.Json(new
                    {
                        @success = true,
                        @sid = prepareTransRequest.Record.Sid,
                        @showTC = showTC
                    });
                }
                else if (processTransRequest.Record.Status == PreTransStatus.Success
                    || processTransRequest.Record.Status == PreTransStatus.Processing)
                {
                    SendReceiptEmail(paymentMethodName, sid);

                    return this.Json(new
                    {
                        @success = true,
                        @sid = prepareTransRequest.Record.Sid,
                        @redirectUrl = Url.RouteUrl("Deposit", new { @action = "Receipt", @sid = prepareTransRequest.Record.Sid, @paymentMethodName = paymentMethodName }),
                    });
                }
                else
                {
                    throw new InvalidOperationException();
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                string friendlyError = GmException.TryGetFriendlyErrorMsg(ex);
                cmTransParameter.SaveObject<string>(sid, "LastError", friendlyError);
                return this.Json(new
                {
                    @success = false,
                    @error = friendlyError,
                });
            }
        }
        #endregion

        /// <summary>
        /// This action is called by 3rd-party payment gateway when the transaction is completed.
        /// </summary>
        /// <param name="sid"></param>
        /// <returns></returns>
        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult BonusTC(string sid)
        {
            PrepareTransRequest prepareTransRequest = cmTransParameter.ReadObject<PrepareTransRequest>(sid, "PrepareTransRequest");
            if (prepareTransRequest == null)
                throw new ArgumentOutOfRangeException("sid");

            return this.View("BonusTC", prepareTransRequest);
        }


        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult SaveSecurityKey(string sid, string securityKey)
        {
            if (string.IsNullOrWhiteSpace(sid) ||
                string.IsNullOrWhiteSpace(securityKey))
            {
                throw new ArgumentNullException();
            }
            cmTransParameter.SaveObject<string>(sid, "SecurityKey", securityKey.DefaultEncrypt());
            return this.Json(new { @success = true }, JsonRequestBehavior.AllowGet);
        }


        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult SaveEnterCash(string sid, string bankID, string verificationCode, string paymentName)
        {
            if (string.IsNullOrWhiteSpace(sid) ||
                string.IsNullOrWhiteSpace(bankID) //||
                                                  //(paymentName.Equals("EnterCash_WyWallet", StringComparison.InvariantCultureIgnoreCase) && string.IsNullOrWhiteSpace(verificationCode))
                )
            {
                throw new ArgumentNullException();
            }
            cmTransParameter.SaveObject<string>(sid, "InputValue1", bankID.DefaultEncrypt());
            if (!string.IsNullOrWhiteSpace(verificationCode))
                cmTransParameter.SaveObject<string>(sid, "InputValue2", verificationCode.DefaultEncrypt());

            return this.Json(new { @success = true }, JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult SaveUkash(string sid, string ukashNumber, string ukashValue)
        {
            if (string.IsNullOrWhiteSpace(sid)
                || string.IsNullOrWhiteSpace(ukashNumber))
            //|| string.IsNullOrWhiteSpace(ukashValue))
            {
                throw new ArgumentNullException();
            }

            if (Settings.Ukash_AllowPartialDeposit)
            {
                if (string.IsNullOrWhiteSpace(ukashValue))
                    throw new ArgumentNullException();
            }
            else
            {
                PrepareTransRequest prepareTransRequest = cmTransParameter.ReadObject<PrepareTransRequest>(sid, "prepareTransRequest");
                if (prepareTransRequest == null)
                    throw new ArgumentNullException();

                ukashValue = prepareTransRequest.Record.RequestAmount.ToString(CultureInfo.InvariantCulture);
            }

            cmTransParameter.SaveObject<string>(sid, "InputValue1", ukashNumber.DefaultEncrypt());
            cmTransParameter.SaveObject<string>(sid, "InputValue2", decimal.Parse(ukashValue.Trim(), CultureInfo.InvariantCulture).ToString("0.00", CultureInfo.InvariantCulture).DefaultEncrypt());
            return this.Json(new { @success = true }, JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult SaveAstroPay(string sid, string cardNumber, string expiryDate, string cardSecurityCode)
        {
            if (string.IsNullOrWhiteSpace(sid)
                || string.IsNullOrWhiteSpace(cardNumber)
                || string.IsNullOrWhiteSpace(expiryDate)
                || string.IsNullOrWhiteSpace(cardSecurityCode))
            {
                throw new ArgumentNullException();
            }

            if (string.IsNullOrWhiteSpace(expiryDate))
            {
                throw new ArgumentNullException();
            }

            DateTime temp;

            if (!DateTime.TryParseExact(expiryDate, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out temp))
            {
                throw new ArgumentException();
            }

            cmTransParameter.SaveObject<string>(sid, "InputValue1", cardNumber.DefaultEncrypt());
            cmTransParameter.SaveObject<string>(sid, "InputValue2", expiryDate.Trim().DefaultEncrypt());
            cmTransParameter.SaveObject<string>(sid, "SecurityKey", cardSecurityCode.Trim().DefaultEncrypt());
            return this.Json(new { @success = true }, JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult SaveBocash(string sid, string bocashCode)
        {
            if (string.IsNullOrWhiteSpace(sid) ||
                string.IsNullOrWhiteSpace(bocashCode))
            {
                throw new ArgumentNullException();
            }
            cmTransParameter.SaveObject<string>(sid, "InputValue1", bocashCode.DefaultEncrypt());
            return this.Json(new { @success = true }, JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult SaveIPSToken(string sid, string token, string checkDigit)
        {
            if (string.IsNullOrWhiteSpace(sid) ||
                string.IsNullOrWhiteSpace(token) ||
                string.IsNullOrWhiteSpace(checkDigit))
            {
                throw new ArgumentNullException();
            }
            cmTransParameter.SaveObject<string>(sid, "InputValue1", token.Trim().DefaultEncrypt());
            cmTransParameter.SaveObject<string>(sid, "SecurityKey", checkDigit.Trim().DefaultEncrypt());
            return this.Json(new { @success = true }, JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult SaveTLNakit(string sid, string cardNumber, string ukashValue)
        {
            if (string.IsNullOrWhiteSpace(sid) ||
                string.IsNullOrWhiteSpace(cardNumber))
            {
                throw new ArgumentNullException();
            }
            cmTransParameter.SaveObject<string>(sid, "InputValue1", cardNumber.DefaultEncrypt());
            return this.Json(new { @success = true }, JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult SaveInPay(string sid, string inPayBankID)
        {
            if (string.IsNullOrWhiteSpace(sid) ||
                //string.IsNullOrWhiteSpace(inPayCountry) ||
                string.IsNullOrWhiteSpace(inPayBankID)
                )
            {
                throw new ArgumentNullException();
            }

            int bankID;
            if (!int.TryParse(inPayBankID, out bankID))
                throw new ArgumentNullException();

            var countries = InPayClient.GetInPayCountryAndBanks();
            var country = countries.FirstOrDefault(c => c.Banks.Any(b => b.ID == bankID));
            if (country == null)
                throw new ArgumentNullException();

            var bank = country.Banks.FirstOrDefault(b => b.ID == bankID);
            if (bank == null)
                throw new ArgumentNullException();

            cmTransParameter.SaveObject<InPayBank>(sid, "InPayBank", bank);

            return this.Json(new { @success = true }, JsonRequestBehavior.AllowGet);
        }

        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult SaveVoucher(string sid, string voucherNumber, string securityKey)
        {
            if (string.IsNullOrWhiteSpace(sid) ||
                string.IsNullOrWhiteSpace(voucherNumber) ||
                string.IsNullOrWhiteSpace(securityKey))
            {
                throw new ArgumentNullException();
            }
            cmTransParameter.SaveObject<string>(sid, "InputValue1", voucherNumber.DefaultEncrypt());
            cmTransParameter.SaveObject<string>(sid, "SecurityKey", securityKey.DefaultEncrypt());
            return this.Json(new { @success = true }, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Save the bonus choice
        /// </summary>
        /// <param name="sid"></param>
        /// <param name="paramterName"></param>
        /// <param name="?"></param>
        /// <returns></returns>
        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult SaveBonusChoice(string sid, long gammingAccountID, bool accepted, int rememberDays)
        {
            cmTransParameter.SaveObject<bool>(sid, "BonusAccepted", accepted);

            HttpCookie cookie = new HttpCookie(string.Format("GM_{0}", gammingAccountID));
            if (!string.IsNullOrWhiteSpace(SiteManager.Current.SessionCookieDomain))
                cookie.Domain = SiteManager.Current.SessionCookieDomain;
            cookie.Secure = false;
            cookie.HttpOnly = false;
            cookie.Value = accepted.ToString();
            cookie.Expires = DateTime.Now.AddDays(rememberDays);
            Response.Cookies.Add(cookie);

            return this.Json(new { @success = true });
        }

        /// <summary>
        /// The confirmation view
        /// </summary>
        /// <param name="sid"></param>
        /// <returns></returns>
        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult Confirmation(string sid, string paymentMethodName)
        {
            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
                .First(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.InvariantCultureIgnoreCase));

            this.ViewData["paymentMethod"] = paymentMethod;

            if (paymentMethod.VendorID == VendorID.TxtNation)
            {
                var realAmount = 0M;

                if (!decimal.TryParse(sid, out realAmount))
                {
                    throw new ArgumentOutOfRangeException("sid");
                }

                var prepareTransactionRequest = new PrepareTransRequest
                {
                    Record = new PreTransRec
                    {
                        CreditRealCurrency = "GBP",
                        CreditRealAmount = realAmount,
                        DebitRealCurrency = "GBP",
                        DebitRealAmount = realAmount,
                        CreditPayItemVendorID = VendorID.TxtNation
                    }
                };

                return View("Confirmation", prepareTransactionRequest);
            }

            PrepareTransRequest prepareTransRequest = cmTransParameter.ReadObject<PrepareTransRequest>(sid, "PrepareTransRequest");
            if (prepareTransRequest == null)
                throw new ArgumentOutOfRangeException("sid");

            if (paymentMethod.VendorID == VendorID.InPay)
            {
                InPayBank inPayBank = cmTransParameter.ReadObject<InPayBank>(sid, "InPayBank");
                string inPayApiResponseXml = cmTransParameter.ReadObject<string>(sid, "InPayApiResponseXml");
                if (inPayBank == null || string.IsNullOrWhiteSpace(inPayApiResponseXml))
                    throw new ArgumentOutOfRangeException("sid");

                this.ViewData["inPayBank"] = inPayBank;
                this.ViewData["inPayApiResponseXml"] = inPayApiResponseXml;
                return View("ConfirmationInPay", prepareTransRequest);
            }

            return View("Confirmation", prepareTransRequest);
        }

        #region Confirm
        /// <summary>
        /// The confirmation view
        /// </summary>
        /// <param name="sid"></param>
        /// <returns></returns>

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
                    using (GamMatrixClient client = GamMatrixClient.Get())
                    {
                        ProcessTransRequest processTransRequest = new ProcessTransRequest()
                        {
                            SID = sid,
                            IsFirstDepositBonusTCAccepted = cmTransParameter.ReadObject<bool>(sid, "BonusAccepted"),
                            IsRequiredRedirectForm = true,
                            RedirectFormName = "depositForm",
                            RedirectFormTarget = "_self",
                            IsRequiredRedirectURL = false,
                            ReturnURL = this.Url.RouteUrlEx("Deposit", new { @action = "Return", @paymentMethodName = paymentMethodName, @sid = sid }),
                            PostBackURL = this.Url.RouteUrlEx("Deposit", new { @action = "Postback", @paymentMethodName = paymentMethodName, @sid = sid }),
                            SecretKey = cmTransParameter.ReadObject<string>(sid, "SecurityKey").DefaultDecrypt(),
                            InputValue1 = cmTransParameter.ReadObject<string>(sid, "InputValue1").DefaultDecrypt(),
                            InputValue2 = cmTransParameter.ReadObject<string>(sid, "InputValue2").DefaultDecrypt(),
                        };
                        if (Settings.IovationDeviceTrack_Enabled)
                        {
                            processTransRequest.IovationBlackBox = Request.Form["iovationBlackBox"];
                        }
                        GamMatrixClient.SingleRequestAsync<ProcessTransRequest>(processTransRequest, OnProcessTransactionCompleted);
                        AsyncManager.OutstandingOperations.Increment();
                    }
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
                try
                {
                    if (exception != null)
                        throw exception;

                    if (prepareTransRequest.Record.Status == PreTransStatus.Setup)
                    {
                        processTransRequest.InputValue1 = cmTransParameter.Mask(sid, "InputValue1", processTransRequest.InputValue1);
                        processTransRequest.InputValue2 = cmTransParameter.Mask(sid, "InputValue2", processTransRequest.InputValue2);
                        processTransRequest.SecretKey = cmTransParameter.Mask(sid, "SecurityKey", processTransRequest.SecretKey);
                        cmTransParameter.SaveObject<ProcessTransRequest>(sid, "ProcessTransRequest", processTransRequest);

                        if (processTransRequest.Record.Status == PreTransStatus.Success)
                        {
                            SendReceiptEmail(paymentMethodName, sid);
                            this.ViewData["RedirectUrl"] = string.Format(CultureInfo.InvariantCulture, "/Deposit/Receipt/{0}/{1}", paymentMethodName, sid);
                            return View("SuccessRedirect");
                        }
                        else if (processTransRequest.Record.Status == PreTransStatus.AsyncSent)
                        {
                            // for EcoCard, EnterCash_OnlineBank etc
                            this.ViewData["FormHtml"] = processTransRequest.RedirectForm;

                            if (processTransRequest.RedirectForm == null && paymentMethodName.Equals("EnterCash_OnlineBank", StringComparison.InvariantCultureIgnoreCase))
                            {
                                if (prepareTransRequest.PaymentMethods != null && prepareTransRequest.PaymentMethods.Exists(p => p.Equals("REFCODE", StringComparison.InvariantCultureIgnoreCase)))
                                    this.ViewData["RedirectUrl"] = string.Format(CultureInfo.InvariantCulture, "/Deposit/EnterCashSuccess/{0}/{1}", paymentMethodName, sid); ;

                                return View("SuccessRedirect");
                            }
                        }
                    }
                    else if (prepareTransRequest.Record.Status == PreTransStatus.AsyncSent)
                    {
                        if (prepareTransRequest.RedirectForm == null && paymentMethodName.Equals("PugglePay", StringComparison.InvariantCultureIgnoreCase))
                        {
                            this.ViewData["PaymentMethodName"] = paymentMethodName;
                            return View("PugglePayRedirect", prepareTransRequest);
                            //this.ViewData["RedirectUrl"] = string.Format(CultureInfo.InvariantCulture, "/Deposit/PugglePayRedirect/{0}", sid); ;
                            //return View("SuccessRedirect");
                        }

                        this.ViewData["FormHtml"] = prepareTransRequest.RedirectForm;
                    }

                    return View("PaymentFormPost");
                }
                catch (GmException gex)
                {
                    // handle the sensitive error codes for EntroPay
                    if (Settings.DeclindedDeposit_SensitiveErrorCodes.
                        FirstOrDefault(e => string.Equals(e, gex.ReplyResponse.ErrorCode, StringComparison.InvariantCultureIgnoreCase)) != null)
                    {
                        string url = string.Format(CultureInfo.InvariantCulture, "/Deposit/DeclindedDeposit/{0}", sid);
                        this.ViewData["EntroPayUrl"] = url;
                    }
                    throw;
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                string friendlyError = GmException.TryGetFriendlyErrorMsg(ex);
                cmTransParameter.SaveObject<string>(sid, "LastError", friendlyError);
                this.ViewData["ErrorMessage"] = friendlyError;
                return View("Error");
            }
        }
        #endregion

        /// <summary>
        /// This action is called by 3rd-party payment gateway when the transaction is completed.
        /// </summary>
        /// <param name="sid"></param>
        /// <returns></returns>
        [ValidateInput(false)]
        public void PostbackAsync(string paymentMethodName, string sid, bool isQuickDeposit = false)
        {
            if (string.IsNullOrWhiteSpace(sid))
                sid = Request["gm_sid"].DefaultIfNullOrEmpty(Request["transaction_id"]);

            Logger.Information("Deposit", "Postback {0} {1}", sid, paymentMethodName);

            if (string.IsNullOrWhiteSpace(sid))
                throw new ArgumentNullException("sid");

            AsyncManager.Parameters["sid"] = sid;
            AsyncManager.Parameters["paymentMethodName"] = paymentMethodName;
            AsyncManager.Parameters["isQuickDeposit"] = isQuickDeposit;

            Dictionary<string, string> d = new Dictionary<string, string>();

            foreach (string name in Request.Params.Keys)
            {
                if (!string.IsNullOrEmpty(name))
                {
                    d[name] = (string)Request.Params[name];
                }
            }
            d["REMOTE_ADDR"] = Request.GetRealUserAddress();
            d["gm_sid"] = sid;

            ProcessAsyncTransRequest processAsyncTransRequest = new ProcessAsyncTransRequest()
            {
                ResponseFields = d,
                SecretKey = cmTransParameter.ReadObject<string>(sid, "SecurityKey").DefaultDecrypt(),
                ForbidDoubleBooking = !string.Equals(paymentMethodName, "Paysafecard", StringComparison.InvariantCultureIgnoreCase),
                IsFirstDepositBonusTCAccepted = cmTransParameter.ReadObject<bool>(sid, "BonusAccepted"),
            };

            cmTransParameter.SaveObject<ProcessAsyncTransRequest>(sid, "ProcessAsyncTransRequestBefore", processAsyncTransRequest);

            GamMatrixClient.SingleRequestAsync<ProcessAsyncTransRequest>(processAsyncTransRequest
                , OnProcessAsyncTransactionCompleted
                );

            AsyncManager.OutstandingOperations.Increment();
        }

        private void OnProcessAsyncTransactionCompleted(AsyncResult result)
        {
            try
            {
                AsyncManager.Parameters["processAsyncTransRequest"]
                    = result.EndSingleRequest().Get<ProcessAsyncTransRequest>();
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

        public ActionResult PostbackCompleted(ProcessAsyncTransRequest processAsyncTransRequest
            , string paymentMethodName
            , string sid
            , bool isQuickDeposit
            , Exception exception
            )
        {
            try
            {
                try
                {
                    if (exception != null)
                        throw exception;

                    if (processAsyncTransRequest != null)
                    {
                        processAsyncTransRequest.SecretKey = cmTransParameter.Mask(sid, "SecurityKey", processAsyncTransRequest.SecretKey);
                    }
                    cmTransParameter.SaveObject<ProcessAsyncTransRequest>(sid, "ProcessAsyncTransRequest", processAsyncTransRequest);

                    SendReceiptEmail(paymentMethodName, sid);
                    this.ViewData["RedirectUrl"] = this.Url.RouteUrlEx("Deposit", new { @action = "Receipt", @paymentMethodName = paymentMethodName, @sid = sid });
                    this.ViewData["Sid"] = sid;
                    return View(isQuickDeposit ? "QuickDepositWidget/SuccessRedirect" : "SuccessRedirect");
                }
                catch (GmException gex)
                {
                    // handle the sensitive error codes for EntroPay
                    if (Settings.DeclindedDeposit_SensitiveErrorCodes.
                        FirstOrDefault(e => string.Equals(e, gex.ReplyResponse.ErrorCode, StringComparison.InvariantCultureIgnoreCase)) != null)
                    {
                        string url = string.Format(CultureInfo.InvariantCulture, "/Deposit/DeclindedDeposit/{0}", sid);
                        this.ViewData["EntroPayUrl"] = url;
                    }
                    throw;
                }
            }
            catch (Exception ex)
            {
                string friendlyError = GmException.TryGetFriendlyErrorMsg(ex);
                cmTransParameter.SaveObject<string>(sid, "LastError", friendlyError);
                this.ViewData["ErrorMessage"] = friendlyError;
                this.ViewData["Sid"] = sid;
                return View(isQuickDeposit ? "QuickDepositWidget/Error" : "Error");
            }
        }

        #region SendReceiptEmail
        private void SendReceiptEmail(string paymentMethodName, string sid)
        {
            try
            {
                /*
                using (RedisConnectionEx redis = new RedisConnectionEx())
                {
                    redis.Open().Wait();
                    Task<bool> t = redis.Hashes.SetIfNotExists(0, "$EMAIL_SENT$", sid, new byte[0]);
                    t.Wait();
                    if (!t.Result)
                        return;
                }
                 * */

                PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
                .FirstOrDefault(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.InvariantCultureIgnoreCase));
                if (paymentMethod == null)
                    throw new ArgumentOutOfRangeException("paymentMethodName");

                GetTransInfoRequest getTransInfoRequest;
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    //only for GCE
                    if (paymentMethod.VendorID == VendorID.GCE)
                    {
                        GetGiftCardEmpireAutoCreatedTransRequest getGiftCardEmpireAutoCreatedTransRequest = client.SingleRequest<GetGiftCardEmpireAutoCreatedTransRequest>(new GetGiftCardEmpireAutoCreatedTransRequest()
                        {
                            Sid = sid,
                        });
                        if (!string.IsNullOrWhiteSpace(getGiftCardEmpireAutoCreatedTransRequest.AutoCreatedSid))
                            sid = getGiftCardEmpireAutoCreatedTransRequest.AutoCreatedSid;
                    }

                    //for PugglePay
                    if (paymentMethod.VendorID == VendorID.PugglePay)
                    {
                        GetAutoCreatedTransRequest getAutoCreatedTransRequest = client.SingleRequest<GetAutoCreatedTransRequest>(new GetAutoCreatedTransRequest()
                        {
                            Sid = sid,
                        });
                        if (!string.IsNullOrWhiteSpace(getAutoCreatedTransRequest.AutoCreatedSid))
                            sid = getAutoCreatedTransRequest.AutoCreatedSid;
                    }

                    getTransInfoRequest = client.SingleRequest<GetTransInfoRequest>(new GetTransInfoRequest()
                    {
                        SID = sid,
                        NoDetails = true,
                    });
                }
                PreTransStatus preTransStatus = getTransInfoRequest.TransData.Status;
                TransStatus transStatus = getTransInfoRequest.TransData.TransStatus;
                if (preTransStatus == PreTransStatus.Success &&
                    transStatus == TransStatus.Success)
                {
                    UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                    long userID = long.Parse(cmTransParameter.ReadObject<string>(sid, "UserID"));
                    cmUser user = ua.GetByID(userID);
                    Email mail = new Email();
                    mail.LoadFromMetadata("DepositReceipt", Request.GetLanguage());
                    mail.ReplaceDirectory["FIRSTNAME"] = user.FirstName;
                    mail.ReplaceDirectory["TRANSACTION_ID"] = getTransInfoRequest.TransID.ToString();
                    //mail.ReplaceDirectory["TRANSACTION_SITE"] = string.Format( "http://{0}:{1}", Request.Url.Host, SiteManager.Current.HttpPort);
                    mail.ReplaceDirectory["TRANSACTION_SITE"] = string.Format("http://{0}", Request.Url.Host);
                    mail.ReplaceDirectory["TRANSACTION_TIME"] = getTransInfoRequest.TransData.TransCompleted.ToString("dd/MM/yyyy HH:mm:ss");

                    string receiptAction = "Receipt";
                    if (paymentMethodName.Equals("Receipt", StringComparison.InvariantCultureIgnoreCase))
                        receiptAction = "IPSTokenReceipt";

                    // the email will be sent by another server
                    string url = string.Format("http://{0}:{1}/{2}{3}"
                        , Request.Url.Host
                        , SiteManager.Current.HttpPort
                        , Request.GetLanguage()
                        , this.Url.RouteUrl("Deposit", new { @action = receiptAction, @paymentMethodName = paymentMethodName, @sid = sid, @_sid = cmTransParameter.ReadObject<string>(sid, "SessionID") })
                        );

                    string postUrl = ConfigurationManager.AppSettings["ScreenshotSenderUrl"].DefaultIfNullOrEmpty("http://10.0.10.245/SendReceipt.ashx");
                    HttpWebRequest request = HttpWebRequest.Create(postUrl) as HttpWebRequest;
                    request.Method = "POST";
                    request.KeepAlive = false;
                    request.Timeout = 5000;
                    request.ReadWriteTimeout = 5000;
                    request.ContentType = "text/plain";
                    request.Headers.Add("Receiver", user.Email);
                    request.Headers.Add("Sender", Settings.Email_NoReplyAddress);
                    request.Headers.Add("ReplyTo", Settings.Email_SupportAddress);
                    request.Headers.Add("Sid", sid);
                    request.Headers.Add("Url", url);
                    request.Headers.Add("Subject", mail.Subject);
                    request.Headers.Add("Email_SMTP", Settings.Email_SMTP);
                    request.Headers.Add("Email_Port", Settings.Email_Port.ToString());

                    using (Stream stream = request.GetRequestStream())
                    {
                        using (StreamWriter sw = new StreamWriter(stream))
                        {
                            sw.Write(mail.GetBody());
                            sw.Close();
                        }
                        HttpWebResponse response = (HttpWebResponse)request.GetResponse();
                        using (Stream s = response.GetResponseStream())
                        {
                            using (StreamReader sr = new StreamReader(s))
                            {
                                string respText = sr.ReadToEnd();

                                if (!string.Equals(respText, "-ERR", StringComparison.InvariantCultureIgnoreCase))
                                    Logger.Email("DepositReceipt", Settings.Email_NoReplyAddress, Settings.Email_SupportAddress, user.Email, mail.Subject, mail.GetBody());
                            }
                        }
                        response.Close();
                    }
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }
        }
        #endregion

        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult EnterCashSuccess(string paymentMethodName, string sid)
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return View("Anonymous");

            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
               .FirstOrDefault(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.InvariantCultureIgnoreCase));
            if (paymentMethod == null)
                throw new ArgumentOutOfRangeException("paymentMethodName");

            PrepareTransRequest prepareTransRequest = cmTransParameter.ReadObject<PrepareTransRequest>(sid, "PrepareTransRequest");
            if (prepareTransRequest == null)
                throw new ArgumentOutOfRangeException("sid");

            ProcessTransRequest processTransRequest = cmTransParameter.ReadObject<ProcessTransRequest>(sid, "ProcessTransRequest");
            if (processTransRequest != null)
            {
                processTransRequest.InputValue1 = cmTransParameter.Unmask(sid, "InputValue1", processTransRequest.InputValue1);
                processTransRequest.InputValue2 = cmTransParameter.Unmask(sid, "InputValue2", processTransRequest.InputValue2);
                processTransRequest.SecretKey = cmTransParameter.Unmask(sid, "SecurityKey", processTransRequest.SecretKey);
            }

            string lastError = cmTransParameter.ReadObject<string>(sid, "LastError");
            GetTransInfoRequest getTransInfoRequest = null;
            var bankID = cmTransParameter.ReadObject<string>(sid, "InputValue1").DefaultDecrypt();

            try
            {
                using (GamMatrixClient client = GamMatrixClient.Get())
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
                this.ViewData["bankID"] = bankID;

                PreTransStatus preTransStatus = getTransInfoRequest.TransData.Status;
                TransStatus transStatus = getTransInfoRequest.TransData.TransStatus;

                if (preTransStatus == PreTransStatus.Failed ||
                    transStatus == TransStatus.Failed ||
                    !string.IsNullOrEmpty(lastError))
                {
                    this.ViewData["ErrorMessage"] = cmTransParameter.ReadObject<string>(sid, "LastError");
                    return View("Error");
                }

                return View("EnterCashSuccess", paymentMethod);
            }
            catch (Exception ex)
            {
                if (!string.IsNullOrEmpty(lastError))
                {
                    this.ViewData["ErrorMessage"] = cmTransParameter.ReadObject<string>(sid, "LastError");
                    return View("Error");
                }
                throw;
            }
        }

        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult IPSTokenReceipt(string paymentMethodName, string sid)
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return View("Anonymous");

            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
                .FirstOrDefault(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.InvariantCultureIgnoreCase));
            if (paymentMethod == null)
                throw new ArgumentOutOfRangeException("paymentMethodName");

            IPSTokenDepositNoAmountRequest requestIPSTokenDepositNoAmount = cmTransParameter.ReadObject<IPSTokenDepositNoAmountRequest>(sid, "IPSTokenDepositNoAmountRequest");

            string lastError = cmTransParameter.ReadObject<string>(sid, "LastError");

            AccountData account = GamMatrixClient.GetUserGammingAccounts(CustomProfile.Current.UserID, true).FirstOrDefault(a => a.ID == requestIPSTokenDepositNoAmount.AccountId);
            GetTransInfoRequest getTransInfoRequest;
            using (GamMatrixClient client = GamMatrixClient.Get())
            {
                getTransInfoRequest = client.SingleRequest<GetTransInfoRequest>(new GetTransInfoRequest()
                {
                    SID = sid,
                    NoDetails = true,
                });
            }
            this.ViewData["getTransInfoRequest"] = getTransInfoRequest;
            this.ViewData["requestIPSTokenDepositNoAmount"] = requestIPSTokenDepositNoAmount;
            this.ViewData["creditAccount"] = account;

            SendReceiptEmail(paymentMethodName, sid);

            return View("IPSTokenReceipt", paymentMethod);
        }


        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult Receipt(string paymentMethodName, string sid)
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return View("Anonymous");

            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
                .FirstOrDefault(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.InvariantCultureIgnoreCase));
            if (paymentMethod == null)
                throw new ArgumentOutOfRangeException("paymentMethodName");

            if (paymentMethod.VendorID == VendorID.TxtNation)
            {
                return View("Receipt", paymentMethod);
            }

            PrepareTransRequest prepareTransRequest = cmTransParameter.ReadObject<PrepareTransRequest>(sid, "PrepareTransRequest");
            if (prepareTransRequest == null)
                throw new ArgumentOutOfRangeException("sid");

            ProcessTransRequest processTransRequest = cmTransParameter.ReadObject<ProcessTransRequest>(sid, "ProcessTransRequest");
            if (processTransRequest != null)
            {
                processTransRequest.InputValue1 = cmTransParameter.Unmask(sid, "InputValue1", processTransRequest.InputValue1);
                processTransRequest.InputValue2 = cmTransParameter.Unmask(sid, "InputValue2", processTransRequest.InputValue2);
                processTransRequest.SecretKey = cmTransParameter.Unmask(sid, "SecurityKey", processTransRequest.SecretKey);
            }

            ProcessAsyncTransRequest processAsyncTransRequest = cmTransParameter.ReadObject<ProcessAsyncTransRequest>(sid, "ProcessAsyncTransRequest");
            if (processAsyncTransRequest != null)
            {
                processAsyncTransRequest.SecretKey = cmTransParameter.Unmask(sid, "SecurityKey", processAsyncTransRequest.SecretKey);
            }

            GetTransInfoRequest getTransInfoRequest = null;

            var lastError = cmTransParameter.ReadObject<string>(sid, "LastError");

            try
            {
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    //only for GCE
                    if (paymentMethod.VendorID == VendorID.GCE)
                    {
                        GetGiftCardEmpireAutoCreatedTransRequest getGiftCardEmpireAutoCreatedTransRequest = client.SingleRequest<GetGiftCardEmpireAutoCreatedTransRequest>(new GetGiftCardEmpireAutoCreatedTransRequest()
                        {
                            Sid = sid,
                        });
                        if (!string.IsNullOrWhiteSpace(getGiftCardEmpireAutoCreatedTransRequest.AutoCreatedSid))
                            sid = getGiftCardEmpireAutoCreatedTransRequest.AutoCreatedSid;
                    }

                    //for PugglePay and MM Zimpler
                    if (paymentMethod.VendorID == VendorID.PugglePay ||
                        (paymentMethod.VendorID == VendorID.MoneyMatrix && paymentMethod.UniqueName == "MoneyMatrix_Zimpler"))
                    {
                        GetAutoCreatedTransRequest getAutoCreatedTransRequest = client.SingleRequest<GetAutoCreatedTransRequest>(new GetAutoCreatedTransRequest()
                        {
                            Sid = sid,
                        });
                        if (!string.IsNullOrWhiteSpace(getAutoCreatedTransRequest.AutoCreatedSid))
                            sid = getAutoCreatedTransRequest.AutoCreatedSid;
                    }

                    getTransInfoRequest = client.SingleRequest<GetTransInfoRequest>(new GetTransInfoRequest()
                    {
                        SID = sid,
                        NoDetails = true,
                    });
                }
                this.ViewData["getTransInfoRequest"] = getTransInfoRequest;
                this.ViewData["prepareTransRequest"] = prepareTransRequest;
                this.ViewData["processTransRequest"] = processTransRequest;
                this.ViewData["processAsyncTransRequest"] = processAsyncTransRequest;

                PreTransStatus preTransStatus = getTransInfoRequest.TransData.Status;
                TransStatus transStatus = getTransInfoRequest.TransData.TransStatus;

                cmTransParameter.DeleteSecurityKey(sid);

                if (transStatus == TransStatus.Success)
                {
                    Logger.Information("Payment"
                        , "GetTransInfoRequest.TransData.Status = {0}; SID = {1}"
                        , preTransStatus.ToString()
                        , sid
                        );
                    //by Shema: postings are returned in reversed order, so let's reorder
                    getTransInfoRequest.PostingData.Reverse();
                    //by Shema: now first posting is always DEBIT, second CREDIT, the rest - fees / comissions / charges / etc.

                    SendReceiptEmail(paymentMethodName, sid);
                    return View("Receipt", paymentMethod);
                }

                lastError = cmTransParameter.ReadObject<string>(sid, "LastError");

                if (preTransStatus == PreTransStatus.Failed || transStatus == TransStatus.Failed || !string.IsNullOrEmpty(lastError))
                {
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

                return View(paymentMethod.VendorID == VendorID.EnterCash ? "EnterCashNotCompleted" : "NotCompleted");
            }
            catch (Exception ex)
            {
                if (string.IsNullOrWhiteSpace(lastError))
                    lastError = GmException.TryGetFriendlyErrorMsg(ex);

                if (!string.IsNullOrEmpty(lastError))
                {
                    this.ViewData["ErrorMessage"] = cmTransParameter.ReadObject<string>(sid, "LastError");
                    return View("Error");
                }
                throw;
            }
        }


        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult Cancel(bool isQuickDeposit = false)
        {
            return View(isQuickDeposit ? "QuickDepositWidget/Cancel" : "Cancel");
        }


        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult Return(bool isQuickDeposit = false)
        {
            Logger.Information("Deposit", "Return, Url = {0}", Request.RawUrl);
            if (string.Equals(Request.QueryString["Succeed"], "NO", StringComparison.InvariantCultureIgnoreCase))
            {
                this.ViewData["RedirectUrl"] = "/Deposit/Error";
                return View(isQuickDeposit ? "QuickDepositWidget/SuccessRedirect" : "SuccessRedirect");
            }

            string receiptUrl = CustomProfile.Current.Get("ReceiptUrl");
            if (!string.IsNullOrWhiteSpace(receiptUrl))
            {
                Logger.Information("Deposit", "Return, Redirect Url = {0}", receiptUrl);
                this.ViewData["RedirectUrl"] = receiptUrl;
            }

            string sid = CustomProfile.Current.Get("Sid");
            if (!string.IsNullOrWhiteSpace(sid))
            {
                this.ViewData["Sid"] = sid;
            }

            return View(isQuickDeposit ? "QuickDepositWidget/SuccessRedirect" : "SuccessRedirect");
        }


        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult Error(bool isQuickDeposit = false)
        {
            return View(isQuickDeposit ? "QuickDepositWidget/Error" : "Error");
        }

        private void SetBonusDefaultOption(bool addFlag)
        {
            AcceptBonusByDefault flag = AcceptBonusByDefault.All;
            UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
            if (addFlag)
                ua.AddAcceptBonusByDefaultFlag(CustomProfile.Current.UserID, flag);
            else
                ua.RemoveAcceptBonusByDefaultFlag(CustomProfile.Current.UserID, flag);
        }


        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult PrepareEnvoyTransaction(string paymentMethodName
            , long gammingAccountID
            , bool? acceptBonus
            , string bonusCode
            , string bonusVendor
            , string currency
            , string amount
            , string iovationBlackBox = null
            )
        {
            var iovResult = IovationCheck(iovationBlackBox);
            if (iovResult != null)
                return iovResult;

            try
            {
                if (!CustomProfile.Current.IsAuthenticated)
                    return View("Anonymous");



                // save the accept bonus by default value for GmCore backend
                AccountData account = GamMatrixClient.GetUserGammingAccounts(CustomProfile.Current.UserID, true).FirstOrDefault(a => a.ID == gammingAccountID);
                SetBonusDefaultOption(acceptBonus.HasValue && acceptBonus.Value);


                PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
                    .FirstOrDefault(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.InvariantCultureIgnoreCase));
                if (paymentMethod == null)
                    throw new ArgumentOutOfRangeException("paymentMethodName");

                if (Regex.IsMatch(Metadata.Get("Metadata/Settings/Deposit.AstroPayCard_Ignore_DenyDepositCardRole").DefaultIfNullOrWhiteSpace("NO"), @"(YES)|(ON)|(OK)|(TRUE)|(\1)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled))
                {
                    if (CustomProfile.Current.IsInRole(paymentMethod.DenyAccessRoleNames)
                        && !(paymentMethod.UniqueName == "AstroPayCard" && !CustomProfile.Current.IsInRole(paymentMethod.DenyAccessRoleNames.Where(r => !r.Equals("Deny Card Deposit", StringComparison.InvariantCultureIgnoreCase)).ToArray())))
                        return View("AccessDenied");
                }
                else
                {
                    if (CustomProfile.Current.IsInRole(paymentMethod.DenyAccessRoleNames))
                        return View("AccessDenied");
                }
                if (CustomProfile.Current.IsInRole("Withdraw only"))
                    return View("GamblingRegulationsRestriction");

                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    EnvoyGetOneClickGatewayRequest envoyGetOneClickGatewayRequest = new EnvoyGetOneClickGatewayRequest
                    {
                        UserID = CustomProfile.Current.UserID,
                        PaymentType = paymentMethod.SubCode,
                        CreditAccountID = gammingAccountID,
                      
                        IsRequiredRedirectForm = true,
                        RedirectFormName = "depositForm",
                        RedirectFormTarget = "_self",
                    };

                    if (!string.IsNullOrWhiteSpace(amount))
                    {
                        decimal requestAmount = 0.00M;
                        if (decimal.TryParse(Regex.Replace(amount, @"[^\d\.]", string.Empty)
                            , NumberStyles.Number | NumberStyles.AllowDecimalPoint
                            , CultureInfo.InvariantCulture
                            , out requestAmount))
                        {
                            Range rgAmount = paymentMethod.GetDepositLimitation(currency);
                            if (requestAmount > 0 &&
                                ((rgAmount.MinAmount >= rgAmount.MaxAmount && requestAmount >= rgAmount.MinAmount) ||
                                (requestAmount >= rgAmount.MinAmount && requestAmount <= rgAmount.MaxAmount)))
                            {
                                envoyGetOneClickGatewayRequest.RequestAmount = requestAmount;
                                envoyGetOneClickGatewayRequest.RequestCurrency = currency;
                            }
                            else
                            {
                                this.ViewData["outRange"] = "OUTRANGE";
                                return View("Error");
                            }
                        }
                    }

                    if (!string.IsNullOrWhiteSpace(bonusCode))
                    {
                        if (account != null)
                        {
                            VendorID bonusVendorID = VendorID.Unknown;
                            if (!string.IsNullOrWhiteSpace(bonusVendor))
                            {
                                Enum.TryParse(bonusVendor, out bonusVendorID);
                            }
                            if (bonusVendorID == VendorID.Unknown)
                                bonusVendorID = account.Record.VendorID;

                            envoyGetOneClickGatewayRequest.ApplyBonusVendorID = bonusVendorID;
                            envoyGetOneClickGatewayRequest.ApplyBonusCode = bonusCode.Trim();
                        }
                    }

                    envoyGetOneClickGatewayRequest = client.SingleRequest<EnvoyGetOneClickGatewayRequest>(envoyGetOneClickGatewayRequest);

                    string formHtml = envoyGetOneClickGatewayRequest.RedirectForm;

                    // because there is a 50 chractors restriction on the Envoy parameter length
                    // so here stores the urls with a unique id

                    string uid = Guid.NewGuid().ToString("N");
                    cmTransParameter.SaveObject<string>(uid
                        , "SuccessUrl"
                        , this.Url.RouteUrlEx("Deposit", new { @action = "EnvoyPostback", @paymentMethodName = paymentMethodName, @gammingAccountID = gammingAccountID.ToString(), @result = "success" })
                        );
                    cmTransParameter.SaveObject<string>(uid
                        , "ErrorUrl"
                        , this.Url.RouteUrlEx("Deposit", new { @action = "EnvoyPostback", @paymentMethodName = paymentMethodName, @gammingAccountID = gammingAccountID.ToString(), @result = "error" })
                        );
                    cmTransParameter.SaveObject<string>(uid
                        , "CancelUrl"
                        , this.Url.RouteUrlEx("Deposit", new { @action = "EnvoyPostback", @paymentMethodName = paymentMethodName, @gammingAccountID = gammingAccountID.ToString(), @result = "cancel" })
                        );

                    string extraFields = string.Format(@"
<input type=""hidden"" name=""uid"" value=""{0}"" />
</form>"
                        , uid.SafeHtmlEncode()
                        );

                    formHtml = Regex.Replace(formHtml, @"\<\/form\>", extraFields, RegexOptions.Multiline | RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);
                    this.ViewData["FormHtml"] = formHtml;
                    return View("PaymentFormPost");
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return View("Error");
            }
        }


        public JsonResult ProcessLocalBankTransaction(string paymentMethodName
            , long gammingAccountID
            , string currency
            , string amount
            , long payCardID
            , string iovationBlackBox = null
            )
        {
            //SetBonusDefaultOption(acceptBonus.HasValue && acceptBonus.Value);

            var iovResult = IovationCheck(iovationBlackBox);
            if (iovResult != null)
                return iovResult;


            decimal requestAmount = decimal.Parse(Regex.Replace(amount, @"[^\d\.]", string.Empty), CultureInfo.InvariantCulture);

            using (GamMatrixClient client = GamMatrixClient.Get())
            {
                LocalBankPaymentRequest request = new LocalBankPaymentRequest()
                {
                    Payment = new LocalBankRec()
                    {
                        AccountID = gammingAccountID,
                        Amount = requestAmount,
                        Currency = currency,
                        PaycardID = payCardID,

                        UserID = CustomProfile.Current.UserID,
                    }
                };

                request = client.SingleRequest<LocalBankPaymentRequest>(request);
            }

            return this.Json(new { @success = true });
        }

        /// <summary>
        /// Done view
        /// </summary>
        /// <param name="paymentMethodName"></param>
        /// <returns></returns>
        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult Done(string paymentMethodName)
        {
            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
                    .FirstOrDefault(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.InvariantCultureIgnoreCase));
            if (paymentMethod == null)
                throw new ArgumentOutOfRangeException("paymentMethodName");

            if (paymentMethod.VendorID == VendorID.Envoy)
                return View("EnvoySuccess", paymentMethod);

            return View("Done");
        }




        /// <summary>
        /// The postback page for Envoy
        /// </summary>
        /// <param name="paymentMethodName"></param>
        /// <param name="gammingAccountID"></param>
        /// <param name="action"></param>
        /// <returns></returns>
        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult EnvoyPostback(string paymentMethodName, long gammingAccountID, string result)
        {
            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
                    .FirstOrDefault(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.InvariantCultureIgnoreCase));
            if (paymentMethod == null)
                throw new ArgumentOutOfRangeException("paymentMethodName");

            switch (result.ToLower(CultureInfo.InvariantCulture))
            {
                case "success":
                    return View("EnvoySuccess", paymentMethod);

                case "cancel":
                    return View("Cancel");

                case "error":
                    this.ViewData["ErrorMessage"] = Request.Form["customerMessage"];
                    return View("Error");
            }
            return View("EnvoyPostback");
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult InPayFormPost(string sid)
        {
            ProcessTransRequest processTransRequest = cmTransParameter.ReadObject<ProcessTransRequest>(sid, "ProcessTransRequest");
            if (processTransRequest == null)
                throw new ArgumentOutOfRangeException("sid");

            var xml = processTransRequest.ResponseFields["api_response"];

            XDocument doc = XDocument.Parse(xml);
            var isThirdParty = doc.Root.Element("invoice").GetElementValue("is-third-party", false);

            if (isThirdParty)
            {
                // form post method is from instructions -> bank -> payment-instructions -> bank-interface -> form-method
                // form action url is from instructions -> bank -> online-bank-url
                XElement bankInterfaceElement = doc.Root.Element("bank").Element("payment-instructions").Element("bank-interface");

                StringBuilder form = new StringBuilder();
                form.AppendFormat("<form method=\"{0}\" action=\"{1}\">"
                    , bankInterfaceElement.GetElementValue("form-method").SafeHtmlEncode()
                    , doc.Root.Element("bank").GetElementValue("online-bank-url").SafeHtmlEncode()
                    );

                // populate the post fields
                var fields = bankInterfaceElement.Element("fields").Elements("field");
                foreach (var field in fields)
                {
                    form.AppendFormat("<input type=\"hidden\" name=\"{0}\" value=\"{1}\" />"
                        , field.GetElementValue("label").SafeHtmlEncode()
                        , field.GetElementValue("value").SafeHtmlEncode()
                        );
                }

                form.Append("</form>");

                this.ViewData["FormHtml"] = form.ToString();
            }
            else
            {
                StringBuilder form = new StringBuilder();
                form.AppendFormat("<form method=\"{0}\" action=\"{1}\">"
                    , "GET"
                    , doc.Root.Element("bank").GetElementValue("url"));
                form.Append("</form>");

                this.ViewData["FormHtml"] = form.ToString();
            }
            return View("PaymentFormPost");
        }

        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult GetPayCards(VendorID vendorID, string paymentMethodName)
        {
            try
            {
                if (!CustomProfile.Current.IsAuthenticated)
                    throw new UnauthorizedAccessException();

                var payCardInfoRecs = vendorID == VendorID.MoneyMatrix
                    ? GamMatrixClient.GetPayCards(vendorID).Where(c => true)
                    : GamMatrixClient.GetPayCards(vendorID);

                var payCards = payCardInfoRecs
                    .Select(p =>
                    {
                        var paymentMethod = p.GetPaymentMethod();
                        return new
                        {
                            ID = p.ID.ToString(),
                            ExpiryDate = p.ExpiryDate.ToString("MM/yyyy"),
                            DisplayNumber = p.DisplayName,
                            RecordDisplayNumber = p.DisplayNumber,
                            BankName = p.BankName,
                            OwnerName = p.OwnerName,
                            BankAccountNo = p.BankAccountNo,
                            BankCountryID = p.BankCountryID,
                            @IsDummy = p.IsDummy,
                            @Icon = p.GetPaymentMethod().GetImageUrl(),
                            @PaymentMethodCategory = p.GetPaymentMethod().Category.GetDisplayName().SafeHtmlEncode(),
                            @CardName = p.GetPaymentMethod().GetTitleHtml(),
                            @IsBelongsToPaymentMethod = p.IsBelongsToPaymentMethod(paymentMethodName),
                            @Visible = CheckPaymentMethod(paymentMethod),
                            @Url = this.Url.RouteUrl("Deposit", new { @action = "Prepare", @paymentMethodName = paymentMethod.UniqueName, @payCardID = p.ID }),
                        };
                    })
                    .OrderByDescending(p => p.IsBelongsToPaymentMethod)
                    .ToArray();
                return this.Json(new { @success = true, @payCards = payCards }, JsonRequestBehavior.AllowGet);
            }
            catch (GmException ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false, @error = GmException.TryGetFriendlyErrorMsg(ex) }, JsonRequestBehavior.AllowGet);
            }
        }

        public JsonResult GetUserAllPayCards()
        {
            try
            {
                if (!CustomProfile.Current.IsAuthenticated)
                    throw new UnauthorizedAccessException();

                var payCards = GamMatrixClient.GetPayCards()
                    .Where( p => p.SuccessDepositNumber > 0 && !p.IsDummy)
                   .Select(p =>
                   {
                       var paymentMethod = p.GetPaymentMethod();
                       if (paymentMethod == null)
                           return null;
                       return new
                       {
                           ID = p.ID.ToString(),
                           ExpiryDate = p.ExpiryDate.ToString("MM/yyyy"),
                           DisplayNumber = p.DisplayName,
                           RecordDisplayNumber = p.DisplayNumber,
                           BankName = p.BankName,
                           OwnerName = p.OwnerName,
                           BankAccountNo = p.BankAccountNo,
                           BankCountryID = p.BankCountryID,
                           @IsDummy = p.IsDummy,
                           @Icon = p.GetPaymentMethod().GetImageUrl(),
                           @PaymentMethodCategory = p.GetPaymentMethod().Category.GetDisplayName().SafeHtmlEncode(),
                           @CardName = p.GetPaymentMethod().GetTitleHtml(),
                           @Visible = CheckPaymentMethod(paymentMethod),
                           @Url = this.Url.RouteUrl("Deposit", new { @action = "Prepare", @paymentMethodName = paymentMethod.UniqueName, @payCardID = p.ID }),
                       };
                   })
                   .Where(o => o != null)
                   .ToArray();
                return this.Json(new { @success = true, @payCards = payCards }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
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

        /// <summary>
        /// the entropay popup
        /// </summary>
        /// <param name="sid"></param>
        /// <returns></returns>
        public ActionResult EntroPay(string sid)
        {
            PrepareTransRequest prepareTransRequest = cmTransParameter.ReadObject<PrepareTransRequest>(sid, "PrepareTransRequest");
            return View("EntroPay", prepareTransRequest);
        }

        /// <summary>
        /// the entropay popup
        /// </summary>
        /// <param name="sid"></param>
        /// <returns></returns>
        public ActionResult DeclindedDeposit(string sid)
        {
            PrepareTransRequest prepareTransRequest = cmTransParameter.ReadObject<PrepareTransRequest>(sid, "PrepareTransRequest");
            return View("DeclindedDeposit", prepareTransRequest);
        }

        public ActionResult InPayInformation(string sid)
        {
            return View();
        }

        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult DepositBonusInfo(long gammingAccountID, string currency, string amount)
        {
            try
            {
                var account = GamMatrixClient.GetUserGammingAccounts(CustomProfile.Current.UserID).FirstOrDefault(a => a.ID == gammingAccountID);
                decimal requestAmount = decimal.Parse(Regex.Replace(amount, @"[^\d\.]", string.Empty), CultureInfo.InvariantCulture);

                if (account != null)
                {
                    this.ViewData["VendorID"] = account.Record.VendorID;

                    using (GamMatrixClient client = GamMatrixClient.Get())
                    {
                        if (account.Record.VendorID == VendorID.NetEnt && requestAmount > 0)
                        {
                            NetEntAPIRequest request = new NetEntAPIRequest()
                            {
                                GetDepositBonusAmountForPlayer = true,
                                GetDepositBonusAmountForPlayerDepositCurrency = currency,
                                GetDepositBonusAmountForPlayerDepositAmount = requestAmount,
                                UserID = CustomProfile.Current.UserID,
                            };
                            request = client.SingleRequest<NetEntAPIRequest>(request);
                            this.ViewData["BonusAmount"] = request.GetDepositBonusAmountForPlayerResponse;
                            this.ViewData["BonusCurrency"] = currency;

                        }
                    }

                    return View("DepositBonusInfo", account.Record.VendorID);
                }

            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Content(string.Empty, "text/html");
            }

            return this.Content(string.Empty, "text/html");

        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public JsonResult SendEnterCashVerificationCode(long bankID, string phoneNumber)
        {
            if (bankID < 0 || string.IsNullOrWhiteSpace(phoneNumber))
                throw new ArgumentNullException();

            using (GamMatrixClient client = GamMatrixClient.Get())
            {
                EnterCashSendVerificationCodeRequest request = client.SingleRequest<EnterCashSendVerificationCodeRequest>(
                    new EnterCashSendVerificationCodeRequest()
                    {
                        BankId = bankID,
                        PhoneNumber = phoneNumber,
                    });

                if (request.Data.Status.Equals("ok", StringComparison.InvariantCultureIgnoreCase))
                    return this.Json(new { @success = true });
            }

            return this.Json(new { @success = false });
        }

        #region Quick Deposit
        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public void ProcessQuickDepositTransactionAsync(string paymentMethodName
            , long gammingAccountID
            , string currency
            , string amount
            , long payCardID
            , string securityKey
            , string iovationBlackBox = null
            )
        {
            var iovationResult = IovationCheck(iovationBlackBox);
            if (iovationResult != null)
            {
                //deny ,return ;
                AsyncManager.Parameters["iovationResult"] = iovationResult;
                return;
            }

            try
            {
                AsyncManager.Parameters["isRegularDeposit"] = false;
                PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
                .FirstOrDefault(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.InvariantCultureIgnoreCase));
                if (paymentMethod == null)
                    throw new ArgumentOutOfRangeException();

                var allowVendorIDs = new[]
                {
                    VendorID.PaymentTrust,
                    VendorID.Neteller,
                    VendorID.Moneybookers,
                    VendorID.MoneyMatrix
                };

                if (!allowVendorIDs.Contains(paymentMethod.VendorID))
                    throw new NotSupportedException();

                //use for process trans request
                AsyncManager.Parameters["postBackURL"] = this.Url.RouteUrlEx("Deposit", new { @action = "Postback", @paymentMethodName = paymentMethodName, @sid = "_SID_", @isQuickDeposit = true });
                AsyncManager.Parameters["returnURL"] = this.Url.RouteUrlEx("Deposit", new { @action = "Return", @isQuickDeposit = true });
                AsyncManager.Parameters["sessionID"] = GamMatrixClient.GetSessionIDForCurrentOperator();
                AsyncManager.Parameters["userID"] = CustomProfile.Current.UserID;
                AsyncManager.Parameters["userIP"] = global::System.Web.HttpContext.Current.Request.GetRealUserAddress();
                AsyncManager.Parameters["userSessionID"] = CustomProfile.Current.SessionID;
                AsyncManager.Parameters["securityKey"] = securityKey;

                if (paymentMethod.ResourceKey == "MoneyMatrix_Neteller")
                {
                    var pcNickAlias = Request.Form.GetValues("payCardNickAlias").FirstOrDefault();
                    if (!string.IsNullOrEmpty(pcNickAlias))
                        AsyncManager.Parameters["NetellerEmailAddressOrAccountId"] = pcNickAlias;
                    AsyncManager.Parameters["NetellerSecret"] = securityKey;
                }
                if (paymentMethod.ResourceKey == "MoneyMatrix_Skrill")
                {
                    var pcNickAlias = Request.Form.GetValues("payCardNickAlias").FirstOrDefault();
                    if (!string.IsNullOrEmpty(pcNickAlias))
                        AsyncManager.Parameters["SkrillEmailAddress"] = pcNickAlias;
                }

                PrepareQuickDepositTransaction(paymentMethodName
                , gammingAccountID
                , currency
                , amount
                , payCardID
                , iovationBlackBox);

                AsyncManager.OutstandingOperations.Increment();
            }
            catch (Exception ex)
            {
                AsyncManager.Parameters["exception"] = ex;
            }
        }

        private void PrepareQuickDepositTransaction(string paymentMethodName
            , long gammingAccountID
            , string currency
            , string amount
            , long payCardID
            , string iovationBlackBox = null
            )
        {
            AsyncManager.Parameters["paymentMethodName"] = paymentMethodName;
            AsyncManager.Parameters["gammingAccountID"] = gammingAccountID;
            AsyncManager.Parameters["currency"] = currency;
            AsyncManager.Parameters["amount"] = amount;
            AsyncManager.Parameters["payCardID"] = payCardID;
            AsyncManager.Parameters["bonusCode"] = string.Empty;
            AsyncManager.Parameters["issuer"] = string.Empty;
            AsyncManager.Parameters["outRange"] = "0";
            if (iovationBlackBox != null)
                AsyncManager.Parameters["iovationBlackBox"] = iovationBlackBox;

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
                                PaymentType = null,
                                TempExternalReference = null,
                            },
                            IovationBlackBox = iovationBlackBox,
                            IsWindowOwner = false,
                            IsRequiredRedirectForm = true,
                            RedirectFormName = "depositForm",
                            RedirectFormTarget = "_self",
                            IsRequiredRedirectURL = false,
                            PostBackURL = this.Url.RouteUrlEx("Deposit", new { @action = "Postback", @paymentMethodName = paymentMethodName, @isQuickDeposit = true }),
                            PostBackURLTarget = "_self",
                            CancelURL = this.Url.RouteUrlEx("Deposit", new { @action = "Cancel", @isQuickDeposit = true }),
                            CancelURLTarget = "_self",
                            ReturnURL = this.Url.RouteUrlEx("Deposit", new { @action = "Return", @isQuickDeposit = true }),
                            ReturnURLTarget = "_self",
                            //DepositSource = DepositSource.QuickDepositPage,
                        };

                        // for MB and Dotpay, pass the sub code
                        if (paymentMethod.VendorID == VendorID.Moneybookers ||
                            paymentMethod.VendorID == VendorID.Dotpay ||
                            paymentMethod.VendorID == VendorID.PayAnyWay)
                        {
                            if (!string.IsNullOrEmpty(paymentMethod.SubCode))
                            {
                                prepareTransRequest.PaymentMethods = new List<string>() { paymentMethod.SubCode };
                            }
                        }

                        if (paymentMethod.VendorID == VendorID.MoneyMatrix)
                        {
                            if (!string.IsNullOrEmpty(paymentMethod.SubCode))
                            {
                                prepareTransRequest.PaymentMethods = new List<string>() { paymentMethod.SubCode };
                                if (paymentMethod.ResourceKey == "MoneyMatrix_Neteller")
                                {
                                    prepareTransRequest.RequestFields = new Dictionary<string, string>
                                    {
                                        {"NetellerEmailAddressOrAccountId", AsyncManager.Parameters["NetellerEmailAddressOrAccountId"].ToString()},
                                        {"NetellerSecret", AsyncManager.Parameters["NetellerSecret"].ToString()}
                                    };
                                }
                                if (paymentMethod.ResourceKey == "MoneyMatrix_Skrill")
                                {
                                    prepareTransRequest.RequestFields = new Dictionary<string, string>
                                    {
                                        {"SkrillEmailAddress", AsyncManager.Parameters["SkrillEmailAddress"].ToString()}
                                    };
                                }
                            }
                        }

                        GamMatrixClient.SingleRequestAsync<PrepareTransRequest>(prepareTransRequest
                            , OnPrepareQuickDepositTransactionCompleted
                            );
                    }
                    else
                    {
                        AsyncManager.Parameters["outRange"] = "1";
                    }

                }// using
            }//if
        }

        private void OnPrepareQuickDepositTransactionCompleted(AsyncResult reply)
        {
            try
            {
                var prepareTransRequest = reply.EndSingleRequest().Get<PrepareTransRequest>();

                if (string.Compare("1", AsyncManager.Parameters["outRange"].ToString(), false) == 0)
                    throw new Exception("OUTRANGE");

                string sid = prepareTransRequest.Record.Sid;

                cmTransParameter.SaveObject<PrepareTransRequest>(prepareTransRequest.Record.Sid
                    , "PrepareTransRequest"
                    , prepareTransRequest
                    );
                //cmTransParameter.SaveObject<string>(prepareTransRequest.Record.Sid
                //    , "UserID"
                //    , CustomProfile.Current.UserID.ToString()
                //    );
                cmTransParameter.SaveObject<string>(prepareTransRequest.Record.Sid
                    , "UserID"
                    , AsyncManager.Parameters["userID"].ToString()
                    );
                //cmTransParameter.SaveObject<string>(prepareTransRequest.Record.Sid
                //    , "SessionID"
                //    , CustomProfile.Current.SessionID
                //    );
                cmTransParameter.SaveObject<string>(prepareTransRequest.Record.Sid
                    , "SessionID"
                    , AsyncManager.Parameters["userSessionID"].ToString()
                    );
                cmTransParameter.SaveObject<string>(prepareTransRequest.Record.Sid
                    , "SuccessUrl"
                    , prepareTransRequest.ReturnURL
                    );
                cmTransParameter.SaveObject<string>(prepareTransRequest.Record.Sid
                    , "CancelUrl"
                    , prepareTransRequest.CancelURL
                    );

                string securityKey = AsyncManager.Parameters["securityKey"].ToString();

                if (!string.IsNullOrWhiteSpace(securityKey))
                    cmTransParameter.SaveObject<string>(sid, "SecurityKey", securityKey.DefaultEncrypt());

                var paymentMethodName = AsyncManager.Parameters["paymentMethodName"].ToString();

                ProcessQuickDepositTransaction(paymentMethodName, sid);
            }
            catch (Exception ex)
            {
                AsyncManager.Parameters["exception"] = ex;
                AsyncManager.OutstandingOperations.Decrement();
            }
        }

        public void ProcessQuickDepositTransaction(string paymentMethodName, string sid)
        {
            try
            {
                AsyncManager.Parameters["paymentMethodName"] = paymentMethodName;
                AsyncManager.Parameters["sid"] = sid;

                PrepareTransRequest prepareTransRequest = cmTransParameter.ReadObject<PrepareTransRequest>(sid, "PrepareTransRequest");
                if (prepareTransRequest == null)
                    throw new ArgumentOutOfRangeException("sid");

                AsyncManager.Parameters["prepareTransRequest"] = prepareTransRequest;

                if (prepareTransRequest.Record.Status == PreTransStatus.Setup)
                {
                    using (GamMatrixClient client = GamMatrixClient.Get())
                    {
                        ProcessTransRequest processTransRequest = new ProcessTransRequest()
                        {
                            SID = sid,
                            IsFirstDepositBonusTCAccepted = true, //cmTransParameter.ReadObject<bool>(sid, "BonusAccepted"),
                            IsRequiredRedirectForm = true,
                            RedirectFormName = "depositForm",
                            RedirectFormTarget = "_self",
                            IsRequiredRedirectURL = false,
                            //PostBackURL = this.Url.RouteUrlEx("Deposit", new { @action = "Postback", @paymentMethodName = paymentMethodName, @sid = sid }),
                            PostBackURL = AsyncManager.Parameters["postBackURL"].ToString().Replace("_SID_", sid),
                            SecretKey = cmTransParameter.ReadObject<string>(sid, "SecurityKey").DefaultDecrypt(),
                            InputValue1 = cmTransParameter.ReadObject<string>(sid, "InputValue1").DefaultDecrypt(),
                            InputValue2 = cmTransParameter.ReadObject<string>(sid, "InputValue2").DefaultDecrypt(),
                            //ReturnURL = this.Url.RouteUrlEx("Deposit", new { @action = "Return" }),
                            ReturnURL = AsyncManager.Parameters["returnURL"].ToString(),
                            SESSION_ID = AsyncManager.Parameters["sessionID"].ToString(),
                            SESSION_USERID = Convert.ToInt64(AsyncManager.Parameters["userID"]),
                            SESSION_USERIP = AsyncManager.Parameters["userIP"].ToString(),
                            SESSION_USERSESSIONID = AsyncManager.Parameters["userSessionID"].ToString(),
                        };
                        if (AsyncManager.Parameters.ContainsKey("iovationBlackBox"))
                        {
                            processTransRequest.IovationBlackBox = AsyncManager.Parameters["iovationBlackBox"].ToString();
                        }
                        GamMatrixClient.SingleRequestAsync<ProcessTransRequest>(processTransRequest, OnProcessTransactionCompleted);
                    }
                }
                else
                {
                    AsyncManager.OutstandingOperations.Decrement();
                }
            }
            catch (Exception ex)
            {
                AsyncManager.Parameters["exception"] = ex;
            }
        }

        public ActionResult ProcessQuickDepositTransactionCompleted(PrepareTransRequest prepareTransRequest
            , ProcessTransRequest processTransRequest
            , string paymentMethodName
            , string sid
            , Exception exception
            , JsonResult iovationResult = null
            )
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return View("Anonymous");

            if (iovationResult != null)
                return iovationResult;

            try
            {
                if (exception != null)
                    throw exception;

                string receiptUrl = this.Url.RouteUrlEx("Deposit", new { @action = "Receipt", @paymentMethodName = paymentMethodName, @sid = prepareTransRequest.Record.Sid });

                CustomProfile.Current.Set("ReceiptUrl", receiptUrl);
                CustomProfile.Current.Set("Sid", sid);

                if (prepareTransRequest.Record.Status == PreTransStatus.Setup)
                {
                    processTransRequest.InputValue1 = cmTransParameter.Mask(sid, "InputValue1", processTransRequest.InputValue1);
                    processTransRequest.InputValue2 = cmTransParameter.Mask(sid, "InputValue2", processTransRequest.InputValue2);
                    processTransRequest.SecretKey = cmTransParameter.Mask(sid, "SecurityKey", processTransRequest.SecretKey);
                    cmTransParameter.SaveObject<ProcessTransRequest>(sid, "ProcessTransRequest", processTransRequest);

                    if (processTransRequest.Record.Status == PreTransStatus.Success)
                    {
                        SendReceiptEmail(paymentMethodName, sid);
                        this.ViewData["RedirectUrl"] = string.Format(CultureInfo.InvariantCulture, "/Deposit/Receipt/{0}/{1}", paymentMethodName, sid);
                        return this.Json(new
                        {
                            @success = true,
                            @status = TransactionStatus.success.ToString(),
                            @sid = prepareTransRequest.Record.Sid,
                            //@redirectUrl = string.Format(CultureInfo.InvariantCulture, "/Deposit/Receipt/{0}/{1}", paymentMethodName, sid)
                        });
                    }
                    else if (processTransRequest.Record.Status == PreTransStatus.AsyncSent)
                    {
                        cmTransParameter.SaveObject<string>(sid, "RedirectForm", processTransRequest.RedirectForm);
                        return this.Json(new
                        {
                            @success = true,
                            @status = TransactionStatus.redirection.ToString(),
                            @sid = prepareTransRequest.Record.Sid,
                            //@redirectUrl = string.Format(CultureInfo.InvariantCulture, "/Deposit/QuickDepositWidget/Dialog/{0}/{1}", paymentMethodName, sid)
                        });
                    }
                }
                else if (prepareTransRequest.Record.Status == PreTransStatus.AsyncSent)
                {
                    cmTransParameter.SaveObject<string>(sid, "RedirectForm", prepareTransRequest.RedirectForm);
                    return this.Json(new
                    {
                        @success = true,
                        @status = TransactionStatus.redirection.ToString(),
                        @sid = prepareTransRequest.Record.Sid,
                        //@redirectUrl = string.Format(CultureInfo.InvariantCulture, "/Deposit/QuickDepositWidget/Dialog/{0}/{1}", paymentMethodName, sid)
                    });
                }

                throw new InvalidOperationException();
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                string friendlyError = GmException.TryGetFriendlyErrorMsg(ex);
                cmTransParameter.SaveObject<string>(sid, "LastError", friendlyError);
                return this.Json(new
                {
                    @success = false,
                    @error = friendlyError,
                });
            }
        }

        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult QuickDepositFormRedirect(string sid)
        {
            string redirectForm = cmTransParameter.ReadObject<string>(sid, "RedirectForm");
            if (string.IsNullOrWhiteSpace(redirectForm))
                throw new ArgumentOutOfRangeException("sid");

            this.ViewData["FormHtml"] = redirectForm;

            return View("PaymentFormPost");
        }
        #endregion

        public ActionResult NetellerQuickRegister(string returnUrl)
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return View("Anonymous");

            string countryCode = string.Empty;
            List<CountryInfo> lstCountry = CountryManager.GetAllCountries();
            if (lstCountry.Exists(n => n.InternalID == CustomProfile.Current.UserCountryID))
            {
                countryCode = lstCountry.FindLast(n =>
                {
                    return (n.InternalID == CustomProfile.Current.UserCountryID);
                }).ISO_3166_Alpha2Code;
            }

            UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
            cmUser user = ua.GetByID(CustomProfile.Current.UserID);

            GetNetellerMerchantInfoRequest request = new GetNetellerMerchantInfoRequest();
            using (GamMatrixClient client = GamMatrixClient.Get())
            {
                request = client.SingleRequest(request);
                if (string.IsNullOrWhiteSpace(request.MerchantID) ||
                string.IsNullOrWhiteSpace(request.MerchantKey))
                {
                    throw new Exception("The NETELLER quick signup is not configured in GmCore.");
                }
            }

            ViewData["returnUrl"] = returnUrl;
            ViewData["merchantid"] = request.MerchantID.SafeHtmlEncode();
            ViewData["merchant"] = request.MerchantKey.SafeHtmlEncode();

            ViewData["currency"] = user.Currency.SafeHtmlEncode();
            ViewData["firstname"] = user.FirstName.SafeHtmlEncode();
            ViewData["lastname"] = user.Surname.SafeHtmlEncode();
            ViewData["email"] = user.Email.SafeHtmlEncode();
            ViewData["address"] = user.Address1.SafeHtmlEncode();
            ViewData["address2"] = user.Address2.SafeHtmlEncode();
            ViewData["city"] = user.City.SafeHtmlEncode();
            ViewData["country"] = countryCode;
            ViewData["postcode"] = user.Zip.SafeHtmlEncode();

            if (!string.IsNullOrWhiteSpace(user.Mobile))
            {
                ViewData["phone2"] = user.Mobile.SafeHtmlEncode();
                ViewData["phone2type"] = "mobile";
            }
            if (!string.IsNullOrWhiteSpace(user.Phone))
            {
                ViewData["phone2"] = user.Phone.SafeHtmlEncode();
                ViewData["phone2type"] = "landLine";
            }
            if (user.Birth.HasValue)
            {
                ViewData["dob"] = user.Birth.Value.ToString("MM/DD/YYYY");
            }
            if (string.Equals(user.Gender, "M", StringComparison.InvariantCultureIgnoreCase) ||
                    string.Equals(user.Gender, "F", StringComparison.InvariantCultureIgnoreCase))
            {
                ViewData["gender"] = user.Gender.ToLowerInvariant();
            }
            if (!string.IsNullOrWhiteSpace(user.Language))
            {
                string lang = user.Language.Truncate(2).ToLowerInvariant();
                switch (lang)
                {
                    case "da":
                    case "de":
                    case "es":
                    case "fr":
                    case "it":
                    case "ja":
                    case "no":
                    case "pl":
                    case "pt":
                    case "ru":
                    case "sv":
                    case "tr":
                        break;

                    default:
                        lang = "en";
                        break;
                }
                ViewData["lang"] = lang;
            }

            return View("NetellerQuickRegister");
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public JsonResult Rollback(string sid)
        {
            try
            {
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    GetTransInfoRequest getTransInfoRequest = client.SingleRequest<GetTransInfoRequest>(new GetTransInfoRequest()
                    {
                        SID = sid,
                        NoDetails = true,
                    });

                    bool isAllowed = false;
                    if (getTransInfoRequest.TransData.TransStatus == TransStatus.Pending && getTransInfoRequest.TransData.TransType == TransType.Withdraw)
                    {
                        if (Settings.PendingWithdrawal_EnableApprovement)
                            isAllowed = !getTransInfoRequest.TransData.ApprovalStatus;
                        else
                            isAllowed = getTransInfoRequest.TransData.CreditPayItemVendorID != VendorID.PaymentTrust
                               && getTransInfoRequest.TransData.CreditPayItemVendorID != VendorID.PayPoint
                               && getTransInfoRequest.TransData.CreditPayItemVendorID != VendorID.Envoy
                               && getTransInfoRequest.TransData.CreditPayItemVendorID != VendorID.Bank
                               && getTransInfoRequest.TransData.CreditPayItemVendorID != VendorID.PaymentTrust
                               && getTransInfoRequest.TransData.CreditPayItemVendorID != VendorID.PayPoint
                               && getTransInfoRequest.TransData.CreditPayItemVendorID != VendorID.Envoy
                               && getTransInfoRequest.TransData.CreditPayItemVendorID != VendorID.Bank;
                    }

                    if (!isAllowed)
                    {
                        throw new InvalidOperationException();
                    }

                    if (getTransInfoRequest.TransData.TransStatus == TransStatus.Pending)
                    {

                        DivertTransRequest divertTransRequest = client.SingleRequest<DivertTransRequest>(new DivertTransRequest()
                        {
                            SID = sid,
                            DivertAccountID = getTransInfoRequest.TransData.DebitAccountID
                        });
                    }

                    if (getTransInfoRequest.TransData.TransStatus == TransStatus.Pending ||
                        getTransInfoRequest.TransData.TransStatus == TransStatus.RollBack)
                    {
                        return this.Json(new { @success = true, @transID = getTransInfoRequest.TransData.TransID });
                    }
                    throw new InvalidOperationException();
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return this.Json(new { @success = false });
            }
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [ValidateInput(false)]
        public void PugglePayPostbackAsync(string paymentMethodName, string sid, string authorizationID)
        {
            if (string.IsNullOrWhiteSpace(sid))
                sid = Request["gm_sid"].DefaultIfNullOrEmpty(Request["transaction_id"]);

            if (string.IsNullOrWhiteSpace(sid))
                throw new ArgumentNullException("sid");

            AsyncManager.Parameters["sid"] = sid;
            AsyncManager.Parameters["paymentMethodName"] = paymentMethodName;

            PugglePayProcessAsyncTransRequest pugglePayProcessAsyncTransRequest = new PugglePayProcessAsyncTransRequest()
            {
                Sid = sid,
                AuthorizationId = authorizationID,
            };

            GamMatrixClient.SingleRequestAsync<PugglePayProcessAsyncTransRequest>(pugglePayProcessAsyncTransRequest
                , OnPugglePayPostbackCompleted
                );

            AsyncManager.OutstandingOperations.Increment();
        }

        private void OnPugglePayPostbackCompleted(AsyncResult result)
        {
            try
            {
                AsyncManager.Parameters["pugglePayProcessAsyncTransRequest"]
                    = result.EndSingleRequest().Get<PugglePayProcessAsyncTransRequest>();
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

        public ActionResult PugglePayPostbackCompleted(PugglePayProcessAsyncTransRequest pugglePayProcessAsyncTransRequest
            , string paymentMethodName
            , string sid
            , Exception exception
            )
        {
            try
            {
                if (exception != null)
                    throw exception;

                cmTransParameter.SaveObject<PugglePayProcessAsyncTransRequest>(sid, "PugglePayProcessAsyncTransRequest", pugglePayProcessAsyncTransRequest);

                SendReceiptEmail(paymentMethodName, sid);
                return this.Json(new
                {
                    @success = true,
                });
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                string friendlyError = GmException.TryGetFriendlyErrorMsg(ex);
                cmTransParameter.SaveObject<string>(sid, "LastError", friendlyError);
                return this.Json(new
                {
                    @success = false,
                    @error = friendlyError,
                });
            }
        }

        private string AcceptTheTerms(TermsConditionsChange termsId)
        {
            try
            {
                UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                cmUser user = ua.GetByID(CustomProfile.Current.UserID);
                if (!user.IsTCAcceptRequired.HasFlag(termsId))
                    ua.SetTermsConditionsFlagByUserID(CustomProfile.Current.UserID, termsId);
                return "Success";
            }
            catch (Exception e)
            {
                return e.Message.ToString();
            }

        }


        public JsonResult AcceptUKTerms(string status)
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return Json(new { Success = false, msg = "Anonymous player" });
            if (!(CustomProfile.Current.UserCountryID == 230 || Settings.IsUKLicense))
                return Json(new { Success = false, msg = "the operator is disable the UK License" });
            if (string.IsNullOrWhiteSpace(status))
                return Json(new { Success = false, msg = "status is empty." });
            try
            {
                if (status.Equals("1", StringComparison.InvariantCultureIgnoreCase))
                {
                    string updateResultMsg = this.AcceptTheTerms(TermsConditionsChange.UKLicense);
                    bool upstatus = updateResultMsg.Equals("Success", StringComparison.InvariantCultureIgnoreCase);
                    return Json(new { Success = upstatus, msg = updateResultMsg });
                }
                else
                {
                    return Json(new { Success = false, msg = "error status." });
                }
            }
            catch (Exception e)
            {
                return Json(new { Success = false, msg = e.Message });
            }
        }
        public JsonResult AcceptTerms(int termsId)
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return Json(new { Success = false, msg = "Anonymous player" });
            //if (!Settings.IsUKLicense)
            //    return Json(new { Success = false, msg = "the operator is disable the UK License" });
            if (termsId == 0)
                return Json(new { Success = false, msg = "status is empty." });
            try
            {
                string updateResultMsg = this.AcceptTheTerms((TermsConditionsChange)termsId);
                bool upstatus = updateResultMsg.Equals("Success", StringComparison.InvariantCultureIgnoreCase);
                return Json(new { Success = upstatus, msg = updateResultMsg });
            }
            catch (Exception e)
            {
                return Json(new { Success = false, msg = e.Message });
            }
        }

        public JsonResult GetTxtNationRedirectUrl(
            decimal amount,
            long userId,
            string windowSize,
            string bonusCode,
            string bonusVendor,
            long gammingAccountID)
        {
            var success = true;
            var data = string.Empty;
            long txtNationTransID = 0L;

            try
            {
                var request = new GamMatrixAPI.GetTxtNationPaymentFormURLRequest
                {
                    Amount = amount,
                    UserID = userId,
                    WindowSize = windowSize
                };

                if (!string.IsNullOrWhiteSpace(bonusCode))
                {
                    VendorID bonusVendorID = VendorID.Unknown;

                    List<AccountData> accounts = GamMatrixClient.GetUserGammingAccounts(CustomProfile.Current.UserID);
                    AccountData account = accounts.FirstOrDefault(a => a.ID == gammingAccountID);

                    if (account != null)
                    {
                        if (!string.IsNullOrWhiteSpace(bonusVendor))
                        {
                            Enum.TryParse(bonusVendor, out bonusVendorID);
                        }
                        if (bonusVendorID == VendorID.Unknown)
                            bonusVendorID = account.Record.VendorID;

                        bonusCode = bonusCode.Trim();
                    }

                    request.ApplyBonusCode = bonusCode;
                    request.ApplyBonusVendorID = bonusVendorID;
                }

                using (GamMatrixClient client = new GamMatrixClient())
                {
                    request = client.SingleRequest<GetTxtNationPaymentFormURLRequest>(request);
                }

                data = request.RedirectURL;
                txtNationTransID = request.TxtNationTransID;
            }
            catch (Exception ex)
            {
                success = false;
                data = ex.Message;
            }

            return Json(new { Success = success, Data = data, TxtNationTransID = txtNationTransID });
        }

        public JsonResult GetTxtNationSessionId(long txtNationTransID)
        {
            var success = true;
            var message = string.Empty;
            string sessionId = string.Empty;

            try
            {
                var request = new GamMatrixAPI.GetTxtNationSidRequest
                {
                    TxtNationTransID = txtNationTransID
                };

                using (GamMatrixClient client = new GamMatrixClient())
                {
                    request = client.SingleRequest<GetTxtNationSidRequest>(request);
                }

                sessionId = request.Sid;
            }
            catch (Exception ex)
            {
                message = ex.Message;
            }

            return Json(new { Success = success, Message = message, SessionId = sessionId });
        }

        public ActionResult TxtNationSuccess()
        {
            this.ViewData["RedirectUrl"] = "/Deposit/";
            return View("SuccessRedirect");
        }

        public ActionResult TxtNationFail()
        {
            this.ViewData["RedirectUrl"] = "/Error/";
            return View("SuccessRedirect");
        }

        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult ReceiptTxtNation(long txtNationTransID)
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return View("Anonymous");

            var paymentMethodName = VendorID.TxtNation.ToString();

            var sid = string.Empty;

            var request = new GamMatrixAPI.GetTxtNationSidRequest
            {
                TxtNationTransID = txtNationTransID
            };

            using (GamMatrixClient client = new GamMatrixClient())
            {
                request = client.SingleRequest<GetTxtNationSidRequest>(request);
            }

            sid = request.Sid;

            if (string.IsNullOrEmpty(sid))
            {
                return View("NotCompleted");
            }

            return Receipt(paymentMethodName, sid);
        }


        #region
        private readonly string __LimitSet_POP_COOKIE_KEY = "__limitset_pop_{0}";
        [HttpGet]
        public void LimitSetPopupAsync()
        {
            AsyncManager.Parameters["showPopup"] = false;

            if (CustomProfile.Current.IsAuthenticated && Settings.LimitSetPopup.Enabled)
            {
                if (Request.Cookies.AllKeys.Contains(string.Format(__LimitSet_POP_COOKIE_KEY, CustomProfile.Current.UserID)))
                {
                    AsyncManager.Parameters["hasCookie"] = true;
                    return;
                }
                TransSelectParams transSelectParams = new TransSelectParams()
                {
                    ByTransTypes = true,
                    ParamTransTypes = new List<TransType> { TransType.Deposit, TransType.Vendor2User },
                    ByUserID = true,
                    ParamUserID = CustomProfile.Current.UserID,
                    ByTransStatuses = true,
                    ParamTransStatuses = new List<TransStatus>
                    {
                        TransStatus.Success,
                    },
                    ByDebitPayableTypes = true,
                };

                transSelectParams.ParamDebitPayableTypes = Enum.GetNames(typeof(PayableType))
                    .Select(t => (PayableType)Enum.Parse(typeof(PayableType), t))
                    .Where(t => t != PayableType.AffiliateFee && t != PayableType.CasinoFPP)
                    .ToList();

                AsyncManager.OutstandingOperations.Increment();
                GamMatrixClient.GetTransactionsAsync(transSelectParams, 1, 1, OnGetTransactions);
            }
        }

        public void OnGetTransactions(List<TransInfoRec> transInfoRecs)
        {
            if (transInfoRecs == null || transInfoRecs.Count == 0)
            {
                AsyncManager.Parameters["showPopup"] = true;
            }
            AsyncManager.OutstandingOperations.Decrement();
        }

        public ActionResult LimitSetPopupCompleted(bool showPopup, bool hasCookie)
        {
            if (CustomProfile.Current.IsAuthenticated)
            {
                try
                {
                    if (!hasCookie)
                    {
                        HttpCookie cookie = new HttpCookie(string.Format(__LimitSet_POP_COOKIE_KEY, CustomProfile.Current.UserID), showPopup.ToString());
                        cookie.Path = "/";
                        cookie.Expires = DateTime.Now.AddYears(99);
                        Response.Cookies.Add(cookie);
                    }
                    if (showPopup)
                    {
                        return View("/Deposit/LimitSetPopup");
                    }
                }
                catch (Exception exception)
                {
                    Logger.Exception(exception);
                }
            }

            return new EmptyResult();
        }
        #endregion

    }
}
