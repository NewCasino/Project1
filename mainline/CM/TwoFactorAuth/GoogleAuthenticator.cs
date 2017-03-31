using System;

namespace TwoFactorAuth.Authenticators
{
    public class GoogleAuthenticator
    {
        public static SecondFactorAuthSetupCode GenerateSetupCode(string issuer, string username, string secretKey, int qrCodeWidth, int qrCodeHeigt)
        {
            Google.Authenticator.TwoFactorAuthenticator tfa = new Google.Authenticator.TwoFactorAuthenticator();
            Google.Authenticator.SetupCode setupInfo = tfa.GenerateSetupCode(issuer, username, secretKey, qrCodeWidth, qrCodeHeigt);

            SecondFactorAuthSetupCode setupCode = new SecondFactorAuthSetupCode()
            {
                QrCodeImageUrl = setupInfo.QrCodeSetupImageUrl,
                SetupCode = setupInfo.ManualEntryKey,
            };

            return setupCode;
        }

        public static bool ValidatePIN(string secretKey, string pin)
        {
            Google.Authenticator.TwoFactorAuthenticator tfa = new Google.Authenticator.TwoFactorAuthenticator();
            return tfa.ValidateTwoFactorPIN(secretKey, pin);
        }
    }
}
