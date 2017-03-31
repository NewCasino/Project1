using System;
using System.Collections.Generic;

namespace Casino
{
    /// <summary>
    /// Summary description for Jackpot
    /// </summary>
    [Serializable]
    public sealed class JackpotInfo
    {
        public string ID { get; set; }
        public string Currency { get; set; }
        public decimal Amount { get; set; }
        public List<GameID> Games { get; set; }

        public JackpotInfo()
        {
            this.Games = new List<GameID>();
        }
    }
}