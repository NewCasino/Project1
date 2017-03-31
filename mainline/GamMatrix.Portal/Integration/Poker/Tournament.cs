using System;

namespace Poker
{
    public enum TournamentType
    {
        Current,
        UpcommingFreerolls,
        UpcommingGuaranteeds,

        RegistrationOpening,
        Completed,             
    }

    public enum TournamentFrequency
    {
        DAILY,
        WEEKLY,
        MONTHLY,
        INFOS,
    }

    public enum TournamentStatus
    {
        ANNOUNCED = 1,
        REGISTERING = 2,
        SEATING = 3,
        RUNNING = 4,
        ONBREAK = 5,
        COMPLETED = 6,
        CANCELLED = 7,
        ONHOLD = 8,
        NOTYETANNOUNCED = 9,
        CANCELLING = 10,
        SEATED = 11,
        COMPLETING =12,
        STARTINGBREAK = 13,
        STARTINGADDON = 14,
        ADDONPERIOD = 15,
        LATEREGISTRATION =22,
    }

    /// <summary>
    /// Summary description for TournamentBase
    /// </summary>
    [Serializable]
    public class Tournament
    {
        public TournamentType Type { get; internal set; }        
        public string Name { get; internal set; }
        public string Currency { get; internal set; }
        public decimal BuyIn { get; internal set; }
        public decimal EntryFee { get; internal set; }
        public decimal PrizePool { get; internal set; }
        public int Entrants { get; internal set; }
        public DateTime? RegistrationTime { get; internal set; }
        public DateTime? StartTime { get; internal set; }

        public int MaxTables { get; set; }

        public string LimitType { get; set; }
        public decimal MaxRebuy { get; set; }
        public string GameType { get; set; }

        public long ID { get; internal set; }
        public TournamentFrequency Frequency{ get; internal set; }
        public TournamentStatus Status { get; internal set; }
    }

}