using System;

namespace Finance
{
    [Serializable]
    /// <summary>
    /// Summary description for ProcessTime
    /// </summary>
    public enum ProcessTime
    {
        Immediately,
        FifteenMinutes,
        ThreeToFiveDays,
        Instant,
        Variable,
    }
}