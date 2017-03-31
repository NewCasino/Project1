using System;
using System.Collections;
using System.Collections.Generic;
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
    public class SelfExclusionController : ControllerEx
    {
        [HttpGet]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        public ActionResult Index()
        {
            return View();
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public ActionResult Apply(SelfExclusionPeriod selfExclusionOption)
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return View("Anonymous");

            try
            {
                using (GamMatrixClient client = GamMatrixClient.Get() )
                {                    
                    SetUserRgSelfExclusionRequest setUserRgSelfExclusionRequest = client.SingleRequest<SetUserRgSelfExclusionRequest>(new SetUserRgSelfExclusionRequest()
                    {
                        UserID = CustomProfile.Current.UserID,
                        Period = selfExclusionOption,
                        
                    });
                }
                CustomProfile.Current.Logoff();
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return this.View("Error");
            }

            return this.View("Success");
        }

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public ActionResult ApplySelfExclusion(SelfExclusionPeriod selfExclusionOption, string selectedDate)
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return View("Anonymous");

            DateTime dateUntill = DateTime.MinValue;
            if (selfExclusionOption == SelfExclusionPeriod.SelfExclusionUntilSelectedDate)
            {
                if (string.IsNullOrWhiteSpace(selectedDate))
                    throw new ArgumentNullException();

                if (!DateTime.TryParse(selectedDate, out dateUntill) || dateUntill < DateTime.Now.AddMonths(6))
                    throw new ArgumentException();
            }

            try
            {
                SetUserRgSelfExclusionRequest setUserRgSelfExclusionRequest = new SetUserRgSelfExclusionRequest()
                    {
                        UserID = CustomProfile.Current.UserID,
                        Period = selfExclusionOption,
                        SendNotificationEmail = true,
                    };
                if (selfExclusionOption == SelfExclusionPeriod.SelfExclusionUntilSelectedDate
                    || selfExclusionOption == SelfExclusionPeriod.CoolOffUntilSelectedDate)
                    setUserRgSelfExclusionRequest.ExpiryDate = dateUntill;

                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    setUserRgSelfExclusionRequest = client.SingleRequest<SetUserRgSelfExclusionRequest>(setUserRgSelfExclusionRequest);
                }
                CustomProfile.Current.Logoff();
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return this.View("Error");
            }

            return this.View("Success");
        }


        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public ActionResult ApplyCoolOff(SelfExclusionPeriod coolOffPeriod, string coolOffReason, string coolOffReasonDescription, string unsatisfiedReason = null, string unsatisfiedDescription = null, string selectedDate = null)
        {
            if (!CustomProfile.Current.IsAuthenticated)
                return View("Anonymous");

            DateTime dateUntill = DateTime.MinValue;
            if (coolOffPeriod == SelfExclusionPeriod.CoolOffUntilSelectedDate)
            {
                if (string.IsNullOrWhiteSpace(selectedDate))
                    throw new ArgumentNullException();

                if ( !DateTime.TryParse(selectedDate, out dateUntill) || dateUntill > DateTime.Now.AddMonths(6))
                    throw new ArgumentException();
            }

            try
            {
                SetUserRgCoolOffRequest setUserRgCoolOffRequest = new SetUserRgCoolOffRequest()
                {
                    UserID = CustomProfile.Current.UserID,
                    Period = coolOffPeriod,
                    CoolOffReason = coolOffReason,
                    CoolOffDescription = coolOffReasonDescription,
                    UnsatisfiedReason = unsatisfiedReason,
                    UnsatisfiedDescription = unsatisfiedDescription,
                    SendNotificationEmail = true,
                };                

                if (coolOffPeriod == SelfExclusionPeriod.CoolOffUntilSelectedDate)
                    setUserRgCoolOffRequest.ExpiryDate = dateUntill;

                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    setUserRgCoolOffRequest = client.SingleRequest<SetUserRgCoolOffRequest>(setUserRgCoolOffRequest);
                }
                CustomProfile.Current.Logoff();
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return this.View("Error");
            }

            return this.View("Success");
        }
    }
}
