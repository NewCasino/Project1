using GamMatrixAPI;

public static class GlobalConstant
{
    public static VendorID[] AllVendors = new VendorID[]
    {
        VendorID.NetEnt,
        VendorID.Microgaming,
        VendorID.CTXM,
        VendorID.IGT,
        VendorID.PlaynGO,
        VendorID.XProGaming,
        VendorID.BetSoft,
        VendorID.GreenTube,
        VendorID.Sheriff,
        VendorID.OMI,
        VendorID.EvolutionGaming,
        VendorID.NYXGaming,
        VendorID.BallyGaming,
        VendorID.Norske,
        VendorID.ISoftBet,
        VendorID.Ezugi,
        VendorID.BetGames,
        VendorID.Vivo,
        VendorID.OneXTwoGaming,
        VendorID.GTS,
        VendorID.Williams,
        VendorID.EGT,
        VendorID.Lega,
        VendorID.EGB,
        VendorID.Yggdrasil,
        VendorID.WorldMatch,
        VendorID.PokerKlas,
        VendorID.Spigo,
        VendorID.QuickSpin,
        VendorID.Realistic,
        VendorID.Parlay,
        VendorID.Hybrino,
        VendorID.Authentic,
        VendorID.BetOnFinance,
        VendorID.CandleBets,
        VendorID.Eyecon,
        VendorID.LuckyStreak,
        VendorID.Genii,
        VendorID.Globalbet,
        VendorID.Odobo,
        VendorID.JoinGames,
        VendorID.Multislot,
        VendorID.Kiron,
        VendorID.Tombala,
        VendorID.Playson,
        VendorID.Igrosoft,
        VendorID.Habanero,
        VendorID.Endorphina,
        VendorID.Spinomenal,
        VendorID.Mrslotty,
        VendorID.RCT,
        VendorID.Pariplay,
        VendorID.BoomingGames,
        VendorID.GaminGenius,
        VendorID.StakeLogic,
        VendorID.ViG,
        VendorID.Oriental,
        VendorID.HoGaming,
        VendorID.AsiaGaming,
        VendorID.TTG,
        VendorID.Opus,
        VendorID.ISoftGaming,
        VendorID.Magnet,
        VendorID.GoldenRace,
        VendorID.LiveGames,
        VendorID.Entwine,
        VendorID.Gamevy,
        VendorID.PlayStar,
    };

    public static VendorID[] AllLiveCasinoVendors = new VendorID[]
    {
        VendorID.NetEnt,
        VendorID.Microgaming,
        VendorID.XProGaming,
        VendorID.EvolutionGaming,
        VendorID.Ezugi,
        VendorID.BetGames,
        VendorID.Vivo,
        VendorID.PokerKlas,
        VendorID.LuckyStreak,
		VendorID.Tombala,
        VendorID.Authentic,
        VendorID.Oriental,
        VendorID.ViG,
        VendorID.HoGaming,
        VendorID.AsiaGaming,
        VendorID.TTG,
        VendorID.Opus,
        VendorID.LiveGames,
        VendorID.Entwine
    };

    /// <summary>
    /// Vendors that have both LiveCasino and usual Slots Games
    /// </summary>
    public static VendorID[] AllUniversalVendors = new VendorID[]
    {
        VendorID.NetEnt,
        VendorID.Microgaming,
        VendorID.Vivo,
        VendorID.TTG,
        VendorID.AsiaGaming
    };

    public static VendorID[] NonSeamlessVendors = new VendorID[]
    {
        VendorID.Opus, 
        VendorID.Oriental
    };

    /// <summary>
    /// Vendors that have both LiveCasino and usual Slots Games
    /// </summary>
    public static VendorID[] AllGenericApiVendors = new VendorID[]
    {
        VendorID.Realistic,
        VendorID.Parlay
    };

    public static class Continent
    {
        public const string Africa = "AF";
        public const string Antarctica = "AN";
        public const string Asia = "AS";
        public const string Australia = "OA";
        public const string Europe = "EU";
        public const string NorthAmerica = "NA";
        public const string SouthAmerica = "SA";
    }
}
