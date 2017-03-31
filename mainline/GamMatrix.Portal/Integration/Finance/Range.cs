using System;

namespace Finance
{
    [Serializable]
    /// <summary>
    /// Summary description for Limitation
    /// </summary>
    public sealed class Range
    {
        public string Currency { get; set; }
        public decimal MinAmount { get; set; }
        public decimal MaxAmount { get; set; }
    }
}