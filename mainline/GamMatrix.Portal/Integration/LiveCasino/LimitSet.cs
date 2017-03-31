namespace LiveCasino
{
    /// <summary>
    /// Summary description for LimitSet
    /// </summary>
    public sealed class LimitSet
    {
        public string ID { get; internal set; }
        public decimal? MinBet { get; internal set; }
        public decimal? MaxBet { get; internal set; }
        public decimal? MinPlayerBet { get; internal set; }
        public decimal? MaxPlayerBet { get; internal set; }
        public decimal? MinInsideBet { get; internal set; }
        public decimal? MaxInsideBet { get; internal set; }
        public decimal? MinOutsideBet { get; internal set; }
        public decimal? MaxOutsideBet { get; internal set; }

    }
}