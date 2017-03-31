using System;
using System.Globalization;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web.Mvc;

using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.State;
using CM.Web;
using Finance;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Controllers._666betMobile
{
    [ControllerExtraInfo(DefaultAction = "Index", ParameterUrl = "{paymentMethodName}/{sid}")]
    public class _666betMobileDepositController : GamMatrix.CMS.Controllers.MobileShared.MobileDepositController
    {
        /// <summary>
        ///  The list view
        /// </summary>
        /// <returns></returns>
        [HttpGet]
        public ActionResult Index()
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return View("AccessDenied");

            UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
            cmUser user = ua.GetByID(CustomProfile.Current.UserID);

            if (!user.IsEmailVerified)
                return View("EmailNotVerified");
            else if (!CustomProfile.Current.IsEmailVerified)
                CustomProfile.Current.IsEmailVerified = true;

            PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
                .FirstOrDefault(p => string.Equals(p.UniqueName, "IPG", StringComparison.InvariantCultureIgnoreCase));
            if (paymentMethod == null)
                throw new ArgumentOutOfRangeException();

            if (!CheckPaymentMethod(paymentMethod))
                return View("AccessDenied");

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
        [RequireLogin]
        public void ProcessIPGTransactionAsync(string paymentMethodName)
        {
            try
            {
                PaymentMethod paymentMethod = PaymentMethodManager.GetPaymentMethods()
                    .FirstOrDefault(p => string.Equals(p.UniqueName, paymentMethodName, StringComparison.InvariantCultureIgnoreCase));
                if (paymentMethod == null)
                    throw new ArgumentOutOfRangeException("paymentMethodName");

                if (paymentMethod.VendorID != VendorID.IPG)
                    throw new NotSupportedException();

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

                base.InternalPrepareTransactionAsync(payCardID.Value
                    , creditAccountID.Value
                    , currency
                    , amount.Value);
            }
            catch (Exception ex)
            {
                AsyncManager.Parameters["exception"] = ex;
            }
        }

        public ActionResult ProcessIPGTransactionCompleted(string paymentMethodName
            , PrepareTransRequest prepareTransRequest
            , Exception exception
            , string securityKey
            , string inputValue1
            , string inputValue2
            )
        {
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

                if (prepareTransRequest.Record.Status != PreTransStatus.AsyncSent)
                    throw new NotSupportedException();

                this.ViewData["FormHtml"] = prepareTransRequest.RedirectForm;
                return View("PaymentFormPost");
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
