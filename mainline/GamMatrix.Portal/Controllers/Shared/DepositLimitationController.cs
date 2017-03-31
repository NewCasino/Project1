using System;
using System.Globalization;
using System.Text.RegularExpressions;
using System.Web.Mvc;
using CM.Sites;
using CM.State;
using CM.Web;
using GamMatrixAPI;
using GmCore;

namespace GamMatrix.CMS.Controllers.Shared
{
    [HandleError]
    [ControllerExtraInfo(DefaultAction = "Index")]
    public class DepositLimitationController : ControllerEx
    {
        [HttpGet]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        public virtual ActionResult Index()
        {
            if (CustomProfile.Current.IsAuthenticated)
            {
                using (GamMatrixClient client = GamMatrixClient.Get() )
                {
                    GetUserRgDepositLimitRequest getUserRgDepositLimitRequest = client.SingleRequest<GetUserRgDepositLimitRequest>(new GetUserRgDepositLimitRequest()
                    {
                        UserID = CustomProfile.Current.UserID
                    });
                    return View("Index", getUserRgDepositLimitRequest.Record);
                }
            }

            return this.View();
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public virtual ActionResult Apply(RgDepositLimitPeriod depositLimitPeriod, string currency, string amount)
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return this.View("Anonymous");

            try
            {
                decimal requestAmount = decimal.Parse(Regex.Replace(amount, @"[^\d\.]", string.Empty), CultureInfo.InvariantCulture);
                using (GamMatrixClient client = GamMatrixClient.Get() )
                {
                    SetUserRgDepositLimitRequest setUserRgDepositLimitRequest = client.SingleRequest<SetUserRgDepositLimitRequest>(new SetUserRgDepositLimitRequest()
                    {
                        UserID = CustomProfile.Current.UserID,
                        Period = depositLimitPeriod,
                        Amount = requestAmount,
                        Currency = currency,
                    });
                }
                return this.View("Success");
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return this.View("Error");
            }
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public virtual ActionResult Remove(RgDepositLimitPeriod? depositLimitPeriod = null)
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return this.View("Anonymous");

            try
            {
                RemoveUserRgDepositLimitRequest removeUserRgDepositLimitRequest = new RemoveUserRgDepositLimitRequest()
                {
                    UserID = CustomProfile.Current.UserID,
                };
                if (depositLimitPeriod.HasValue)
                {
                    removeUserRgDepositLimitRequest.Period = depositLimitPeriod.Value;
                }
                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    client.SingleRequest<RemoveUserRgDepositLimitRequest>(removeUserRgDepositLimitRequest);
                }
                return this.View("Success");
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
