using System;
using System.Collections.Generic;

namespace TwoFactorAuth
{
    public class SecondFactorAuthSetupCode
    {
        public SecondFactorAuthType AuthType { get; set; }

        public string QrCodeImageUrl { get; set; }
        public string SetupCode { get; set; }

        public List<string> BackupCodes { get; set; }
    }
}
