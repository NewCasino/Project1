using System;
using System.Collections.Generic;
using System.Configuration;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Net;
using System.Text;
using System.Text.RegularExpressions;
using System.Web.Mvc;
using System.Xml.Linq;
using CM.Content;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.State;
using CM.Web;
using Finance;
using GamMatrix.CMS.Models.MobileShared.Components;
using GamMatrix.CMS.Models.MobileShared.Deposit;
using GamMatrix.CMS.Models.MobileShared.Deposit.Prepare;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Controllers.MobileShared
{
    [HandleError]
    [MasterPageViewData(Name = "CurrentSectionMarkup", Value = "DepositSection")]
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{paymentMethodName}/{sid}")]
    public class MobileDepositController : AsyncControllerEx
    {
        [RequireLogin]
        public ActionResult Index(string currency, int? countryID)
        {
            if (CustomProfile.Current.IsInRole("Withdraw only"))
                return View("GamblingRegulationsRestriction");

            List<CurrencyData> currencies = GamMatrixClient.GetSupportedCurrencies().FilterForCurrentDomain();
            if (!string.IsNullOrEmpty(currency))
            {
                currency = currency.ToUpperInvariant();
                if (!currencies.Exists(c => string.Equals(c.ISO4217_Alpha, currency, StringComparison.InvariantCulture)))
                {
                    currency = null;
                }
            }
            else
                currency = null;

            if (currency == null)
                currency = CustomProfile.Current.UserCurrency;

            this.ViewData["Currency"] = currency;

            if (!countryID.HasValue)
                countryID = CustomProfile.Current.UserCountryID;

            this.ViewData["CountryID"] = countryID.Value;

            return View("Index");
        }

        [HttpGet]
        [RequireLogin]
        public ActionResult Account(string paymentMethodName)
        {
            UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
            cmUser user = ua.GetByID(CustomProfile.Current.UserID);

            if (!user.IsEmailVerified)
                return View("EmailNotVerified");
            else if (!CustomProfile.Current.IsEmailVerified)
                CustomProfile.Current.IsEmailVerified = true;

            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
                .FirstOrDefault(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.InvariantCultureIgnoreCase));
            if (paymentMethod == null)
                throw new ArgumentOutOfRangeException();

            if (!CheckPaymentMethod(paymentMethod))
                return RedirectToIndex();

            if (paymentMethod.VendorID == VendorID.Bank)
                return View("InfoBank");

            if (CustomProfile.Current.IsInRole("Incomplete Profile"))
            {
                return View("IncompleteProfile");
            }

            if (CustomProfile.Current.IsInRole(paymentMethod.DenyAccessRoleNames))
                return View("AccessDenied");

            if (paymentMethod.VendorID == VendorID.IPSToken)
                return View("IPSToken", paymentMethod);

            if (paymentMethod.VendorID == VendorID.EnterCash)
                return View("EnterCash", paymentMethod);

            return View(paymentMethod);
        }

        protected bool CheckPaymentMethod(PaymentMethod paymentMethod)
        {
            if (Settings.Deposit_SkipPaymentMethodCheck)
                return true;

            PaymentMethod[] paymentMethods = PaymentMethodManager.GetPaymentMethods().ToArray();

            var query = paymentMethods.Where(p => p.IsAvailable && p.SupportDeposit);

            //Hide EnterCash_Siru, it is not supported in mobile
            query = query.Where(p => p.UniqueName != "EnterCash_Siru");

            int countryID = CustomProfile.Current.UserCountryID;
            string currency = CustomProfile.Current.UserCurrency;

            if (countryID > 0)
                query = query.Where(p => p.SupportedCountries.Exists(countryID));

            var list = query.ToArray();

            var query2 = list.Where(p => p.RepulsivePaymentMethods == null ||
                p.RepulsivePaymentMethods.Count == 0 ||
                !p.RepulsivePaymentMethods.Exists(p2 => list.FirstOrDefault(p3 => p3.UniqueName == p2) != null)
                );

            paymentMethods = query2.ToArray();

            return paymentMethods.Contains(paymentMethod);
        }

        private RedirectResult RedirectToIndex()
        {
            return Redirect(Url.RouteUrl("Deposit", new { action = "Index" }));
        }

        [HttpGet]
        public virtual RedirectResult Prepare()
        {
            return RedirectToIndex();
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [RequireLogin]
        public virtual ActionResult Prepare(string paymentMethodName)
        {
            if (!CustomProfile.Current.IsEmailVerified)
            {
                UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                cmUser user = ua.GetByID(CustomProfile.Current.UserID);
                if (!user.IsEmailVerified)
                    return View("EmailNotVerified");
                else if (!CustomProfile.Current.IsEmailVerified)
                    CustomProfile.Current.IsEmailVerified = true;
            }

            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
                .FirstOrDefault(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.InvariantCultureIgnoreCase));
            if (paymentMethod == null)
                throw new ArgumentOutOfRangeException();

            if (paymentMethod.SimultaneousDepositLimit > 0)
            {
                if (paymentMethod.SimultaneousDepositLimit <= GamMatrixClient.GetPendingDepositCount(paymentMethod.VendorID, CustomProfile.Current.UserID))
                    return View("SimultaneousDepositDenied");
            }

            var stateVars = new Dictionary<string, string>
            {
                { "amount" , Request.Form["amount"] },
                { "bonusCode" , Request.Form["bonusCode"] },
                { "bonusVendor" , Request.Form["bonusVendor"] },
                { "creditAccountID" , Request.Form["creditAccountID"] },
                { "currency" , Request.Form["currency"] },
            };

            switch (paymentMethod.VendorID)
            {
                case VendorID.Neteller:
                    return View("PrepareNeteller", new PrepareNetellerViewModel(paymentMethod, stateVars));

                case VendorID.Ukash:
                    return View("PrepareUkash", new PrepareUkashViewModel(paymentMethod, stateVars));

                case VendorID.BoCash:
                    return View("PrepareBoCash", new PrepareBoCashViewModel(paymentMethod, stateVars));


                case VendorID.Paysafecard:
                    return View("PreparePaysafecard", new PreparePaysafeCardViewModel(paymentMethod, stateVars));

                case VendorID.Moneybookers:
                    {
                        if (string.Equals("Moneybookers_1Tap", paymentMethod.UniqueName,
                            StringComparison.InvariantCultureIgnoreCase))
                            return View("PrepareMoneybookers1Tap",
                                new PrepareMoneybookers1TapViewModel(paymentMethod, stateVars));
                        return View("PrepareMoneybookers", new PrepareMoneybookersViewModel(paymentMethod, stateVars));
                    }

                case VendorID.PaymentTrust:
                    return View("PreparePT", new PreparePaymentTrustViewModel(paymentMethod, stateVars));

                case VendorID.Envoy:
                    return View("PrepareEnvoy", new TransactionInfo(paymentMethod, stateVars));

                case VendorID.ArtemisSMS:
                    return View("PrepareTurkeySMS", new TurkeySMSViewModel(paymentMethod, stateVars));

                case VendorID.TurkeySMS:
                    return View("PrepareTurkeySMS", new TurkeySMSViewModel(paymentMethod, stateVars));

                case VendorID.TurkeyBankWire:
                    return View("PrepareTurkeyBankWire", new TransactionInfo(paymentMethod, stateVars));

                case VendorID.TLNakit:
                    return View("PrepareTLNakit", new PrepareTLNakitViewModel(paymentMethod, stateVars));

                case VendorID.IPSToken:
                    return View("PrepareIPSToken", new PrepareIPSTokenViewModel(paymentMethod, stateVars));

                case VendorID.LocalBank:
                    return View("PrepareLocalBank", new PrepareLocalBankViewModel(paymentMethod, stateVars));
                case VendorID.Euteller:
                    return View("PrepareEuteller", new PrepareEutellerViewModel(paymentMethod, stateVars));

                case VendorID.UiPas:
                    return View("PrepareUIPAS", new PrepareUiPasViewModel(paymentMethod, stateVars));

                case VendorID.InPay:
                    return View("PrepareInPay", new PrepareInPayViewModel(paymentMethod, stateVars));

                case VendorID.Trustly:
                    return View("PrepareTrustly", new PrepareTrustlyViewModel(paymentMethod, stateVars));

                case VendorID.IPG:
                    return View("PrepareIPG", new PrepareIPGViewModel(paymentMethod, stateVars));

                case VendorID.APX:
                    return View("PrepareAPX", new PrepareAPXViewModel(paymentMethod, stateVars));

                case VendorID.GCE:
                    return View("PrepareGCE", new PrepareGCEViewModel(paymentMethod, stateVars));

                case VendorID.EnterCash:
                    stateVars["enterCashBankID"] = Request.Form["enterCashBankID"];
                    return View("PrepareEnterCash", new PrepareEnterCashViewModel(paymentMethod, stateVars));

                case VendorID.PugglePay:
                    return View("PreparePugglePay", new PreparePugglePayViewModel(paymentMethod, stateVars));

                case VendorID.Voucher:
                    return View("PrepareVoucher", new PrepareVoucherViewModel(paymentMethod, stateVars));

                case VendorID.MoneyMatrix:
                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_PayKasa",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixPayKasa", new PreparePayKasaViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_PayKwik",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixPayKwik", new PreparePayKwikViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Ochapay",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixOchapay", new PrepareOchapayViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_OtoPay",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixOtoPay", new PrepareOtoPayViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_IBanq",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixBanq", new PrepareIBanqViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Epro_Cashlib",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixEproCashlib", new PrepareMoneyMatrixEproCashlibViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_GPaySafe_Visa",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixGPaySafeVisa", new PrepareMoneyMatrixGPaySafeVisaViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_GPaySafe_Mastercard",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixGPaySafeMastercard", new PrepareMoneyMatrixGPaySafeMastercardViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_GPaySafe_PayKasa",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixGPaySafePayKasa", new PrepareMoneyMatrixGPaySafePayKasaViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_GPaySafe_CashIxir",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixGPaySafeCashIxir", new PrepareMoneyMatrixGPaySafeCashIxirViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_GPaySafe_EPayCode",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixGPaySafeEPayCode", new PrepareMoneyMatrixGPaySafeEPayCodeViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_GPaySafe_GsCash",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixGPaySafeGsCash", new PrepareMoneyMatrixGPaySafeGsCashViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_GPaySafe_Jeton",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixGPaySafeJeton", new PrepareMoneyMatrixGPaySafeJetonViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_GPaySafe_InstantBankTransfer",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixGPaySafeInstantBankTransfer", new PrepareMoneyMatrixGPaySafeInstantBankTransferViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_GPaySafe_CepBank",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixGPaySafeCepBank", new PrepareMoneyMatrixGPaySafeCepBankViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Offline_Nordea",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixOfflineNordea", new PrepareMoneyMatrixOfflineNordeaViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Offline_LocalBank",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixOfflineLocalBank", new PrepareMoneyMatrixOfflineLocalBankViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Skrill",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixSkrill", new PrepareMoneyMatrixSkrillViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Skrill_1Tap",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixSkrill_1Tap", new PrepareMoneyMatrixSkrill_1Tap_ViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Zimpler",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixZimpler", new PrepareMoneyMatrixZimplerViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_EcoPayz",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixEcoPayz", new PrepareMoneyMatrixEcoPayzViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_TLNakit",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixTLNakit", new PrepareMoneyMatrixTLNakitViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Trustly",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixTrustly", new PrepareMoneyMatrixTrustlyViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_PaySafeCard",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixPaySafeCard", new PrepareMoneyMatrixPaySafeCardViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Neteller",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixNeteller", new PrepareMoneyMatrixNetellerViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_Wallet",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixPayseraWallet", new PrepareMoneyMatrixPayseraWalletViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_MedicinosBankas",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixPayseraMedicinosBankas", new PrepareMoneyMatrixPayseraMedicinosBankasViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_SiauliuBankas",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixPayseraSiauliuBankas", new PrepareMoneyMatrixPayseraSiauliuBankasViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_LithuanianCreditUnion",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixPayseraLithuanianCreditUnion", new PrepareMoneyMatrixPayseraLithuanianCreditUnionViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_Dnb",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixPayseraDnb", new PrepareMoneyMatrixPayseraDnbViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_CreditCards",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixPayseraCreditCards", new PrepareMoneyMatrixPayseraCreditCardsViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_WebMoney",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixPayseraWebMoney", new PrepareMoneyMatrixPayseraWebMoneyViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_InternationalPaymentInEuros",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixPayseraInternationalPaymentInEuros", new PrepareMoneyMatrixPayseraInternationalPaymentInEurosViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_SwedbankLithuania",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixPayseraSwedbankLithuania", new PrepareMoneyMatrixPayseraSwedbankLithuaniaViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_SebLithuania",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixPayseraSebLithuania", new PrepareMoneyMatrixPayseraSebLithuaniaViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_NordeaLithuania",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixPayseraNordeaLithuania", new PrepareMoneyMatrixPayseraNordeaLithuaniaViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_CitadeleLithuania",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixPayseraCitadeleLithuania", new PrepareMoneyMatrixPayseraCitadeleLithuaniaViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_DanskeLithuania",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixPayseraDanskeLithuania", new PrepareMoneyMatrixPayseraDanskeLithuaniaViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_Perlas",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixPayseraPerlas", new PrepareMoneyMatrixPayseraPerlasViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_SwedbankLatvia",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixPayseraSwedbankLatvia", new PrepareMoneyMatrixPayseraSwedbankLatviaViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_SebLatvia",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixPayseraSebLatvia", new PrepareMoneyMatrixPayseraSebLatviaViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_NordeaLatvia",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixPayseraNordeaLatvia", new PrepareMoneyMatrixPayseraNordeaLatviaViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_CitadeleLatvia",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixPayseraCitadeleLatvia", new PrepareMoneyMatrixPayseraCitadeleLatviaViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_SwedbankEstonia",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixPayseraSwedbankEstonia", new PrepareMoneyMatrixPayseraSwedbankEstoniaViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_SebEstonia",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixPayseraSebEstonia", new PrepareMoneyMatrixPayseraSebEstoniaViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_DanskeEstonia",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixPayseraDanskeEstonia", new PrepareMoneyMatrixPayseraDanskeEstoniaViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_NordeaEstonia",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixPayseraNordeaEstonia", new PrepareMoneyMatrixPayseraNordeaEstoniaViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_Krediidipank",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixPayseraKrediidipank", new PrepareMoneyMatrixPayseraKrediidipankViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_LhvBank",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixPayseraLhvBank", new PrepareMoneyMatrixPayseraLhvBankViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_BzwbkBank",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixPayseraBzwbkBank", new PrepareMoneyMatrixPayseraBzwbkBankViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_PekaoBank",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixPayseraPekaoBank", new PrepareMoneyMatrixPayseraPekaoBankViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_PkoBank",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixPayseraPkoBank", new PrepareMoneyMatrixPayseraPkoBankViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_mBank",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixPayseramBank", new PrepareMoneyMatrixPayseramBankViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_AliorBank",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixPayseraAliorBank", new PrepareMoneyMatrixPayseraAliorBankViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Paysera_Easypay",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixPayseraEasypay", new PrepareMoneyMatrixPayseraEasypayViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Adyen_Sofort",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixAdyenSofort", new PrepareMoneyMatrixAdyenSofortViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Adyen_Giropay",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixAdyenGiropay", new PrepareMoneyMatrixAdyenGiropayViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Adyen_iDeal",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixAdyeniDeal", new PrepareMoneyMatrixAdyeniDealViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Adyen_ELV",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixAdyenELV", new PrepareMoneyMatrixAdyenELVViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Adyen_PayPal",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixAdyenPayPal", new PrepareMoneyMatrixAdyenPayPalViewModel(paymentMethod, stateVars));
                    }

                    if(string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Visa",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixVisa", new DefaultMoneyMatrixPrepareViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_MasterCard",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixMasterCard", new DefaultMoneyMatrixPrepareViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_Dankort",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixDankort", new DefaultMoneyMatrixPrepareViewModel(paymentMethod, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix",
                        StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrix", new PrepareMoneyMatrixViewModel(paymentMethod, stateVars));
                    }

                    var moneyMatrixPrefix = "MoneyMatrix_";
                    var enterPaysPrefix = "EnterPays_";
                    if (paymentMethod.UniqueName.StartsWith(moneyMatrixPrefix + enterPaysPrefix, StringComparison.InvariantCultureIgnoreCase))
                    {
                        var paymentSolutionName = paymentMethod.UniqueName.Replace(moneyMatrixPrefix, string.Empty).Replace("_", ".");

                        var viewName = string.Format(
                            "PrepareMoneyMatrix{0}",
                            paymentSolutionName.Replace(".", string.Empty));

                        return View(viewName, new DefaultMoneyMatrixPrepareViewModel(paymentMethod, paymentSolutionName, stateVars));
                    }

                    var pproPrefix = "PPro_";

                    if (paymentMethod.UniqueName.StartsWith(moneyMatrixPrefix + pproPrefix, StringComparison.InvariantCultureIgnoreCase))
                    {
                        var paymentSolutionName = paymentMethod.UniqueName.Replace(moneyMatrixPrefix, string.Empty).Replace("_", ".");

                        var viewName = string.Format(
                            "PrepareMoneyMatrix{0}",
                            paymentSolutionName.Replace(".", string.Empty));

                        return View(viewName, new DefaultMoneyMatrixPrepareViewModel(paymentMethod, paymentSolutionName, stateVars));
                    }

                    if (string.Equals(paymentMethod.UniqueName, "MoneyMatrix_UPayCard", StringComparison.InvariantCultureIgnoreCase))
                    {
                        return View("PrepareMoneyMatrixUPayCard", new DefaultMoneyMatrixPrepareViewModel(paymentMethod, stateVars));
                    }

                    throw new NotSupportedException();

                case VendorID.EcoCard:
                    return View("PrepareEcoCard", new PrepareEcoCardViewModel(paymentMethod, stateVars));
                case VendorID.TxtNation:
                    return View("PrepareTxtNation", new PrepareTxtNationViewModel(paymentMethod, stateVars));

                default:
                    throw new NotSupportedException();
            }
        }

        [HttpGet]
        public virtual RedirectResult PrepareTransaction()
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

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [RequireLogin]
        #region PrepareTransactionAsync
        public void PrepareTransactionAsync(string paymentMethodName)
        {
            try
            {
                string iovationBlackBox = Request.Form["iovationBlackBox"];
                var iovationResult = IovationCheck(iovationBlackBox);
                if (iovationResult != null)
                {
                    AsyncManager.Parameters["iovationResult"] = iovationResult;
                    return;
                }

                PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
                    .FirstOrDefault(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.InvariantCultureIgnoreCase));
                if (paymentMethod == null)
                    throw new ArgumentOutOfRangeException("paymentMethodName");

                long? payCardID = null;
                long? creditAccountID = null;
                decimal? amount = null;
                string identityNumber = Request.Form["identityNumber"];
                string securityKey = Request.Form["securityKey"];
                string currency = Request.Form["currency"];


                // parse the parameters
                {
                    AsyncManager.Parameters["paymentMethodName"] = paymentMethodName;
                    AsyncManager.Parameters["paymentMethod"] = paymentMethod;
                    AsyncManager.Parameters["bonusCode"] = Request.Form["bonusCode"];
                    AsyncManager.Parameters["bonusVendor"] = Request.Form["bonusVendor"];

                    foreach (string key in Request.Form.AllKeys)
                    {
                        if (!string.IsNullOrWhiteSpace(key))
                            AsyncManager.Parameters[key] = Request.Form[key];
                    }

                    if (Request.Form["amount"] != null)
                    {
                        string temp = Regex.Replace(Request.Form["amount"], @"[^\d\.]", string.Empty, RegexOptions.Compiled | RegexOptions.ECMAScript);
                        decimal tempAmount = 0.00M;
                        if (decimal.TryParse(temp, NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out tempAmount))
                        {
                            amount = tempAmount;
                        }
                    }

                    if (Request.Form["payCardID"] != null)
                    {
                        long tempID = 0L;
                        if (long.TryParse(Request.Form["payCardID"], NumberStyles.Integer, CultureInfo.InvariantCulture, out tempID))
                        {
                            payCardID = tempID;
                        }
                    }

                    if (Request.Form["creditAccountID"] != null)
                    {
                        long tempID = 0L;
                        if (long.TryParse(Request.Form["creditAccountID"], NumberStyles.Integer, CultureInfo.InvariantCulture, out tempID))
                        {
                            creditAccountID = tempID;
                        }
                    }
                }


                switch (paymentMethod.VendorID)
                {
                    case VendorID.PaymentTrust:
                        {
                            if (!creditAccountID.HasValue)
                                throw new ArgumentNullException("creditAccountID");
                            if (!amount.HasValue)
                                throw new ArgumentNullException("amount");

                            if (string.IsNullOrWhiteSpace(securityKey))
                            {
                                if (payCardID.HasValue && payCardID.Value > 0)
                                {
                                    securityKey = Request.Form["securityKeyForExistingPayCard"];
                                }
                                else
                                {
                                    securityKey = Request.Form["securityKeyForNewPayCard"];
                                }
                            }

                            PrepareCreditCardTransaction(payCardID
                                , creditAccountID.Value
                                , currency
                                , amount.Value
                                , identityNumber
                                , securityKey
                                , Request.Form["ownerName"]
                                , Request.Form["issueNumber"]
                                , Request.Form["validFrom"]
                                , Request.Form["expiryDate"]
                                );
                            break;
                        }

                    case VendorID.Neteller:
                        {
                            if (!creditAccountID.HasValue)
                                throw new ArgumentNullException("creditAccountID");
                            if (!amount.HasValue)
                                throw new ArgumentNullException("amount");
                            PrepareNetellerTransaction(payCardID
                                , identityNumber
                                , securityKey
                                , creditAccountID.Value
                                , currency
                                , amount.Value
                                );
                            break;
                        }

                    case VendorID.Ukash:
                        {
                            if (!payCardID.HasValue)
                                throw new ArgumentNullException("payCardID");
                            if (!creditAccountID.HasValue)
                                throw new ArgumentNullException("creditAccountID");
                            if (!amount.HasValue)
                                throw new ArgumentNullException("amount");

                            PrepareUkashTransaction(payCardID.Value
                                , creditAccountID.Value
                                , currency
                                , amount.Value
                                , Request.Form["inputValue1"]
                                , Request.Form["inputValue2"]
                                );
                            break;
                        }

                    case VendorID.BoCash:
                        {
                            if (!payCardID.HasValue)
                                throw new ArgumentNullException("payCardID");
                            if (!creditAccountID.HasValue)
                                throw new ArgumentNullException("creditAccountID");
                            if (!amount.HasValue)
                                throw new ArgumentNullException("amount");

                            PrepareBoCashTransaction(payCardID.Value
                                , creditAccountID.Value
                                , currency
                                , amount.Value
                                , Request.Form["inputValue1"]
                                );
                            break;
                        }


                    case VendorID.Paysafecard:
                        {
                            if (!payCardID.HasValue)
                                throw new ArgumentNullException("payCardID");
                            if (!creditAccountID.HasValue)
                                throw new ArgumentNullException("creditAccountID");
                            if (!amount.HasValue)
                                throw new ArgumentNullException("amount");

                            PreparePaysafecardTransaction(payCardID.Value
                                , creditAccountID.Value
                                , currency
                                , amount.Value
                                );
                            break;
                        }

                    case VendorID.Moneybookers:
                        {
                            if (!payCardID.HasValue)
                                throw new ArgumentNullException("payCardID");
                            if (!creditAccountID.HasValue)
                                throw new ArgumentNullException("creditAccountID");
                            if (!amount.HasValue)
                                throw new ArgumentNullException("amount");

                            if (string.Equals("Moneybookers_1Tap", paymentMethod.UniqueName, StringComparison.InvariantCultureIgnoreCase))
                                PrepareMoneybookers1TapTransaction(payCardID.Value
                                    , creditAccountID.Value
                                    , currency
                                    , amount.Value
                                    , Request.Form["maxAmount"]);
                            else
                                PrepareMoneybookersTransaction(payCardID.Value
                                    , creditAccountID.Value
                                    , currency
                                    , amount.Value
                                    , identityNumber
                                    );
                            break;
                        }
                    case VendorID.TLNakit:
                        {
                            if (!creditAccountID.HasValue)
                                throw new ArgumentNullException("creditAccountID");
                            if (!amount.HasValue)
                                throw new ArgumentNullException("amount");

                            PrepareTLNakitTransaction(payCardID.Value
                                , creditAccountID.Value
                                , currency
                                , amount.Value
                                , Request.Form["cardNumber"]
                                );
                            break;
                        }
                    case VendorID.Euteller:
                        {
                            if (!payCardID.HasValue)
                                throw new ArgumentNullException("payCardID");
                            if (!creditAccountID.HasValue)
                                throw new ArgumentNullException("creditAccountID");
                            if (!amount.HasValue)
                                throw new ArgumentNullException("amount");

                            PrepareEutellerTransaction(payCardID.Value
                                , creditAccountID.Value
                                , currency
                                , amount.Value
                                );
                            break;
                        }

                    case VendorID.UiPas:
                        {
                            if (!creditAccountID.HasValue)
                                throw new ArgumentNullException("creditAccountID");
                            if (!amount.HasValue)
                                throw new ArgumentNullException("amount");
                            PrepareUiPasTransaction(payCardID
                                , identityNumber
                                , securityKey
                                , creditAccountID.Value
                                , currency
                                , amount.Value
                                );
                            break;
                        }

                    case VendorID.Trustly:
                        {
                            if (!creditAccountID.HasValue)
                                throw new ArgumentNullException("creditAccountID");
                            if (!amount.HasValue)
                                throw new ArgumentNullException("amount");
                            if (!payCardID.HasValue)
                            {
                                PayCardInfoRec payCard = GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.Trustly)
                                                         .Where(p => p.IsDummy)
                                                         .FirstOrDefault();
                                if (payCard == null)
                                    throw new Exception("Trustly is not configrured in GmCore correctly, missing dummy pay card.");
                                payCardID = payCard.ID;
                            }
                            PrepareTrustlyTransaction(payCardID.Value
                                , creditAccountID.Value
                                , currency
                                , amount.Value
                                );
                            break;
                        }

                    case VendorID.IPG:
                        {
                            if (!creditAccountID.HasValue)
                                throw new ArgumentNullException("creditAccountID");
                            if (!amount.HasValue)
                                throw new ArgumentNullException("amount");
                            if (!payCardID.HasValue)
                            {
                                PayCardInfoRec payCard = GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.IPG)
                                                         .Where(p => p.IsDummy)
                                                         .FirstOrDefault();
                                if (payCard == null)
                                    throw new Exception("IPG is not configrured in GmCore correctly, missing dummy pay card.");
                                payCardID = payCard.ID;
                            }
                            PrepareIPGTransaction(payCardID.Value
                                , creditAccountID.Value
                                , currency
                                , amount.Value
                                );
                            break;
                        }

                    case VendorID.APX:
                        {
                            if (!creditAccountID.HasValue)
                                throw new ArgumentNullException("creditAccountID");
                            if (!amount.HasValue)
                                throw new ArgumentNullException("amount");
                            if (!payCardID.HasValue)
                            {
                                PayCardInfoRec payCard = GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.APX)
                                                         .Where(p => p.IsDummy)
                                                         .FirstOrDefault();
                                if (payCard == null)
                                    throw new Exception("APX is not configrured in GmCore correctly, missing dummy pay card.");
                                payCardID = payCard.ID;
                            }
                            PrepareAPXTransaction(payCardID.Value
                                , creditAccountID.Value
                                , currency
                                , amount.Value
                                );
                            break;
                        }

                    case VendorID.EnterCash:
                        {
                            if (!creditAccountID.HasValue)
                                throw new ArgumentNullException("creditAccountID");
                            if (!amount.HasValue)
                                throw new ArgumentNullException("amount");
                            if (!payCardID.HasValue)
                            {
                                PayCardInfoRec payCard = GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.EnterCash)
                                                         .Where(p => p.IsDummy)
                                                         .FirstOrDefault();
                                if (payCard == null)
                                    throw new Exception("EnterCash is not configrured in GmCore correctly, missing dummy pay card.");
                                payCardID = payCard.ID;
                            }
                            PrepareEnterCashTransaction(payCardID.Value
                                , creditAccountID.Value
                                , currency
                                , amount.Value
                                , Request.Form["enterCashBankID"]
                                , Request.Form["verificationCode"]
                                );
                            break;
                        }

                    case VendorID.GCE:
                        {
                            if (!creditAccountID.HasValue)
                                throw new ArgumentNullException("creditAccountID");
                            if (!amount.HasValue)
                                throw new ArgumentNullException("amount");
                            if (!payCardID.HasValue)
                            {
                                PayCardInfoRec payCard = GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.GCE)
                                                         .Where(p => p.IsDummy)
                                                         .FirstOrDefault();
                                if (payCard == null)
                                    throw new Exception("GCE is not configrured in GmCore correctly, missing dummy pay card.");
                                payCardID = payCard.ID;
                            }
                            PrepareGCETransaction(payCardID.Value
                                , creditAccountID.Value
                                , currency
                                , amount.Value
                                );
                            break;
                        }

                    case VendorID.PugglePay:
                        {
                            if (!creditAccountID.HasValue)
                                throw new ArgumentNullException("creditAccountID");
                            if (!amount.HasValue)
                                throw new ArgumentNullException("amount");
                            if (!payCardID.HasValue)
                            {
                                PayCardInfoRec payCard = GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.PugglePay)
                                                         .Where(p => p.IsDummy)
                                                         .FirstOrDefault();
                                if (payCard == null)
                                    throw new Exception("PugglePay is not configrured in GmCore correctly, missing dummy pay card.");
                                payCardID = payCard.ID;
                            }
                            PreparePugglePayTransaction(payCardID.Value
                                , creditAccountID.Value
                                , currency
                                , amount.Value
                                );
                            break;
                        }

                    case VendorID.Voucher:
                        {
                            if (!creditAccountID.HasValue)
                                throw new ArgumentNullException("creditAccountID");
                            if (!amount.HasValue)
                                throw new ArgumentNullException("amount");

                            PrepareVoucherTransaction(payCardID
                                , Request.Form["voucherNumber"]
                                , securityKey
                                , creditAccountID.Value
                                , currency
                                , amount.Value
                                );
                            break;
                        }
                    case VendorID.MoneyMatrix:
                        {
                            if (!creditAccountID.HasValue)
                                throw new ArgumentNullException("creditAccountID");
                            if (!amount.HasValue)
                                throw new ArgumentNullException("amount");

                            if (!payCardID.HasValue)
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
                                    try
                                    {
                                        payCardID = this.RegisterMoneyMatrixCreditCardPayCard(identityNumber
                                         , Request["ownerName"]
                                         , Request["expiryDate"]
                                         , Request["validFrom"]);
                                    }
                                    catch (Exception ex)
                                    {
                                        Logger.Exception(ex);

                                        throw;
                                    }
                                }
                            }

                            this.PrepareMoneyMatrixTransaction(
                                paymentMethod.UniqueName,
                                payCardID,
                                creditAccountID.Value,
                                currency,
                                amount.Value);

                            break;
                        }
                    case VendorID.EcoCard:
                        {
                            if (!payCardID.HasValue)
                                throw new ArgumentNullException("payCardID");
                            if (!creditAccountID.HasValue)
                                throw new ArgumentNullException("creditAccountID");
                            if (!amount.HasValue)
                                throw new ArgumentNullException("amount");

                            PrepareEcoCardTransaction(payCardID.Value
                                , creditAccountID.Value
                                , currency
                                , amount.Value
                                );
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

        public ActionResult PrepareTransactionCompleted(string paymentMethodName
            , PrepareTransRequest prepareTransRequest
            , Exception exception
            , string securityKey
            , string inputValue1
            , string inputValue2
            , JsonResult iovationResult
            )
        {
            if (iovationResult != null)
                return iovationResult;

            try
            {
                if (exception != null)
                    throw exception;

                string sid = prepareTransRequest.Record.Sid;

                string receiptUrl = this.Url.RouteUrlEx("Deposit", new { @action = "Receipt", @paymentMethodName = paymentMethodName, @sid = sid });


                CustomProfile.Current.Set("ReceiptUrl", receiptUrl);


                if (!string.IsNullOrWhiteSpace(securityKey))
                {
                    cmTransParameter.SaveObject<string>(sid, "SecurityKey", securityKey.DefaultEncrypt());
                }
                cmTransParameter.SaveObject<PrepareTransRequest>(sid, "PrepareTransRequest", prepareTransRequest);
                cmTransParameter.SaveObject<string>(sid, "UserID", CustomProfile.Current.UserID.ToString());
                cmTransParameter.SaveObject<string>(sid, "SessionID", CustomProfile.Current.SessionID);
                cmTransParameter.SaveObject<string>(sid, "SuccessUrl", prepareTransRequest.ReturnURL);
                cmTransParameter.SaveObject<string>(sid, "CancelUrl", prepareTransRequest.CancelURL);

                if (!string.IsNullOrWhiteSpace(inputValue1))
                    cmTransParameter.SaveObject<string>(sid, "InputValue1", inputValue1.DefaultEncrypt());

                if (!string.IsNullOrWhiteSpace(inputValue2))
                    cmTransParameter.SaveObject<string>(sid, "InputValue2", inputValue2.DefaultEncrypt());

                string url = this.Url.Action("Confirmation", new { paymentMethodName = paymentMethodName, sid = sid });
                return this.Redirect(url);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return this.View("Error");
            }
        }
        #endregion

        #region IPSToken
        [HttpGet]
        public RedirectResult ProcessIPSTokenTransaction()
        {
            return RedirectToIndex();
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [RequireLogin]

        public ActionResult ProcessIPSTokenTransaction(string paymentMethodName
            , long creditAccountID
            , long payCardID
            , string token
            , string checkDigit
            , bool? acceptBonus
            )
        {
            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
                    .FirstOrDefault(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.InvariantCultureIgnoreCase));
            if (paymentMethod == null)
                throw new ArgumentOutOfRangeException("paymentMethodName");

            SetBonusDefaultOption(acceptBonus.HasValue && acceptBonus.Value);

            IPSTokenDepositNoAmountRequest request = new IPSTokenDepositNoAmountRequest();
            request.AccountId = creditAccountID;
            request.CheckDigit = checkDigit;
            request.TokenNumber = token;
            request.UserID = CustomProfile.Current.UserID;
            request.PaycardId = payCardID;

            using (GamMatrixClient client = GamMatrixClient.Get())
            {
                request = client.SingleRequest<IPSTokenDepositNoAmountRequest>(request);
            }
            if (!request.ResponseStatus)
            {
                this.ViewData["ErrorMessage"] = CM.Content.Metadata.Get("/Deposit/_PrepareIPSToken_aspx.Message_DepositFailed");
                return View("Error");
            }

            cmTransParameter.SaveObject<IPSTokenDepositNoAmountRequest>(request.Sid
                    , "IPSTokenDepositNoAmountRequest"
                    , request
                    );
            cmTransParameter.SaveObject<string>(request.Sid
                , "UserID"
                , CustomProfile.Current.UserID.ToString()
                );
            cmTransParameter.SaveObject<string>(request.Sid
                , "SessionID"
                , CustomProfile.Current.SessionID
                );

            string url = this.Url.RouteUrlEx("Deposit", new { @action = "IPSTokenReceipt", @paymentMethodName = paymentMethodName, @sid = request.Sid });
            return this.Redirect(url);
        }

        public ActionResult IPSTokenReceipt(string paymentMethodName, string sid)
        {
            try
            {
                PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
                        .FirstOrDefault(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.InvariantCultureIgnoreCase));
                if (paymentMethod == null)
                    throw new ArgumentException();

                IPSTokenDepositNoAmountRequest requestIPSTokenDepositNoAmount = cmTransParameter.ReadObject<IPSTokenDepositNoAmountRequest>(sid, "IPSTokenDepositNoAmountRequest");
                if (requestIPSTokenDepositNoAmount == null)
                    throw new ArgumentOutOfRangeException("sid");

                GetTransInfoRequest getTransInfoRequest = null;
                string lastError = cmTransParameter.ReadObject<string>(sid, "LastError");

                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    getTransInfoRequest = client.SingleRequest<GetTransInfoRequest>(new GetTransInfoRequest()
                    {
                        SID = sid,
                        NoDetails = true,
                    });
                }
                this.ViewData["getTransInfoRequest"] = getTransInfoRequest;

                AccountData account = GamMatrixClient.GetUserGammingAccounts(CustomProfile.Current.UserID, true).FirstOrDefault(a => a.ID == requestIPSTokenDepositNoAmount.AccountId);
                this.ViewData["creditAccount"] = account;

                PreTransStatus preTransStatus = getTransInfoRequest.TransData.Status;
                TransStatus transStatus = getTransInfoRequest.TransData.TransStatus;
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
                    return View("IPSTokenReceipt", paymentMethod);
                }
                else if (preTransStatus == PreTransStatus.Failed ||
                    transStatus == TransStatus.Failed ||
                    !string.IsNullOrEmpty(lastError))
                {
                    this.ViewData["ErrorMessage"] = cmTransParameter.ReadObject<string>(sid, "LastError");
                    return View("Error");
                }
                else
                {
                    return View("NotCompleted");
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return View("Error");
            }
        }
        #endregion IPSToken

        #region TurkeySMS / ArtemisSMS
        [HttpGet]
        public RedirectResult ConfirmArtemisSMSTransaction()
        {
            return RedirectToIndex();
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [RequireLogin]
        public ViewResult ConfirmArtemisSMSTransaction(string paymentMethodName)
        {
            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
                    .FirstOrDefault(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.InvariantCultureIgnoreCase));
            if (paymentMethod == null)
                throw new ArgumentOutOfRangeException("paymentMethodName");

            var stateVars = Request.Form.AllKeys
                .SelectMany(Request.Form.GetValues, (k, v) => new KeyValuePair<string, string>(k, v))
                .ToDictionary(k => k.Key, v => v.Value);

            return View("ConfirmTurkeySMS", new TurkeySMSViewModel(paymentMethod, stateVars));
        }


        public ViewResult ConfirmTurkeySMSTransaction(string paymentMethodName)
        {
            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
                    .FirstOrDefault(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.InvariantCultureIgnoreCase));
            if (paymentMethod == null)
                throw new ArgumentOutOfRangeException("paymentMethodName");

            var stateVars = Request.Form.AllKeys
                .SelectMany(Request.Form.GetValues, (k, v) => new KeyValuePair<string, string>(k, v))
                .ToDictionary(k => k.Key, v => v.Value);

            return View("ConfirmTurkeySMS", new TurkeySMSViewModel(paymentMethod, stateVars));
        }

        [HttpGet]
        public RedirectResult ProcessArtemisSMSTransaction()
        {
            return RedirectToIndex();
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [RequireLogin]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ViewResult ProcessArtemisSMSTransaction(string paymentMethodName
            , long creditAccountID
            , string currency
            , string amount
            , string senderPhoneNumber
            , string receiverPhoneNumber
            , int? rbday
            , int? rbmonth
            , int? rbyear
            , string password
            , string referenceNumber
            , string senderTCNumber
            , string receiverTCNumber
            , bool? acceptBonus
            )
        {
            SetBonusDefaultOption(acceptBonus.HasValue && acceptBonus.Value);

            decimal requestAmount = decimal.Parse(Regex.Replace(amount, @"[^\d\.]", string.Empty), CultureInfo.InvariantCulture);

            using (GamMatrixClient client = GamMatrixClient.Get())
            {
                ArtemisSMSRec card = new ArtemisSMSRec()
                {
                    TransType = TransType.Deposit,
                    AccountID = creditAccountID,
                    Amount = requestAmount,
                    Currency = currency,
                    UserID = CustomProfile.Current.UserID,
                    SenderPhoneNumber = senderPhoneNumber,
                    ReceiverPhoneNumber = receiverPhoneNumber,
                    Password = password,
                    ReferenceNumber = referenceNumber,
                    SenderTCNumber = senderTCNumber,
                    ReceiverTCNumber = receiverTCNumber,
                    IsMobile = true,
                };


                if (rbday != null && rbmonth != null && rbyear != null)
                    card.ReceiverBirthDate = new DateTime((int)rbyear, (int)rbmonth, (int)rbday);

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

            return View("ReceiptPending");
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public ViewResult ProcessTurkeySMSTransaction(string paymentMethodName
            , long creditAccountID
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
            )
        {
            if (!CustomProfile.Current.IsAuthenticated)
                throw new UnauthorizedAccessException();

            SetBonusDefaultOption(acceptBonus.HasValue && acceptBonus.Value);

            decimal requestAmount = decimal.Parse(Regex.Replace(amount, @"[^\d\.]", string.Empty), CultureInfo.InvariantCulture);

            using (GamMatrixClient client = GamMatrixClient.Get())
            {

                TurkeySMSRec card = new TurkeySMSRec()
                {
                    TransType = TransType.Deposit,
                    AccountID = creditAccountID,
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

            return View("ReceiptPending");
        }
        #endregion

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public ViewResult ProcessLocalBankTransaction(string paymentMethodName
            , long creditAccountID//gammingAccountID
            , string currency
            , string amount
            , long payCardID
            )
        {
            //SetBonusDefaultOption(acceptBonus.HasValue && acceptBonus.Value);

            decimal requestAmount = decimal.Parse(Regex.Replace(amount, @"[^\d\.]", string.Empty), CultureInfo.InvariantCulture);

            using (GamMatrixClient client = GamMatrixClient.Get())
            {
                //long payCardID = GamMatrixClient.GetPayCards(VendorID.LocalBank).First().ID;

                LocalBankPaymentRequest request = new LocalBankPaymentRequest()
                {
                    Payment = new LocalBankRec()
                    {
                        AccountID = creditAccountID,//gammingAccountID,
                        Amount = requestAmount,
                        Currency = currency,
                        PaycardID = payCardID,

                        UserID = CustomProfile.Current.UserID,
                    }
                };

                request = client.SingleRequest<LocalBankPaymentRequest>(request);
            }

            return View("ReceiptPending");
        }


        #region TurkeyBankWire
        [HttpGet]
        public RedirectResult ConfirmTurkeyBankWireTransaction()
        {
            return RedirectToIndex();
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [RequireLogin]
        public ViewResult ConfirmTurkeyBankWireTransaction(string paymentMethodName)
        {
            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
                    .FirstOrDefault(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.InvariantCultureIgnoreCase));
            if (paymentMethod == null)
                throw new ArgumentOutOfRangeException("paymentMethodName");

            var stateVars = Request.Form.AllKeys
                .SelectMany(Request.Form.GetValues, (k, v) => new KeyValuePair<string, string>(k, v))
                .ToDictionary(k => k.Key, v => v.Value);

            return View("ConfirmTurkeyBankWire", new TransactionInfo(paymentMethod, stateVars));
        }

        [HttpGet]
        public RedirectResult ProcessTurkeyBankWireTransaction()
        {
            return RedirectToIndex();
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [RequireLogin]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ViewResult ProcessTurkeyBankWireTransaction(string paymentMethodName
            , long creditAccountID
            , string currency
            , string amount
            , string fullname
            , string citizenID
            , TurkeyBankWirePaymentMethod paymentMethod
            , string transactionID
            )
        {
            decimal requestAmount = decimal.Parse(Regex.Replace(amount, @"[^\d\.]", string.Empty), CultureInfo.InvariantCulture);

            using (GamMatrixClient client = GamMatrixClient.Get())
            {
                TurkeyBankWireRec card = new TurkeyBankWireRec()
                {
                    AccountID = creditAccountID,
                    Amount = requestAmount,
                    Currency = currency,
                    UserID = CustomProfile.Current.UserID,
                    PaymentMethod = paymentMethod,
                    FullName = fullname,
                    CitizenID = citizenID,
                    TransactionID = transactionID,
                    IsMobile = true,
                };

                TurkeyBankWirePaymentRequest request = new TurkeyBankWirePaymentRequest() { Payment = card };
                request = client.SingleRequest<TurkeyBankWirePaymentRequest>(request);
            }

            return View("ReceiptPending");
        }
        #endregion

        #region InPay
        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public void ProcessInPayTransactionAsync(string paymentMethodName, string inPayBankID)
        {
            try
            {
                string iovationBlackBox = Request.Form["iovationBlackBox"];
                var iovationResult = IovationCheck(iovationBlackBox);
                if (iovationResult != null)
                {
                    AsyncManager.Parameters["iovationResult"] = iovationResult;
                    return;
                }
                AsyncManager.Parameters["iovationBlackBox"] = iovationBlackBox;


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
                AsyncManager.Parameters["postBackURL"] = this.Url.RouteUrlEx("Deposit", new { @action = "Postback", @paymentMethodName = paymentMethodName, @sid = "{0}" });
                AsyncManager.Parameters["returnURL"] = this.Url.RouteUrlEx("Deposit", new { @action = "Return" });
                AsyncManager.Parameters["sessionID"] = GamMatrixClient.GetSessionIDForCurrentOperator();
                AsyncManager.Parameters["userID"] = CustomProfile.Current.UserID;
                AsyncManager.Parameters["userIP"] = global::System.Web.HttpContext.Current.Request.GetRealUserAddress();
                AsyncManager.Parameters["userSessionID"] = CustomProfile.Current.SessionID;

                PrepareInPayTransaction(paymentMethodName);
                AsyncManager.OutstandingOperations.Increment();
            }
            catch (Exception ex)
            {
                AsyncManager.Parameters["exception"] = ex;
            }
        }

        private void PrepareInPayTransaction(string paymentMethodName)
        {
            try
            {
                PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
                    .FirstOrDefault(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.InvariantCultureIgnoreCase));
                if (paymentMethod == null)
                    throw new ArgumentOutOfRangeException("paymentMethodName");

                long? payCardID = null;
                long? creditAccountID = null;
                decimal? amount = null;
                string currency = Request.Form["currency"];


                // parse the parameters
                {
                    AsyncManager.Parameters["paymentMethodName"] = paymentMethodName;
                    AsyncManager.Parameters["paymentMethod"] = paymentMethod;
                    AsyncManager.Parameters["bonusCode"] = Request.Form["bonusCode"];
                    AsyncManager.Parameters["bonusVendor"] = Request.Form["bonusVendor"];

                    foreach (string key in Request.Form.AllKeys)
                    {
                        if (!string.IsNullOrWhiteSpace(key))
                            AsyncManager.Parameters[key] = Request.Form[key];
                    }

                    if (Request.Form["amount"] != null)
                    {
                        string temp = Regex.Replace(Request.Form["amount"], @"[^\d\.]", string.Empty, RegexOptions.Compiled | RegexOptions.ECMAScript);
                        decimal tempAmount = 0.00M;
                        if (decimal.TryParse(temp, NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out tempAmount))
                        {
                            amount = tempAmount;
                        }
                    }

                    if (Request.Form["payCardID"] != null)
                    {
                        long tempID = 0L;
                        if (long.TryParse(Request.Form["payCardID"], NumberStyles.Integer, CultureInfo.InvariantCulture, out tempID))
                        {
                            payCardID = tempID;
                        }
                    }

                    if (Request.Form["creditAccountID"] != null)
                    {
                        long tempID = 0L;
                        if (long.TryParse(Request.Form["creditAccountID"], NumberStyles.Integer, CultureInfo.InvariantCulture, out tempID))
                        {
                            creditAccountID = tempID;
                        }
                    }
                }

                if (!creditAccountID.HasValue)
                    throw new ArgumentNullException("creditAccountID");
                if (!amount.HasValue)
                    throw new ArgumentNullException("amount");

                if (!payCardID.HasValue)
                {
                    PayCardInfoRec card = GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.InPay)
                                          .Where(p => p.IsDummy && p.ActiveStatus == ActiveStatus.Active)
                                          .OrderByDescending(c => c.Ins).FirstOrDefault();
                    if (card != null)
                        payCardID = card.ID;
                }

                if (!payCardID.HasValue)
                    throw new ArgumentNullException("payCardID");

                AsyncManager.Parameters["payCardID"] = payCardID;

                PrepareTransRequest prepareTransRequest = new PrepareTransRequest()
                {
                    Record = new PreTransRec()
                    {
                        TransType = TransType.Deposit,
                        DebitPayCardID = payCardID.Value,
                        CreditAccountID = creditAccountID.Value,
                        RequestAmount = amount.Value,
                        RequestCurrency = currency,
                        UserID = CustomProfile.Current.UserID,
                        UserIP = Request.GetRealUserAddress(),
                        IsMobile = true,
                        //PaymentType = null,
                        //TempExternalReference = null,
                    },
                    IovationBlackBox = AsyncManager.Parameters["iovationBlackBox"].ToString(),
                    IsWindowOwner = false,
                    IsRequiredRedirectForm = true,
                    RedirectFormName = "depositForm",
                    RedirectFormTarget = "_self",
                    IsRequiredRedirectURL = false,
                    PostBackURL = this.Url.RouteUrlEx("Deposit", new { @action = "Postback", @paymentMethodName = AsyncManager.Parameters["paymentMethodName"] }),
                    PostBackURLTarget = "_self",
                    CancelURL = this.Url.RouteUrlEx("Deposit", new { @action = "Cancel" }),
                    CancelURLTarget = "_self",
                    ReturnURL = this.Url.RouteUrlEx("Deposit", new { @action = "Return" }),
                    ReturnURLTarget = "_self",
                    //DepositSource = DepositSource.MainDepositPage,
                };

                string bonusCode = AsyncManager.Parameters["bonusCode"] as string;
                string bonusVendor = AsyncManager.Parameters["bonusVendor"] as string;

                if (!string.IsNullOrWhiteSpace(bonusCode))
                {
                    List<AccountData> accounts = GamMatrixClient.GetUserGammingAccounts(CustomProfile.Current.UserID);
                    AccountData account = accounts.FirstOrDefault(a => a.ID == creditAccountID);
                    if (account != null)
                    {
                        VendorID bonusVendorID;
                        if (!Enum.TryParse(bonusVendor, out bonusVendorID))
                            bonusVendorID = account.Record.VendorID;

                        prepareTransRequest.ApplyBonusVendorID = bonusVendorID;
                        prepareTransRequest.ApplyBonusCode = bonusCode.Trim();
                    }
                }

                GamMatrixClient.SingleRequestAsync<PrepareTransRequest>(prepareTransRequest
                        , OnPrepareInPayTransactionCompleted
                        );
            }
            catch (Exception ex)
            {
                AsyncManager.Parameters["exception"] = ex;
            }
        }

        private void OnPrepareInPayTransactionCompleted(AsyncResult reply)
        {
            try
            {
                var prepareTransRequest = reply.EndSingleRequest().Get<PrepareTransRequest>();

                string sid = prepareTransRequest.Record.Sid;

                if (prepareTransRequest.Record.Status != PreTransStatus.Setup)
                    throw new Exception(string.Format("Invalid status for transaction [{0}]", sid));

                var paymentMethodName = AsyncManager.Parameters["paymentMethodName"].ToString();
                var inPayBank = AsyncManager.Parameters["inPayBank"] as InPayBank;

                cmTransParameter.SaveObject<PrepareTransRequest>(sid, "PrepareTransRequest", prepareTransRequest);
                //cmTransParameter.SaveObject<string>(sid, "UserID", CustomProfile.Current.UserID.ToString());
                cmTransParameter.SaveObject<string>(sid, "UserID", AsyncManager.Parameters["userID"].ToString());
                //cmTransParameter.SaveObject<string>(sid, "SessionID", CustomProfile.Current.SessionID);
                cmTransParameter.SaveObject<string>(sid, "SessionID", AsyncManager.Parameters["userSessionID"].ToString());
                cmTransParameter.SaveObject<string>(sid, "SuccessUrl", prepareTransRequest.ReturnURL);
                cmTransParameter.SaveObject<string>(sid, "CancelUrl", prepareTransRequest.CancelURL);

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
                        PostBackURL = string.Format(AsyncManager.Parameters["postBackURL"].ToString(), sid),
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
            )
        {
            try
            {
                if (exception != null)
                    throw exception;

                string receiptUrl = this.Url.RouteUrlEx("Deposit", new { @action = "Receipt", @paymentMethodName = paymentMethodName, @sid = sid });
                CustomProfile.Current.Set("ReceiptUrl", receiptUrl);

                cmTransParameter.SaveObject<ProcessTransRequest>(sid, "ProcessTransRequest", processTransRequest);

                if (processTransRequest.Record.Status == PreTransStatus.Success
                    || processTransRequest.Record.Status == PreTransStatus.Processing)
                {
                    string url = this.Url.RouteUrlEx("Deposit", new { @action = "Receipt", @paymentMethodName = paymentMethodName, @sid = sid });
                    return this.Redirect(url);
                }
                else if (processTransRequest.Record.Status == PreTransStatus.AsyncSent)
                {
                    string xml = processTransRequest.ResponseFields["api_response"];
                    if (string.IsNullOrWhiteSpace(xml))
                        throw new Exception("Empty [api_response] from GmCore.");

                    cmTransParameter.SaveObject<string>(sid, "InPayApiResponseXml", xml);

                    string url = this.Url.RouteUrlEx("Deposit", new { @action = "Confirmation", @paymentMethodName = paymentMethodName, @sid = sid });
                    return this.Redirect(url);
                }
                else
                    throw new InvalidOperationException();
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
        #endregion

        [HttpGet]
        [RequireLogin]
        #region Confirmation
        public ActionResult Confirmation(string paymentMethodName, string sid)
        {
            try
            {
                PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
                    .FirstOrDefault(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.InvariantCultureIgnoreCase));
                if (paymentMethod == null)
                    throw new ArgumentException();

                if (paymentMethod.VendorID == VendorID.TxtNation)
                {
                    var realAmount = 0M;

                    if (!decimal.TryParse(sid, out realAmount))
                    {
                        throw new ArgumentOutOfRangeException("sid");
                    }

                    this.ViewData["paymentMethod"] = paymentMethod;

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

                    return View("ConfirmTxtNation", prepareTransactionRequest);
                }

                PrepareTransRequest prepareTransRequest = cmTransParameter.ReadObject<PrepareTransRequest>(sid, "PrepareTransRequest");
                if (prepareTransRequest == null)
                    throw new ArgumentOutOfRangeException("sid");

                this.ViewData["paymentMethod"] = paymentMethod;

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

                return this.View("Confirmation", prepareTransRequest);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return this.View("Error");
            }
        }
        #endregion


        #region Postback
        /// <summary>
        /// This action is called by 3rd-party payment gateway when the transaction is completed.
        /// </summary>
        /// <param name="sid"></param>
        /// <returns></returns>
        [ValidateInput(false)]
        public void PostbackAsync(string paymentMethodName, string sid)
        {
            if (string.IsNullOrWhiteSpace(sid))
                sid = Request["gm_sid"].DefaultIfNullOrEmpty(Request["transaction_id"]);

            Logger.Information("Deposit", "Postback {0} {1}", sid, paymentMethodName);

            if (string.IsNullOrWhiteSpace(sid))
                throw new ArgumentNullException("sid");

            AsyncManager.Parameters["sid"] = sid;
            AsyncManager.Parameters["paymentMethodName"] = paymentMethodName;

            Dictionary<string, string> d = new Dictionary<string, string>();
            foreach (string name in Request.Params.Keys)
            {
                if (!string.IsNullOrEmpty(name))
                    d[name] = (string)Request.Params[name];
            }
            d["REMOTE_ADDR"] = Request.GetRealUserAddress();
            d["gm_sid"] = sid;

            ProcessAsyncTransRequest processAsyncTransRequest = new ProcessAsyncTransRequest()
            {
                ResponseFields = d,
                SecretKey = cmTransParameter.ReadObject<string>(sid, "SecurityKey").DefaultDecrypt(),
                ForbidDoubleBooking = true,
                IsFirstDepositBonusTCAccepted = cmTransParameter.ReadObject<bool>(sid, "BonusAccepted"),
            };

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
            , Exception exception
            )
        {
            try
            {
                try
                {
                    if (exception != null)
                        throw exception;

                    cmTransParameter.SaveObject<ProcessAsyncTransRequest>(sid, "ProcessAsyncTransRequest", processAsyncTransRequest);

                    SendReceiptEmail(paymentMethodName, sid);
                    this.ViewData["RedirectUrl"] = this.Url.RouteUrlEx("Deposit", new { @action = "Receipt", @paymentMethodName = paymentMethodName, @sid = sid });
                    return View("SuccessRedirect");
                }
                catch (GmException gex)
                {
                    // handle the sensitive error codes for EntroPay
                    if (Settings.EntroPay_SensitiveErrorCodes.
                        FirstOrDefault(e => string.Equals(e, gex.ReplyResponse.ErrorCode, StringComparison.InvariantCultureIgnoreCase)) != null)
                    {
                        string url = this.Url.RouteUrl("Deposit", new { @action = "EntroPay", @sid = sid });
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
                return View("Error");
            }
        }
        #endregion

        [RequireLogin]
        #region Confirm
        public void ConfirmAsync(string paymentMethodName, string sid)
        {
            try
            {
                AsyncManager.Parameters["paymentMethodName"] = paymentMethodName;
                AsyncManager.Parameters["sid"] = sid;

                PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
                    .FirstOrDefault(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.InvariantCultureIgnoreCase));
                if (paymentMethod == null)
                    throw new ArgumentException();

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
                            PostBackURL = this.Url.RouteUrlEx("Deposit", new { @action = "Postback", @paymentMethodName = paymentMethodName, @sid = sid }),
                            SecretKey = cmTransParameter.ReadObject<string>(sid, "SecurityKey").DefaultDecrypt(),
                            InputValue1 = cmTransParameter.ReadObject<string>(sid, "InputValue1").DefaultDecrypt(),
                            InputValue2 = cmTransParameter.ReadObject<string>(sid, "InputValue2").DefaultDecrypt(),
                            ReturnURL = this.Url.RouteUrlEx("Deposit", new { @action = "Return" }),
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
            catch (Exception ex)
            {
                AsyncManager.Parameters["exception"] = ex;
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
            try
            {
                if (exception != null)
                    throw exception;

                if (prepareTransRequest.Record.Status == PreTransStatus.Setup)
                {
                    cmTransParameter.SaveObject<ProcessTransRequest>(sid, "ProcessTransRequest", processTransRequest);

                    if (processTransRequest.Record.Status == PreTransStatus.Success)
                    {
                        string url = this.Url.RouteUrlEx("Deposit", new { @action = "Receipt", @paymentMethodName = paymentMethodName, @sid = sid });
                        return this.Redirect(url);
                    }
                    else if (processTransRequest.Record.Status == PreTransStatus.AsyncSent)
                    {
                        // for EcoCard etc
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
                    }

                    this.ViewData["FormHtml"] = prepareTransRequest.RedirectForm;
                }

                return View("PaymentFormPost");
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

        public ActionResult Receipt(string paymentMethodName, string sid)
        {
            try
            {
                PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
                    .FirstOrDefault(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.InvariantCultureIgnoreCase));
                if (paymentMethod == null)
                    throw new ArgumentException();

                PrepareTransRequest prepareTransRequest = cmTransParameter.ReadObject<PrepareTransRequest>(sid, "PrepareTransRequest");
                if (prepareTransRequest == null)
                    throw new ArgumentOutOfRangeException("sid");

                ProcessTransRequest processTransRequest = cmTransParameter.ReadObject<ProcessTransRequest>(sid, "ProcessTransRequest");
                ProcessAsyncTransRequest processAsyncTransRequest = cmTransParameter.ReadObject<ProcessAsyncTransRequest>(sid, "ProcessAsyncTransRequest");
                GetTransInfoRequest getTransInfoRequest = null;
                
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

                var lastError = cmTransParameter.ReadObject<string>(sid, "LastError");

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
                else
                {
                    if (paymentMethod.VendorID == VendorID.EnterCash)
                        return View("EnterCashNotCompleted");
                    this.ViewData["PaymentMethod"] = paymentMethod;
                    return View("NotCompleted");
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return View("Error");
            }
        }

        public ActionResult Cancel()
        {
            return View();
        }

        public ActionResult Return()
        {
            string receiptUrl = CustomProfile.Current.Get("ReceiptUrl");

            if (!string.IsNullOrWhiteSpace(receiptUrl))
            {
                this.ViewData["RedirectUrl"] = receiptUrl;
            }
            Logger.Information("Deposit", "Return, Redirect Url = {0}", receiptUrl);
            return View("SuccessRedirect");
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
                    mail.ReplaceDirectory["TRANSACTION_SITE"] = string.Format("http://{0}:{1}", Request.Url.Host, SiteManager.Current.HttpPort);
                    mail.ReplaceDirectory["TRANSACTION_TIME"] = getTransInfoRequest.TransData.TransCompleted.ToString("dd/MM/yyyy HH:mm:ss");

                    // the email will be sent by another server
                    string url = string.Format("http://{0}:{1}/{2}{3}"
                        , Request.Url.Host
                        , SiteManager.Current.HttpPort
                        , Request.GetLanguage()
                        , this.Url.RouteUrl("Deposit", new { @action = "Receipt", @paymentMethodName = paymentMethodName, @sid = sid, @_sid = cmTransParameter.ReadObject<string>(sid, "SessionID") })
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
                    request.Headers.Add("IsMobile", "yes");
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

        #region PrepareEutellerTransaction
        private void PrepareEutellerTransaction(long payCardID
            , long creditAccountID
            , string currency
            , decimal amount
            )
        {
            InternalPrepareTransactionAsync(payCardID
                , creditAccountID
                , currency
                , amount
                );
        }
        #endregion

        #region PrepareCreditCardTransaction
        private void PrepareCreditCardTransaction(long? payCardID
            , long creditAccountID
            , string currency
            , decimal amount
            , string identityNumber
            , string securityKey
            , string ownerName
            , string issueNumber
            , string validFrom
            , string expiryDate
            )
        {
            if (!payCardID.HasValue || payCardID.Value == 0)
            {
                try
                {
                    payCardID = RegisterPayCard(VendorID.PaymentTrust
                        , identityNumber
                        , ownerName
                        , validFrom
                        , expiryDate
                        );
                }
                catch (GmException gex)
                {
                    bool ignoreException = false;
                    // try to find the existing card
                    if (gex.ReplyResponse.ErrorCode == "SYS_1021")
                    {
                        List<PayCardInfoRec> payCards = GamMatrixClient.GetPayCards(VendorID.PaymentTrust);
                        PayCardInfoRec payCard = payCards.FirstOrDefault(p => p.DisplayNumber.Substring(0, 6) == identityNumber.Substring(0, 6) &&
                            p.DisplayNumber.Substring(p.DisplayNumber.Length - 4, 4) == identityNumber.Substring(identityNumber.Length - 4, 4)
                            );
                        if (payCard != null)
                        {
                            payCardID = payCard.ID;
                            ignoreException = true;
                        }
                    }

                    if (!ignoreException)
                        throw;
                }
            }

            AsyncManager.Parameters["securityKey"] = securityKey;

            InternalPrepareTransactionAsync(payCardID.Value
                , creditAccountID
                , currency
                , amount
                );
        }
        #endregion

        #region PrepareTrustlyTransaction
        private void PrepareTrustlyTransaction(long payCardID
            , long creditAccountID
            , string currency
            , decimal amount
            )
        {
            InternalPrepareTransactionAsync(payCardID
                , creditAccountID
                , currency
                , amount
                );
        }
        #endregion

        #region PreparePaysafecardTransaction
        private void PreparePaysafecardTransaction(long payCardID
            , long creditAccountID
            , string currency
            , decimal amount
            )
        {
            InternalPrepareTransactionAsync(payCardID
                , creditAccountID
                , currency
                , amount
                );
        }
        #endregion

        #region PrepareNetellerTransaction
        private void PrepareNetellerTransaction(long? payCardID
            , string identityNumber
            , string securityKey
            , long creditAccountID
            , string currency
            , decimal amount
            )
        {
            // attempt to find existing card
            if (!payCardID.HasValue)
            {
                PayCardInfoRec card = GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.Neteller).OrderByDescending(c => c.Ins).FirstOrDefault();
                if (card != null)
                    payCardID = card.ID;
            }

            // register the paycard if not exist
            if (!payCardID.HasValue)
            {
                payCardID = RegisterPayCard(VendorID.Neteller, identityNumber, null, null, null);
            }

            InternalPrepareTransactionAsync(payCardID.Value
                , creditAccountID
                , currency
                , amount
                );
        }
        #endregion

        #region PrepareUkashTransaction
        private void PrepareBoCashTransaction(long payCardID
            , long creditAccountID
            , string currency
            , decimal amount
            , string inputValue
            )
        {
            AsyncManager.Parameters["inputValue1"] = inputValue;


            InternalPrepareTransactionAsync(payCardID
                , creditAccountID
                , currency
                , amount
                );
        }
        #endregion

        #region PrepareUkashTransaction
        private void PrepareUkashTransaction(long payCardID
            , long creditAccountID
            , string currency
            , decimal amount
            , string inputValue1
            , string inputValue2
            )
        {
            AsyncManager.Parameters["inputValue1"] = inputValue1;

            // Ukash value must be end with 2 digits cent
            if (Settings.Ukash_AllowPartialDeposit)
                inputValue2 = decimal.Parse(inputValue2, CultureInfo.InvariantCulture).ToString("0.00", CultureInfo.InvariantCulture);
            else
                inputValue2 = amount.ToString("0.00", CultureInfo.InvariantCulture);
            AsyncManager.Parameters["inputValue2"] = inputValue2;


            InternalPrepareTransactionAsync(payCardID
                , creditAccountID
                , currency
                , amount
                );
        }
        #endregion

        #region PrepareMoneybookersTransaction
        private void PrepareMoneybookersTransaction(long payCardID
            , long creditAccountID
            , string currency
            , decimal amount
            , string email
            )
        {
            InternalPrepareTransactionAsync(payCardID
                , creditAccountID
                , currency
                , amount
                );
        }
        #endregion

        #region PrepareMoneybookers1TapTransaction
        private void PrepareMoneybookers1TapTransaction(long payCardID
            , long creditAccountID
            , string currency
            , decimal amount
            , string tempExternalReference
            )
        {
            string paymentType = string.IsNullOrWhiteSpace(tempExternalReference)
                ? "Skrill1Tap"
                : "Skrill1TapSetup";

            InternalPrepareTransactionAsync(payCardID
                , creditAccountID
                , currency
                , amount
                , paymentType
                , tempExternalReference
                );
        }
        #endregion

        #region PrepareTLNakitTransaction
        private void PrepareTLNakitTransaction(long payCardID
            , long creditAccountID
            , string currency
            , decimal amount
            , string cardNumber
            )
        {
            AsyncManager.Parameters["inputValue1"] = cardNumber;

            InternalPrepareTransactionAsync(payCardID
                , creditAccountID
                , currency
                , amount
                );
        }
        #endregion

        #region PrepareEcoCardTransaction
        private void PrepareEcoCardTransaction(long payCardID
            , long creditAccountID
            , string currency
            , decimal amount
            )
        {
            InternalPrepareTransactionAsync(payCardID
                , creditAccountID
                , currency
                , amount
                );
        }
        #endregion

        #region PrepareUiPasTransaction
        private void PrepareUiPasTransaction(long? payCardID
            , string identityNumber
            , string securityKey
            , long creditAccountID
            , string currency
            , decimal amount
            )
        {
            // attempt to find existing card
            if (!payCardID.HasValue)
            {
                PayCardInfoRec card = GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.UiPas)
                                      .Where(c => !c.IsDummy)
                                      .OrderByDescending(c => c.Ins).FirstOrDefault();
                if (card != null)
                    payCardID = card.ID;
            }

            // register the paycard if not exist
            if (!payCardID.HasValue)
            {
                payCardID = RegisterPayCard(VendorID.UiPas, identityNumber, null, null, null);
            }

            InternalPrepareTransactionAsync(payCardID.Value
                , creditAccountID
                , currency
                , amount
                );
        }
        #endregion

        #region PrepareIPGTransaction
        private void PrepareIPGTransaction(long payCardID
            , long creditAccountID
            , string currency
            , decimal amount
            )
        {
            InternalPrepareTransactionAsync(payCardID
                , creditAccountID
                , currency
                , amount
                );
        }
        #endregion

        #region PrepareAPXTransaction
        private void PrepareAPXTransaction(long payCardID
            , long creditAccountID
            , string currency
            , decimal amount
            )
        {
            InternalPrepareTransactionAsync(payCardID
                , creditAccountID
                , currency
                , amount
                );
        }
        #endregion

        #region PrepareEnterCashTransaction
        private void PrepareEnterCashTransaction(long payCardID
            , long creditAccountID
            , string currency
            , decimal amount
            , string enterCashBankID
            , string verificationCode
            )
        {
            AsyncManager.Parameters["inputValue1"] = enterCashBankID;
            if (!string.IsNullOrWhiteSpace(verificationCode))
                AsyncManager.Parameters["inputValue2"] = verificationCode;
            InternalPrepareTransactionAsync(payCardID
                , creditAccountID
                , currency
                , amount
                );
        }
        #endregion

        #region PrepareGCETransaction
        private void PrepareGCETransaction(long payCardID
            , long creditAccountID
            , string currency
            , decimal amount
            )
        {
            InternalPrepareTransactionAsync(payCardID
                , creditAccountID
                , currency
                , amount
                );
        }
        #endregion

        #region PreparePugglePayTransaction
        private void PreparePugglePayTransaction(long payCardID
            , long creditAccountID
            , string currency
            , decimal amount
            )
        {
            InternalPrepareTransactionAsync(payCardID
                , creditAccountID
                , currency
                , amount
                );
        }
        #endregion

        #region PrepareVoucherTransaction
        private void PrepareVoucherTransaction(long? payCardID
            , string voucherNumber
            , string securityKey
            , long creditAccountID
            , string currency
            , decimal amount
            )
        {
            AsyncManager.Parameters["InputValue1"] = voucherNumber;
            AsyncManager.Parameters["securityKey"] = securityKey;

            InternalPrepareTransactionAsync(payCardID.Value
                , creditAccountID
                , currency
                , amount
                );
        }
        #endregion

        #region InternalPrepareTransactionAsync
        protected void InternalPrepareTransactionAsync(long payCardID
            , long creditAccountID
            , string currency
            , decimal amount
            , string paymentType = null
            , string tempExternalReference = null
            )
        {
            AsyncManager.Parameters["payCardID"] = payCardID;

            PrepareTransRequest prepareTransRequest = new PrepareTransRequest()
            {

                Record = new PreTransRec()
                {
                    TransType = TransType.Deposit,
                    DebitPayCardID = payCardID,
                    CreditAccountID = creditAccountID,
                    RequestAmount = amount,
                    RequestCurrency = currency,
                    UserID = CustomProfile.Current.UserID,
                    UserIP = Request.GetRealUserAddress(),
                    IsMobile = true,
                    PaymentType = paymentType,
                    TempExternalReference = tempExternalReference,
                },
                IsWindowOwner = false,
                IsRequiredRedirectForm = true,
                IovationBlackBox = Request.Form["iovationBlackBox"],
                RedirectFormName = "depositForm",
                RedirectFormTarget = "_self",
                IsRequiredRedirectURL = false,
                PostBackURL = this.Url.RouteUrlEx("Deposit", new { @action = "Postback", @paymentMethodName = AsyncManager.Parameters["paymentMethodName"] }),
                PostBackURLTarget = "_self",
                CancelURL = this.Url.RouteUrlEx("Deposit", new { @action = "Cancel" }),
                CancelURLTarget = "_self",
                ReturnURL = this.Url.RouteUrlEx("Deposit", new { @action = "Return" }),
                ReturnURLTarget = "_self",
                //DepositSource = DepositSource.MainDepositPage,
            };

            if (Settings.IovationDeviceTrack_Enabled)
            {
                prepareTransRequest.IovationBlackBox = Request.Form["iovationBlackBox"];
            }

            string bonusCode = AsyncManager.Parameters["bonusCode"] as string;
            string bonusVendor = AsyncManager.Parameters["bonusVendor"] as string;

            if (!string.IsNullOrWhiteSpace(bonusCode))
            {
                List<AccountData> accounts = GamMatrixClient.GetUserGammingAccounts(CustomProfile.Current.UserID);
                AccountData account = accounts.FirstOrDefault(a => a.ID == creditAccountID);
                if (account != null)
                {
                    VendorID bonusVendorID;
                    if (!Enum.TryParse(bonusVendor, out bonusVendorID))
                        bonusVendorID = account.Record.VendorID;

                    prepareTransRequest.ApplyBonusVendorID = bonusVendorID;
                    prepareTransRequest.ApplyBonusCode = bonusCode.Trim();
                }
            }

            PaymentMethod paymentMethod = AsyncManager.Parameters["paymentMethod"] as PaymentMethod;
            // for MB and Dotpay, pass the sub code
            if (paymentMethod.VendorID == VendorID.Moneybookers ||
                paymentMethod.VendorID == VendorID.Dotpay)
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
                    prepareTransRequest.RequestFields["VoucherCode"] = AsyncManager.Parameters["VoucherCode"] as string;
                }

                if (paymentMethod.SubCode == "OtoPay")
                {
                    prepareTransRequest.RequestFields["SecurityKey"] = AsyncManager.Parameters["SecurityKey"] as string;
                }

                if (paymentMethod.SubCode == "i-Banq")
                {
                    prepareTransRequest.RequestFields["BanqUserId"] = AsyncManager.Parameters["BanqUserId"] as string;
                    prepareTransRequest.RequestFields["BanqUserPassword"] = AsyncManager.Parameters["BanqUserPassword"] as string;
                }

                if (paymentMethod.SubCode == "CreditCard")
                {
                    prepareTransRequest.RequestFields["MonitoringSessionId"] = AsyncManager.Parameters["MonitoringSessionId"] as string;
                }

                if (paymentMethod.SubCode == "Skrill")
                {
                    const string skrillEmailAddressKey = "SkrillEmailAddress";

                    prepareTransRequest.RequestFields[skrillEmailAddressKey] = AsyncManager.Parameters.ContainsKey(skrillEmailAddressKey)
                            ? AsyncManager.Parameters[skrillEmailAddressKey] as string
                            : string.Empty;

                    const string skrillReSetupOneTapKey = "SkrillReSetupOneTap";

                    prepareTransRequest.RequestFields[skrillReSetupOneTapKey] = AsyncManager.Parameters.ContainsKey(skrillReSetupOneTapKey)
                            ? AsyncManager.Parameters[skrillReSetupOneTapKey] as string
                            : bool.FalseString;

                    const string skrillUseOneTapKey = "SkrillUseOneTap";

                    prepareTransRequest.RequestFields[skrillUseOneTapKey] = AsyncManager.Parameters.ContainsKey(skrillUseOneTapKey)
                            ? AsyncManager.Parameters[skrillUseOneTapKey] as string
                            : bool.FalseString;
                }

                if (paymentMethod.SubCode == "TlNakit")
                {
                    prepareTransRequest.RequestFields["TlNakitCardNumber"] = AsyncManager.Parameters["TlNakitCardNumber"] as string;
                }

                if (paymentMethod.SubCode == "Neteller")
                {
                    prepareTransRequest.RequestFields["NetellerEmailAddressOrAccountId"] = AsyncManager.Parameters["NetellerEmailAddressOrAccountId"] as string;
                    prepareTransRequest.RequestFields["NetellerSecret"] = AsyncManager.Parameters["NetellerSecret"] as string;
                }

                if (paymentMethod.SubCode == "PPro.Sofort")
                {
                    prepareTransRequest.RequestFields["BankSwiftCode"] = AsyncManager.Parameters["BankSwiftCode"] as string;
                }

                if (paymentMethod.SubCode == "PPro.GiroPay")
                {
                    prepareTransRequest.RequestFields["BankSwiftCode"] = AsyncManager.Parameters["BankSwiftCode"] as string;
                }

                if (paymentMethod.SubCode == "PPro.Boleto")
                {
                    prepareTransRequest.RequestFields["PProBoletoNationalId"] = AsyncManager.Parameters["PProBoletoNationalId"] as string;
                    prepareTransRequest.RequestFields["PProBoletoEmail"] = AsyncManager.Parameters["PProBoletoEmail"] as string;
                    prepareTransRequest.RequestFields["PProBoletoBirthDate"] = AsyncManager.Parameters["PProBoletoBirthDate"] as string;
                }

                if (paymentMethod.SubCode == "PPro.Qiwi")
                {
                    prepareTransRequest.RequestFields["PProQiwiMobilePhone"] = AsyncManager.Parameters["PProQiwiMobilePhone"] as string;
                }

                if (paymentMethod.SubCode == "PPro.Przelewy24")
                {
                    prepareTransRequest.RequestFields["PProPrzelewy24Email"] = AsyncManager.Parameters["PProPrzelewy24Email"] as string;
                }

                if (paymentMethod.SubCode == "Offline.Nordea" || paymentMethod.SubCode == "Offline.LocalBank")
                {
                    var paymentMethodDetails = GamMatrixClient.GetPaymentSolutionDetails(paymentMethod.SubCode);
                    foreach (var field in paymentMethodDetails.Metadata.Fields.Where(f => f.ForDeposit && f.RequiresUserInput))
                    {
                        prepareTransRequest.RequestFields[field.Key] = AsyncManager.Parameters[field.Key] as string;
                    }
                }
            }

            GamMatrixClient.SingleRequestAsync<PrepareTransRequest>(prepareTransRequest
                        , OnInternalPrepareTransactionCompleted
                        );
            AsyncManager.OutstandingOperations.Increment();
        }

        private void OnInternalPrepareTransactionCompleted(AsyncResult reply)
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
        #endregion

        #region RegisterPayCard
        private long RegisterPayCard(VendorID vendorID
            , string identityNumber
            , string ownerName
            , string validFrom
            , string expiryDate
            )
        {
            DateTime temp;
            PayCardRec payCard = new PayCardRec();
            payCard.VendorID = vendorID;
            payCard.ActiveStatus = ActiveStatus.Active;
            payCard.UserID = CustomProfile.Current.UserID;

            if (!string.IsNullOrWhiteSpace(identityNumber))
            {
                payCard.IdentityNumber = identityNumber;
            }

            // for payment methods except CC, indicate the DisplayName and DisplayNumber
            if (vendorID != VendorID.PaymentTrust && vendorID != VendorID.PayPoint)
            {
                payCard.DisplayName = identityNumber;
                payCard.DisplayNumber = identityNumber;
            }

            if (!string.IsNullOrWhiteSpace(ownerName))
                payCard.OwnerName = ownerName;

            if (!string.IsNullOrWhiteSpace(validFrom) &&
                DateTime.TryParseExact(validFrom, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out temp))
                payCard.ValidFrom = temp;

            if (!string.IsNullOrWhiteSpace(expiryDate) &&
                DateTime.TryParseExact(expiryDate, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out temp))
                payCard.ExpiryDate = temp;

            return GamMatrixClient.RegisterPayCard(payCard);
        }
        #endregion

        #region RegisterPayCard for MoneyMatrix

        private long RegisterMoneyMatrixCreditCardPayCard(string identityNumber
            , string ownerName
            , string expiryDate
            , string validFrom)
        {
            var payCard = new PayCardRec();
            payCard.VendorID = VendorID.MoneyMatrix;
            payCard.ActiveStatus = ActiveStatus.Active;
            payCard.UserID = CustomProfile.Current.UserID;

            if (!string.IsNullOrWhiteSpace(identityNumber))
            {
                payCard.IdentityNumber = identityNumber;
            }

            payCard.BrandType = Request["cardType"];
            payCard.IssuerCompany = Request["IssuerCompany"];
            payCard.IssuerCountry = Request["IssuerCountry"];

            var displayNumber = Request["displayNumber"];

            if (!string.IsNullOrEmpty(displayNumber))
            {
                payCard.DisplayNumber = identityNumber;
                payCard.DisplayName = displayNumber;
            }

            DateTime temp;

            if (!string.IsNullOrWhiteSpace(ownerName))
                payCard.OwnerName = ownerName;

            if (!string.IsNullOrWhiteSpace(validFrom) &&
                DateTime.TryParseExact(validFrom, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out temp))
                payCard.ValidFrom = temp;

            if (!string.IsNullOrWhiteSpace(expiryDate) &&
                DateTime.TryParseExact(expiryDate, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out temp))
                payCard.ExpiryDate = temp;

            return GamMatrixClient.RegisterPayCard(payCard);
        }
        #endregion

        #region PrepareMoneyMatrixTransaction

        private void PrepareMoneyMatrixTransaction(
            string uniqueName
            , long? payCardID
            , long creditAccountID
            , string currency
            , decimal amount
            )
        {
            if (uniqueName == "MoneyMatrix_PayKasa" || uniqueName == "MoneyMatrix_OtoPay")
            {
                AsyncManager.Parameters["VoucherCode"] = Request.Form["VoucherCode"];
            }

            if (uniqueName == "MoneyMatrix_Neteller")
            {
                AsyncManager.Parameters["NetellerEmailAddressOrAccountId"] = Request.Form["NetellerEmailAddressOrAccountId"];
                AsyncManager.Parameters["NetellerSecret"] = Request.Form["NetellerSecret"];
            }

            if (uniqueName == "MoneyMatrix_OtoPay")
            {
                AsyncManager.Parameters["SecurityKey"] = Request.Form["SecurityKey"];
            }

            if (uniqueName == "MoneyMatrix_IBanq")
            {
                AsyncManager.Parameters["BanqUserId"] = Request.Form["BanqUserId"];
                AsyncManager.Parameters["BanqUserPassword"] = Request.Form["BanqUserPassword"];
            }

            if (uniqueName == "MoneyMatrix")
            {
                AsyncManager.Parameters["MonitoringSessionId"] = Request.Form["MonitoringSessionId"];
            }

            if (uniqueName == "MoneyMatrix_Skrill")
            {
                AsyncManager.Parameters["SkrillEmailAddress"] = Request.Form["SkrillEmailAddress"];
            }

            if (uniqueName == "MoneyMatrix_Skrill_1Tap")
            {
                AsyncManager.Parameters["SkrillEmailAddress"] = Request.Form["SkrillEmailAddress"];
                AsyncManager.Parameters["SkrillReSetupOneTap"] = Request.Form["SkrillReSetupOneTap"];
                AsyncManager.Parameters["SkrillUseOneTap"] = Request.Form["SkrillUseOneTap"];
            }

            if (uniqueName == "MoneyMatrix_TLNakit")
            {
                AsyncManager.Parameters["TlNakitCardNumber"] = Request.Form["TlNakitCardNumber"];
            }

            if (uniqueName == "MoneyMatrix_Offline_Nordea")
            {
                var paymentMethodDetails = GamMatrixClient.GetPaymentSolutionDetails("Offline.Nordea");
                foreach (var field in paymentMethodDetails.Metadata.Fields.Where(f => f.RequiresUserInput && f.ForDeposit))
                {
                    AsyncManager.Parameters[field.Key] = Request.Form[field.Key];
                }
            }

            if (uniqueName == "MoneyMatrix_Offline_LocalBank")
            {
                var paymentMethodDetails = GamMatrixClient.GetPaymentSolutionDetails("Offline.LocalBank");
                foreach (var field in paymentMethodDetails.Metadata.Fields.Where(f => f.RequiresUserInput && f.ForDeposit))
                {
                    AsyncManager.Parameters[field.Key] = Request.Form[field.Key];
                }
            }

            if (uniqueName == "MoneyMatrix_Visa" || uniqueName == "MoneyMatrix_MasterCard" || uniqueName == "MoneyMatrix_Dankort")
            {
                AsyncManager.Parameters["MonitoringSessionId"] = Request.Form["MonitoringSessionId"];
            }

            InternalPrepareTransactionAsync(payCardID.Value
                , creditAccountID
                , currency
                , amount
                );
        }

        #endregion


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
        [RequireLogin]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult PrepareEnvoyTransaction(string paymentMethodName
            , long creditAccountID
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
                // save the accept bonus by default value for GmCore backend
                AccountData account = GamMatrixClient.GetUserGammingAccounts(CustomProfile.Current.UserID, true).FirstOrDefault(a => a.ID == creditAccountID);
                SetBonusDefaultOption(acceptBonus.HasValue && acceptBonus.Value);


                PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
                    .FirstOrDefault(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.InvariantCultureIgnoreCase));
                if (paymentMethod == null)
                    throw new ArgumentOutOfRangeException("paymentMethodName");

                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    EnvoyGetOneClickGatewayRequest envoyGetOneClickGatewayRequest = new EnvoyGetOneClickGatewayRequest
                    {
                        UserID = CustomProfile.Current.UserID,
                        PaymentType = paymentMethod.SubCode,
                        CreditAccountID = creditAccountID,

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
                            envoyGetOneClickGatewayRequest.RequestAmount = requestAmount;
                            envoyGetOneClickGatewayRequest.RequestCurrency = currency;
                        }
                    }

                    if (!string.IsNullOrWhiteSpace(bonusCode))
                    {
                        if (account != null)
                        {
                            VendorID bonusVendorID;
                            if (!Enum.TryParse(bonusVendor, out bonusVendorID))
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
                        , this.Url.RouteUrlEx("Deposit", new { @action = "EnvoyPostback", @paymentMethodName = paymentMethodName, @gammingAccountID = creditAccountID.ToString(), @result = "success" })
                        );
                    cmTransParameter.SaveObject<string>(uid
                        , "ErrorUrl"
                        , this.Url.RouteUrlEx("Deposit", new { @action = "EnvoyPostback", @paymentMethodName = paymentMethodName, @gammingAccountID = creditAccountID.ToString(), @result = "error" })
                        );
                    cmTransParameter.SaveObject<string>(uid
                        , "CancelUrl"
                        , this.Url.RouteUrlEx("Deposit", new { @action = "EnvoyPostback", @paymentMethodName = paymentMethodName, @gammingAccountID = creditAccountID.ToString(), @result = "cancel" })
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

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        [OutputCache(Duration = 0, VaryByParam = "None")]
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
                string receiptUrl = this.Url.RouteUrlEx("Deposit", new { @action = "Receipt", @paymentMethodName = paymentMethodName, @sid = sid });
                return this.Redirect(receiptUrl);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                string friendlyError = GmException.TryGetFriendlyErrorMsg(ex);
                cmTransParameter.SaveObject<string>(sid, "LastError", friendlyError);
                string receiptUrl = this.Url.RouteUrlEx("Deposit", new { @action = "Receipt", @paymentMethodName = paymentMethodName, @sid = sid });
                return this.Redirect(receiptUrl);
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

        [HttpPost]
        public ActionResult PrepareTxtNationTransaction(decimal amount
            , string windowSize
            , long creditAccountID
            , string currency = null
            , string payCardID = null
            , string bonusCode = null
            , string bonusVendor = null
            )
        {
            string error = string.Empty;
            try
            {
                var result = GetTxtNationRedirectUrl(amount, CustomProfile.Current.UserID, windowSize, bonusCode, bonusVendor, creditAccountID);
                bool success = result.Item1;
                string url = result.Item2;
                long transID = result.Item3;

                if (success)
                {
                    ViewData["Url"] = url;
                    ViewData["TransID"] = transID;

                    return Confirmation("TxtNation", amount.ToString());
                }
                else
                {
                    error = url;
                }
            }
            catch (Exception ex)
            {
                error = GmException.TryGetFriendlyErrorMsg(ex);
            }

            ViewData["Error"] = error;

            return TxtNationFail();

        }

        /// <summary>
        /// GetTxtNationRedirectUrl 
        /// </summary>
        /// <param name="amount"></param>
        /// <param name="userId"></param>
        /// <param name="windowSize"></param>
        /// <param name="bonusCode"></param>
        /// <param name="bonusVendor"></param>
        /// <param name="gammingAccountID"></param>
        /// <returns>bool: success, string:RedirectUrl or error,long:TransID  </returns>
        public Tuple<bool, string, long> GetTxtNationRedirectUrl(
           decimal amount,
           long userId,
           string windowSize,
           string bonusCode,
           string bonusVendor,
           long creditAccountID)
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
                    AccountData account = accounts.FirstOrDefault(a => a.ID == creditAccountID);

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
            return new Tuple<bool, string, long>(success, data, txtNationTransID);
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
                PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
             .FirstOrDefault(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.InvariantCultureIgnoreCase));
                ViewData["PaymentMethod"] = paymentMethod;

                return View("NotCompleted");
            }

            return Receipt(paymentMethodName, sid);
        }

        [OutputCache(Duration = 0, VaryByParam = "None")]
        public ActionResult Error()
        {
            return View("Error");
        }


        #region mobile  localBank
        [HttpPost]
        public ActionResult PrepareLocalBank(string deposit)
        {
            if (!CustomProfile.Current.IsEmailVerified)
            {
                UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                cmUser user = ua.GetByID(CustomProfile.Current.UserID);
                if (!user.IsEmailVerified)
                    return View("EmailNotVerified");
                else if (!CustomProfile.Current.IsEmailVerified)
                    CustomProfile.Current.IsEmailVerified = true;
            }

            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
                .FirstOrDefault(p => string.Equals(p.UniqueName, "LocalBank", StringComparison.InvariantCultureIgnoreCase));
            if (paymentMethod == null)
                throw new ArgumentOutOfRangeException();
            if (paymentMethod.VendorID != VendorID.LocalBank)
                throw new ArgumentException();

            var stateVars = new Dictionary<string, string>
            {
                { "amount" , deposit },
            };
            return View("PrepareLocalBank", new PrepareLocalBankViewModel(paymentMethod, stateVars));
        }
        [HttpPost]
        public ActionResult ConfirmLocalBank()
        {
            string payCardID = Request.Form["payCardID"];
            if (string.IsNullOrWhiteSpace(Request.Form["payCardID"]))
            {
                long newPayCardID = RegisterLocalBankPayCard(Request.Form["bankName"], Request.Form["nameOnAccount"], Request.Form["bankAccountNo"]);
                payCardID = newPayCardID.ToString();
            }

            var stateVars = new Dictionary<string, string>
            {
                { "amount" , Request.Form["amount"] },
                { "bankName" , Request.Form["bankName"] },
                { "nameOnAccount" , Request.Form["nameOnAccount"] },
                { "bankAccountNo" , Request.Form["bankAccountNo"] },
                { "payCardID" , payCardID },
            };
            return View("ConfirmLocalBank", new ConfirmLocalBankViewModel(stateVars));
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

            //if (CustomProfile.Current.UserCountryID != 223 && CustomProfile.Current.UserCountryID != 202)
            //    throw new ArgumentException("your country did not allowed the bank.");

            string displayNumber = bankAccountNo;
            string identityNumber = bankAccountNo;
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
        #endregion
    }
}