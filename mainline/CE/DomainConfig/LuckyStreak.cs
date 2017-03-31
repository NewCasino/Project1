namespace CE.DomainConfig
{
    public static class LuckyStreak
    {
        // LuckyStreakPlayRealGameUrl
        [Config(Comments = "Casino Game Real Money Mode URL", MaxLength = 512
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CasinoGameRealMoneyModeURL = "LuckyStreak.CasinoGameRealMoneyModeURL";

        // LuckyStreakGameListUrl
        [Config(Comments = "Casino Game List URL", MaxLength = 512
            , ProductionDefaultValue = "https://integ.livepbt.com/lobby/api/v3/Lobby/Games"
            , StagingDefaultValue = "https://integ.livepbt.com/lobby/api/v3/Lobby/Games")]
        public const string CasinoGameListURL = "LuckyStreak.CasinoGameListURL";


        // CELaunchUrlProtocol
        [Config(Comments = "CE Launch Url Protocol", MaxLength = 5
            , ProductionDefaultValue = "https"
            , StagingDefaultValue = "http")]
        public const string CELaunchUrlProtocol = "LuckyStreak.CELaunchUrlProtocol";

        //LuckyStreakTokenURL
        [Config(Comments = "CE Launch GetToken from vendor", MaxLength = 255
            , ProductionDefaultValue = "https://integ.api-ids.livepbt.com/ids/connect/token"
            , StagingDefaultValue = "https://integ.api-ids.livepbt.com/ids/connect/token")]
        public const string CELuckyStreakTokenURL = "LuckyStreak.CELuckyStreakTokenURL";

        //CEOperatorClientId
        [Config(Comments = "CE Operator Client Id", MaxLength = 255
            , ProductionDefaultValue = "int_op_em"
            , StagingDefaultValue = "int_op_em")]
        public const string CEOperatorClientId = "LuckyStreak.CEOperatorClientId";

        //CEOperatorClientSecret
        [Config(Comments = "CE Operator Client Secret", MaxLength = 255
            , ProductionDefaultValue = "emintsecr"
            , StagingDefaultValue = "emintsecr")]
        public const string CEOperatorClientSecret = "LuckyStreak.CEOperatorClientSecret";

        //CEOperatorName
        [Config(Comments = "CE Operator Name", MaxLength = 255
            , ProductionDefaultValue = "EM_INT"
            , StagingDefaultValue = "EM_INT")]
        public const string CEOperatorName = "LuckyStreak.CEOperatorName";

        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "LuckyStreak.CELaunchInjectScriptUrl";

        //CELaunchInjectScriptUrl
        [Config(Comments = "Show live lobby", MaxLength = 10
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CEShowLiveLobby = "LuckyStreak.ShowLiveLobby";
        
    }
}
