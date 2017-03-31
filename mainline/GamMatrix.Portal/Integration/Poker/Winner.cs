using System;

namespace Poker
{
    /// <summary>
    /// Summary description for PokerWinner
    /// </summary>
    [Serializable]
    public sealed class Winner
    {
        public string Nickname { get; internal set; }
        public string Currency { get; internal set; }
        public int GamesWon { get; internal set; }
        public string GameType { get; internal set; }
        public string Limit { get; internal set; }
        public decimal StakeLow { get; internal set; }
        public decimal StakeHigh { get; internal set; }
        public DateTime? StartTime { get; internal set; }
        public DateTime? EndTime { get; internal set; }
    }
}