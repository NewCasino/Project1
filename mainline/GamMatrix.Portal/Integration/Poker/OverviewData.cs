using System;

namespace Poker
{
    /// <summary>
    /// Summary description for OverviewData
    /// </summary>
    [Serializable]
    public sealed class OverviewData
    {
        public int OnlinePlayerNumber { get; set; }
        public int TableNumber { get; set; }
        public int TournamentsNumber { get; set; }
    }

}