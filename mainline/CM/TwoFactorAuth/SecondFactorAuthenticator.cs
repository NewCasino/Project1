using System;
using System.Collections.Generic;
using System.Web;
using BLToolkit.Data;
using BLToolkit.DataAccess;

namespace TwoFactorAuth
{
    using CM.db;
    using CM.db.Accessor;

    using TwoFactorAuth.Authenticators;

    public class SecondFactorAuthenticator
    {
        private static readonly string _TRUSTED_DEVICE_COOKIE_NAME = "_sf_td";
        public static SecondFactorAuthSetupCode GenerateSetupCode(cmSite site, cmUser user, SecondFactorAuthType authType, int qrCodeWidth = 250, int qrCodeHeigt = 250)
        {
            SecondFactorAuthSetupCode setupCode = null;
            if (authType == SecondFactorAuthType.GoogleAuthenticator)
            {
                if (string.IsNullOrWhiteSpace(user.SecondFactorSecretKey))
                {
                    user.SecondFactorSecretKey = GenerateSecretKey(user.ID);
                }

                setupCode = GoogleAuthenticator.GenerateSetupCode(site.DisplayName, user.Username, GetSecretKey(user.SecondFactorSecretKey), qrCodeWidth, qrCodeHeigt);
                setupCode.AuthType = SecondFactorAuthType.GoogleAuthenticator;
            }
            else if (authType == SecondFactorAuthType.GeneralAuthCode)
            {
                setupCode = new SecondFactorAuthSetupCode();
                setupCode.BackupCodes = GenerateBackupCodes(user.ID);
                setupCode.AuthType = SecondFactorAuthType.GeneralAuthCode;
            }
            return setupCode;
        }

        public static bool ValidateAuthCode(cmUser user, string authCode)
        {
            bool result = false;

            result = GoogleAuthenticator.ValidatePIN(GetSecretKey(user.SecondFactorSecretKey), authCode);

            if (result && !user.IsSecondFactorVerified)
            {
                SetSecondFactorVerified(user.ID, true);
            }
            return result;
        }

        public static bool IsTrustedDevice()
        {
            if (HttpContext.Current != null)
                return IsTrustedDevice(HttpContext.Current);

            return false;
        }

        public static bool IsTrustedDevice(HttpContext httpContext)
        {
            HttpCookie cookie = HttpContext.Current.Request.Cookies[_TRUSTED_DEVICE_COOKIE_NAME];
            if (cookie != null && !string.IsNullOrEmpty(cookie.Value))
                return true;

            return false;
        }

        public static void SetTrustedDevice()
        {
            if (HttpContext.Current != null)
                SetTrustedDevice(HttpContext.Current, CM.Sites.SiteManager.Current);
        }
        public static void SetTrustedDevice(HttpContext httpContext, cmSite site)
        {
            HttpCookie cookie = new HttpCookie(_TRUSTED_DEVICE_COOKIE_NAME, "1");

            if (!string.IsNullOrWhiteSpace(site.SessionCookieDomain))
                cookie.Domain = site.SessionCookieDomain.Trim();

            cookie.HttpOnly = true;
            cookie.Secure = false;
            HttpContext.Current.Response.Cookies.Remove(_TRUSTED_DEVICE_COOKIE_NAME);
            HttpContext.Current.Response.Cookies.Add(cookie);
        }

        public static void RemoveTrustedDevice()
        {
            if (HttpContext.Current != null)
                RemoveTrustedDevice(HttpContext.Current);
        }
        public static void RemoveTrustedDevice(HttpContext httpContext)
        {
            HttpCookie cookie = HttpContext.Current.Request.Cookies[_TRUSTED_DEVICE_COOKIE_NAME];
            if (cookie != null)
                cookie.Expires = DateTime.Now.AddMonths(-1);
        }

        public static List<string> GenerateBackupCodes(long userID)
        {
            List<string> codes = new List<string>();

            using (DbManager dbManager = new DbManager())
            {
                codes = GenerateBackupCodes(userID, dbManager);

                UserAccessor ua = DataAccessor.CreateInstance<UserAccessor>(dbManager);
                ua.SetSecondFactorType(userID, (int)SecondFactorAuthType.GeneralAuthCode);
            }            

            return codes;
        }

        private static List<string> GenerateBackupCodes(long userID, DbManager dbManager)
        {
            List<string> codes = new List<string>();

            SecondFactorBackupCodeAccessor accessor = DataAccessor.CreateInstance<SecondFactorBackupCodeAccessor>(dbManager);
            accessor.RemoveCodes(userID);
            string code;
            for (int i = 0; i < 10; i++)
            {
                code = StringHelper.GetRandomString(16);
                codes.Add(code);
                accessor.InsertCode(userID, code);
            }

            return codes;
        }

        public static bool VerifyBackupCode(cmUser user, string code, out List<string> newCodes)
        {
            newCodes = null;
            bool existed = false;
            using (DbManager dbManager = new DbManager())
            {
                SecondFactorBackupCodeAccessor accessor = DataAccessor.CreateInstance<SecondFactorBackupCodeAccessor>(dbManager);

                existed = accessor.IsCodeExist(user.ID, code);
                if (existed)
                {
                    int count = accessor.RemoveCode(user.ID, code);
                    if (count == 0)
                    {
                        newCodes = GenerateBackupCodes(user.ID, dbManager);
                    }
                }                
            }

            if (existed && !user.IsSecondFactorVerified)
            {
                SetSecondFactorVerified(user.ID, true);
            }

            return existed;
        }

        public static void SetSecondFactorVerified(long userID, bool verified)
        {
            using (DbManager dbManager = new DbManager())
            {
                UserAccessor ua = DataAccessor.CreateInstance<UserAccessor>(dbManager);
                ua.SetSecondFactorVerified(userID, verified);
            }
        }

        public static void ResetSecondFactorAuth(long userID)
        {
            using (DbManager dbManager = new DbManager())
            {
                UserAccessor ua = DataAccessor.CreateInstance<UserAccessor>(dbManager);
                ua.ResetSecondFactorAuth(userID);
            }
        }

        private static string GenerateSecretKey(long userID)
        {
            string secretKey = Guid.NewGuid().ToString().Replace("-", string.Empty);
            using (DbManager dbManager = new DbManager())
            {
                UserAccessor ua = DataAccessor.CreateInstance<UserAccessor>(dbManager);
                ua.SetSecondFactorSecretKey(userID, secretKey, (int)SecondFactorAuthType.GoogleAuthenticator);
            }
            return secretKey;
        }

        private static string GetSecretKey(string baseKey)
        {
            baseKey = PasswordHelper.CreateEncryptedPassword(PasswordEncryptionMode.MD5, baseKey).Substring(0,12);
            return baseKey;
        }

        public static void SetSecondFactorType(long userID, int secondFactorType)
        {
            using (DbManager dbManager = new DbManager())
            {
                UserAccessor ua = DataAccessor.CreateInstance<UserAccessor>(dbManager);
                ua.SetSecondFactorType(userID, secondFactorType);
            }
        }
    }
}
