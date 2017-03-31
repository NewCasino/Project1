using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web.Mvc;
using CM.Content;
using CM.db;
using CM.db.Accessor;
using CM.State;
using CM.Web;
using Finance;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Controllers.Daebak88
{
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{paymentMethodName}/{sid}")]
    public class Daebak88DepositController : GamMatrix.CMS.Controllers.Shared.DepositController
    {
        /// <summary>
        /// The prepare view
        /// </summary>
        /// <param name="paymentMethodName"></param>
        /// <returns></returns>
        [HttpGet]
        [OutputCache(Duration = 0, VaryByParam = "None")]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        public override ActionResult Prepare(string paymentMethodName)
        {

            if (!CustomProfile.Current.IsAuthenticated)
                return View("Anonymous");

            UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
            cmUser user = ua.GetByID(CustomProfile.Current.UserID);

            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
    .FirstOrDefault(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.InvariantCultureIgnoreCase));
            if (paymentMethod == null)
                throw new ArgumentOutOfRangeException();

            if (paymentMethod.VendorID != VendorID.LocalBank && !user.IsEmailVerified)
                return View("EmailNotVerified");
            // if the profile is uncompleted, redirect user to profile page
            if (
                paymentMethod.VendorID != VendorID.LocalBank && (
                string.IsNullOrWhiteSpace(user.Address1) ||
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
                CustomProfile.Current.IsInRole("Incomplete Profile")))
            {
                return View("IncompleteProfile");
            }

            else if (!CustomProfile.Current.IsEmailVerified)
                CustomProfile.Current.IsEmailVerified = true;


            //check the payment method
            if (!CheckPaymentMethod(paymentMethod))
                return View("BankNotSupport");
            if (Regex.IsMatch(Metadata.Get("Metadata/Settings/Deposit.Ignore_AstroPayCard_DenyDepositCardrole").DefaultIfNullOrWhiteSpace("NO"), @"(YES)|(ON)|(OK)|(TRUE)|(\1)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled))
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

            switch (paymentMethod.VendorID)
            {

                case VendorID.PaymentTrust:
                    if (string.Equals(paymentMethodName, "PT_VISA_TicketSurf", StringComparison.InvariantCultureIgnoreCase) ||
                        string.Equals(paymentMethodName, "PT_MasterCard_TicketSurf", StringComparison.InvariantCultureIgnoreCase))
                    {
                        this.ViewData["PayCardView"] = "TicketTurfDirectPaymentPayCard";
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

                //case VendorID.Citigate:
                //    this.ViewData["PayCardView"] = "CitigatePayCard";
                //    return View("Prepare", paymentMethod);

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
        /// <summary>
        ///  The list view
        /// </summary>
        /// <returns></returns>
        //[HttpGet]
        //public override ActionResult Index()
        //{
        //    return Prepare("LocalBank");
        //}

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
