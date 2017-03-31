using System;
using System.Web.Mvc;
using BLToolkit.DataAccess;
using CM.db;
using CM.db.Accessor;
using CM.Sites;
using CM.State;
using CM.Web;
using GamMatrixAPI;
using GmCore;
using CM.Content;

namespace GamMatrix.CMS.Controllers.Shared
{
    [ControllerExtraInfo(DefaultAction = "Index")]
    public class ChangePwdController : ControllerEx
    {
        [HttpGet]
        [Protocol(Action = ProtocolAttribute.ProtocolAction.RequireHttps)]
        public ActionResult Index()
        {
            return View("Index");
        }

        public ActionResult SaveNewPassWord(string oldPassword, string newPassword, string successView,long userID)
        {
            try
            {
                UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                cmUser user = ua.GetByID(userID);

                UserPasswordHistoryAccessor upha = DataAccessor.CreateInstance<UserPasswordHistoryAccessor>();
                string newPasswordHash = PasswordHelper.CreateEncryptedPassword(user.PasswordEncMode/*SiteManager.Current.PasswordEncryptionMode*/, newPassword);
                if (Settings.Password_CheckPasswordHistory)
                {
                    if (newPasswordHash.Equals(user.Password))
                        return View("PasswordEverUsed");

                    if (upha.Exists(SiteManager.Current.DomainID, userID, newPasswordHash))
                        return View("PasswordEverUsed");
                }

                using (GamMatrixClient client = GamMatrixClient.Get())
                {
                    ChangeUserPasswordRequest changeUserPasswordRequest = client.SingleRequest<ChangeUserPasswordRequest>(
                        new ChangeUserPasswordRequest()
                        {
                            UserID = userID,
                            PlainTextPassword = newPassword,
                            CheckOldPassword = true,
                            OldPlainTextPassword = oldPassword,
                        });
                }

                if (!upha.Exists(SiteManager.Current.DomainID, CustomProfile.Current.UserID))
                {
                    string oldPwdHash = PasswordHelper.CreateEncryptedPassword(user.PasswordEncMode/*SiteManager.Current.PasswordEncryptionMode*/, oldPassword);
                    upha.Create(SiteManager.Current.DomainID, CustomProfile.Current.UserID, oldPwdHash, DateTime.Now);
                }
                upha.Create(SiteManager.Current.DomainID, CustomProfile.Current.UserID, newPasswordHash, DateTime.Now);

                return View(successView);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return View("Error");
            }
        }

        public ActionResult Save(string oldPassword, string newPassword)
        {
            if (!CustomProfile.Current.IsAuthenticated)
                throw new UnauthorizedAccessException();
            return SaveNewPassWord(oldPassword, newPassword, "Success", CustomProfile.Current.UserID);
        }

        public ActionResult SaveSafe(string username, string oldPassword, string newPassword)
        {
            try
            {
                cmUser user = null;
                CustomProfile.LoginResult result = CustomProfile.Current.AsCustomProfile().VerifyUserPassword(username, oldPassword, out user);
                long userID = user == null ? 0 : user.ID;
                if (result == CustomProfile.LoginResult.Success)
                {
                    return SaveNewPassWord(oldPassword, newPassword, getSuccessView(), userID);
                }
                else
                {
                    return ErrorInfo(result, userID);
                }
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                this.ViewData["ErrorMessage"] = GmException.TryGetFriendlyErrorMsg(ex);
                return View("Error");
            }
        }
        public virtual string getSuccessView()
        {
            return "/ChangeUnSafePassWord/Success";
        }
        public ActionResult ErrorInfo(CustomProfile.LoginResult result, long userID)
        {
            if (result == CustomProfile.LoginResult.EmailNotVerified)
            {
                if (Settings.NumberOfDaysForLoginWithoutEmailVerification > 0)
                    this.ViewData["Error"] = string.Format(Metadata.Get("/Metadata/ServerResponse.Login_EmailNotVerified"), Settings.NumberOfDaysForLoginWithoutEmailVerification);
                else
                    this.ViewData["Error"] = Metadata.Get("/Metadata/ServerResponse.Login_EmailNotVerified_DoNotAllowLogin");
            }
            else if (result == CustomProfile.LoginResult.Blocked)
            {
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
                            string blockMessage = string.Empty;
                            switch (getUserRgSelfExclusionRequest.Record.Period)
                            {
                                case SelfExclusionPeriod.CoolOffFor24Hours:
                                case SelfExclusionPeriod.CoolOffFor7Days:
                                case SelfExclusionPeriod.CoolOffFor30Days:
                                case SelfExclusionPeriod.CoolOffFor3Months:
                                case SelfExclusionPeriod.CoolOffUntilSelectedDate:
                                    blockMessage = Metadata.Get("/Metadata/ServerResponse.Login_Blocked_CoolOff");
                                    break;
                                case SelfExclusionPeriod.SelfExclusionFor7Days:
                                case SelfExclusionPeriod.SelfExclusionFor30Days:
                                case SelfExclusionPeriod.SelfExclusionFor6Months:
                                case SelfExclusionPeriod.SelfExclusionFor3Months:
                                case SelfExclusionPeriod.SelfExclusionFor1Year:
                                case SelfExclusionPeriod.SelfExclusionFor5Years:
                                case SelfExclusionPeriod.SelfExclusionFor7Years:
                                case SelfExclusionPeriod.SelfExclusionUntilSelectedDate:
                                    blockMessage = Metadata.Get("/Metadata/ServerResponse.Login_Blocked_SelfExclusion");
                                    break;
                                case SelfExclusionPeriod.SelfExclusionPermanent:
                                    blockMessage = Metadata.Get("/Metadata/ServerResponse.Login_Blocked_SelfExclusion_Permanent");
                                    break;
                            }

                            this.ViewData["Error"] = string.Format(blockMessage, getUserRgSelfExclusionRequest.Record.ExpiryDate);
                        }
                    }
                }
            }
            else
                this.ViewData["Error"] = Metadata.Get(string.Format("/Metadata/ServerResponse.Login_{0}", result));
            var script = string.Format("<script type=\"text/javascript\">alert('{0}');</script>", this.ViewData["Error"]);
            Response.Write(script);
            return View("/ChangeUnSafePassWord/InputView");
        }
    }
}
