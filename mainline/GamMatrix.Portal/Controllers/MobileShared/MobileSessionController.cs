using System;
using System.Web.Mvc;
using CM.Content;
using CM.State;
using CM.Web;
using GamMatrix.CMS.Controllers.Shared;
using GmCore;
using OAuth;
using GamMatrixAPI;
using TwoFactorAuth;

namespace GamMatrix.CMS.Controllers.MobileShared
{
	/// <summary>
	/// Summary description for MobileSessionController
	/// </summary>
	/// 
	[HandleError]
	[MasterPageViewData(Name = "CurrentSectionMarkup", Value = "LoginSection")]
	[ControllerExtraInfo(DefaultAction = "Index")]
	public class MobileSessionController : SessionController
	{

		[HttpGet]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
		public new ActionResult Index()
		{
			return View("Index");
		}

        [HttpPost]
        [CustomValidateAntiForgeryToken]
        public override ActionResult SignIn(string username, string password, string captcha, string callback, string unused, string referrerID, string iovationBlackBox = null, string authToken = null, bool? trustedDevice = null, string authType = null)
        {
			bool status = false;
			string message = string.Empty;
            string customMessage = string.Empty;
            CustomProfile.LoginResult result = CustomProfile.LoginResult.NoMatch;

            long userID = 0;
            SecondFactorAuthSetupCode secondFactorAuthSetupCode = null;

            try
            {
                if (Settings.IovationDeviceTrack_Enabled && string.IsNullOrEmpty(iovationBlackBox))
                {
                    //throw new ArgumentNullException(GamMatrixClient.GetIovationError(eventType: IovationEventType.Login));
                }
                string phoneNumber = string.Empty;
                result = InternalSignIn(username, password, null, captcha, iovationBlackBox, authToken, trustedDevice, authType, out userID, out secondFactorAuthSetupCode, out phoneNumber);

                if (result == CustomProfile.LoginResult.Success && !string.IsNullOrWhiteSpace(referrerID))
                {
                    ExternalAuthManager.SaveAssociatedExternalAccount(CustomProfile.Current.UserID, referrerID);
                }                
                else if (result == CustomProfile.LoginResult.NeedChangePassword)
                {
                    string htmlNeedChangePassword = string.Format(@"<!DOCTYPE html>
                                    <html>
                                    <head>
                                    <meta http-equiv=""location"" content=""URL={0}"" />
                                    <meta http-equiv=""Content-Type"" content=""text/html; charset=utf-8"" />
                                    <title></title>
                                    <meta http-equiv=""Refresh"" content=""2;URL={0}"" />
                                    </head>
                                    <body>
                                    <script type=""text/javascript"">
                                    parent.parent.location = '{0}';
                                    </script>
                                    </body>
                                    </html>
                                    ", "/ChangeUnSafePassWord/Index?UN=" + username);
                    return this.Content(htmlNeedChangePassword, "text/html");
                }
                else if (result == CustomProfile.LoginResult.Blocked)
                {
                    #region
                    if (userID > 0)
                    {
                        using (GamMatrixClient client = GamMatrixClient.Get())
                        {
                            GetUserRgSelfExclusionRequest getUserRgSelfExclusionRequest = client.SingleRequest<GetUserRgSelfExclusionRequest>(new GetUserRgSelfExclusionRequest()
                            {
                                UserID = userID,

                            });
                            if (getUserRgSelfExclusionRequest.Record != null)
                            {
                                switch (getUserRgSelfExclusionRequest.Record.Period)
                                {
                                    case SelfExclusionPeriod.CoolOffFor24Hours:
                                    case SelfExclusionPeriod.CoolOffFor7Days:
                                    case SelfExclusionPeriod.CoolOffFor30Days:
                                    case SelfExclusionPeriod.CoolOffFor3Months:
                                    case SelfExclusionPeriod.CoolOffUntilSelectedDate:
                                        customMessage = Metadata.Get("/Metadata/ServerResponse.Login_Blocked_CoolOff");
                                        break;
                                    case SelfExclusionPeriod.SelfExclusionFor7Days:
                                    case SelfExclusionPeriod.SelfExclusionFor30Days:
                                    case SelfExclusionPeriod.SelfExclusionFor6Months:
                                    case SelfExclusionPeriod.SelfExclusionFor3Months:
                                    case SelfExclusionPeriod.SelfExclusionFor1Year:
                                    case SelfExclusionPeriod.SelfExclusionFor5Years:
                                    case SelfExclusionPeriod.SelfExclusionFor7Years:
                                    case SelfExclusionPeriod.SelfExclusionUntilSelectedDate:
                                        customMessage = Metadata.Get("/Metadata/ServerResponse.Login_Blocked_SelfExclusion");
                                        break;
                                    case SelfExclusionPeriod.SelfExclusionPermanent:
                                        customMessage = Metadata.Get("/Metadata/ServerResponse.Login_Blocked_SelfExclusion_Permanent");
                                        break;
                                }
                                if (!string.IsNullOrWhiteSpace(customMessage))
                                    customMessage = string.Format(customMessage, getUserRgSelfExclusionRequest.Record.ExpiryDate.ToString("dd-MM-yyyy HH:mm:ss"));
                            }
                        }
                    }
                    #endregion
                }
                else if(result == CustomProfile.LoginResult.EmailNotVerified)
                {
                    if (Settings.NumberOfDaysForLoginWithoutEmailVerification > 0)
                        customMessage = string.Format(Metadata.Get("/Metadata/ServerResponse.Login_EmailNotVerified"), Settings.NumberOfDaysForLoginWithoutEmailVerification);
                    else
                        customMessage = Metadata.Get("/Metadata/ServerResponse.Login_EmailNotVerified_DoNotAllowLogin");
                }
                else if (result == CustomProfile.LoginResult.NotMatchDevice)
                {
                    this.ViewData["PhoneNumber"] = phoneNumber;
                }
                //end of result == CustomProfile.LoginResult.Blocked

                status = result == CustomProfile.LoginResult.Success;
                message = string.IsNullOrWhiteSpace(customMessage) ? Metadata.Get(string.Format("/Metadata/ServerResponse.Login_{0}", result)) : customMessage;
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);

				message = GmException.TryGetFriendlyErrorMsg(ex);
            }

			this.ViewData["Callback"] = callback;
			this.ViewData["Status"] = status;
			this.ViewData["Message"] = message;
            this.ViewData["Result"] = result.ToString();
            this.ViewData["SecondFactorAuthSetupCode"] = secondFactorAuthSetupCode;

            return View("Response", this.ViewData);
        }
	}
}