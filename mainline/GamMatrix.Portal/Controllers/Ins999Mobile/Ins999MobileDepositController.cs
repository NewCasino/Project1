using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using CM.db;
using CM.db.Accessor;
using CM.State;
using CM.Web;
using Finance;
using GamMatrix.CMS.Controllers.MobileShared;
using GamMatrix.CMS.Models.MobileShared.Deposit;
using GamMatrix.CMS.Models.MobileShared.Deposit.Prepare;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Controllers.Ins999Mobile
{

    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{paymentMethodName}/{sid}")]
    public class Ins999MobileDepositController : MobileDepositController
    {

        [HttpPost]
        [RequireLogin]
        public ActionResult Account(string paymentMethodName, string deposit)
        {
            UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
            cmUser user = ua.GetByID(CustomProfile.Current.UserID);

            if (!user.IsEmailVerified)
                return View("EmailNotVerified");
            else if (!CustomProfile.Current.IsEmailVerified)
                CustomProfile.Current.IsEmailVerified = true;

            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
                .FirstOrDefault(p => string.Equals(p.UniqueName, "LocalBank", StringComparison.InvariantCultureIgnoreCase));
            if (paymentMethod == null)
                throw new ArgumentOutOfRangeException();

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

            return View(paymentMethod);
        }

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
