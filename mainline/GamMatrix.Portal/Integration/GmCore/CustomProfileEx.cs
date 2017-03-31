using System;
using System.Linq;
using System.Web;
using System.Collections.Generic;
using System.Text;
using CM.db;
using CM.Sites;
using CM.State;
using EveryMatrix.SessionAgent.Protocol;
using GamMatrixAPI;

namespace GmCore
{
    /// <summary>
    /// Summary description for CustomProfileEx
    /// </summary>
    public class CustomProfileEx : CustomProfile
    {
        protected override void LogFailedLogin(cmUser user, NoteType type, string message)
        {
            AddNoteRequest request = new AddNoteRequest()
            {
                TypeID = user.ID,
                Importance = ImportanceType.Normal,
                Type = type,
                Note = message,
            };
            using (GamMatrixClient client = new GamMatrixClient())
            {
                client.SingleRequest<AddNoteRequest>(request);
            }
        }

        protected override string GetRoleStringByUser(cmSite site, long userID)
        {
            return GamMatrixClient.GetRoleString(userID, site);
        }

        protected override void UpdateRoleStringAsync(string guid, string roleString)
        {
            //LongRunWorker.UpdateRoleString(guid, roleString);
        }

        protected override void OnLoginCompleted(cmUser user, string sessionID, string ip)
        {
            //LongRunWorker.LoginSucceed(user.ID, sessionID, ip);
        }

        protected override void OnLogoffCompleted(long userID, string sessionID, SessionExitReason exitReason)
        {
            if( exitReason != SessionExitReason.LoggedOff )
                Logger.Warning("Session", string.Format("User session is discarded, reason={0}", exitReason.ToString()));
            HttpCookie cookie = new HttpCookie("_ser", exitReason.ToString());
            cookie.Domain = SiteManager.Current.SessionCookieDomain;
            cookie.HttpOnly = false;
            cookie.Secure = false;
            cookie.Expires = DateTime.Now.AddMinutes(30);
            HttpContext.Current.Response.Cookies.Add(cookie);
        }

        protected override void UpdateLastAccessTime(string sessionID)
        {
            //LongRunWorker.UpdateLastAccessTime(this.SessionID);
        }

        protected override void SendSecondFactorBackupCodeEmail(cmUser user, List<string> backupCodes)
        {
            try
            {
                // send the email
                Email mail = new Email();
                mail.LoadFromMetadata("SecondFactorNewGenerationBackupCode", user.Language);
                mail.ReplaceDirectory["USERNAME"] = user.Username;
                mail.ReplaceDirectory["FIRSTNAME"] = user.FirstName;

                StringBuilder sb = new StringBuilder();
                if (backupCodes != null && backupCodes.Count > 0)
                {
                    for (int i = 0; i < backupCodes.Count; i++)
                    {
                        mail.ReplaceDirectory["BACKUPCODE" + (i + 1)] = backupCodes[i];

                        sb.AppendFormat("<li>{0}</li>", backupCodes[i]);
                    }
                }
                mail.ReplaceDirectory["BACKUPCODELIST"] = sb.ToString();

                mail.Send(user.Email);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }
        }

        protected override bool ExportUser(long userID, string currency)
        {
            try
            {
                GamMatrixClient.RegisterUserAsync(userID, currency);
                return true;
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return false;
            }
        }


        protected override void SendNotificationEmail(cmUser user)
        {
            try
            {
                // send the email
                Email mail = new Email();
                mail.LoadFromMetadata("TooManyFailedLoginAttempts", user.Language);
                mail.ReplaceDirectory["USERNAME"] = user.Username;
                mail.ReplaceDirectory["FIRSTNAME"] = user.FirstName;
                mail.Send(user.Email);
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }
        }

        protected override bool IsCountryBlocked(int countryID)
        {
            try
            {
                if (countryID > 0)
                {
                    CountryInfo countryInfo = CountryManager.GetAllCountries().FirstOrDefault(c => c.InternalID == countryID);
                    string currentIp = HttpContext.Current.Request.GetRealUserAddress(); 
                    if (countryInfo != null && !Settings.WhiteList_EMUserIPs.Contains(currentIp, StringComparer.InvariantCultureIgnoreCase))
                        return countryInfo.RestrictLoginByIP;
                }
                return false;
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
                return false;
            }
        }

    }
}