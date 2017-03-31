using System;

namespace Finance
{
    [Serializable]
    public enum BankWithdrawalType
    {
        None,
        Envoy,
        ClassicInternationalBank,
        ClassicEECBank,
        InPay,
        EnterCash,
    }

    [Serializable]
    /// <summary>
    /// Summary description for BankWithdrawalConfiguration
    /// </summary>
    public sealed class BankWithdrawalCountryConfig
    {
        public long InternalID { get; set; }
        public BankWithdrawalType Type { get; set; }
    }
}