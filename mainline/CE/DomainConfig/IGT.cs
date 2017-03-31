namespace CE.DomainConfig
{
    public static class IGT
    {
        // IGTSkinCode
        [Config(Comments = "Casino Game Skin Code", MaxLength = 50
            , ProductionDefaultValue = "EM01"
            , StagingDefaultValue = "EM01")]
        public const string CasinoGameSkinCode = "IGT.CasinoGameSkinCode";

        // IGTNsCode
        [Config(Comments = "Casino Game NS Code", MaxLength = 50
            , ProductionDefaultValue = "EVMX"
            , StagingDefaultValue = "EVMX")]
        public const string CasinoGameNSCode = "IGT.CasinoGameNSCode";

        // IGTPlayGameBaseUrl
        [Config(Comments = "Casino Game Base URL", MaxLength = 255
            , ProductionDefaultValue = "https://platform.rgsgames.com"
            , StagingDefaultValue = "https://rgs-cust03.lab.wagerworks.com")]
        public const string CasinoGameBaseURL = "IGT.CasinoGameBaseURL";

        // IGTPlayMobileGameBaseUrl
        [Config(Comments = "Mobile Game Base URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "https://ipl-dmzcust03.lab.wagerworks.com/games/index.html")]
        public const string MobileGameBaseURL = "IGT.MobileGameBaseURL";


        //CELaunchUrlProtocol
        [Config(Comments = "CE Launch Url Protocol", MaxLength = 5
            , ProductionDefaultValue = "https"
            , StagingDefaultValue = "http")]
        public const string CELaunchUrlProtocol = "IGT.CELaunchUrlProtocol";



        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "IGT.CELaunchInjectScriptUrl";

        [Config(Comments = "Jackpot Base URL", MaxLength = 255
            , ProductionDefaultValue = "https://platform.rgsgames.com/JackpotMeter?JackpotID={0}&CurrencyCd=EUR"
            , StagingDefaultValue = "https://platform.rgsgames.com/JackpotMeter?JackpotID={0}&CurrencyCd=EUR")]
        public const string JackpotBaseURL = "IGT.JackpotBaseURL";

        [Config(Comments = "GameListV2 URL", MaxLength = 255
            , ProductionDefaultValue = "https://rgs-cust02.lab.wagerworks.com/ws-v2/rest/game/gameList/v2"
            , StagingDefaultValue = "https://rgs-cust02.lab.wagerworks.com/ws-v2/rest/game/gameList/v2")]
        public const string GameListV2URL = "IGT.GameListV2URL";

        [Config(Comments = "UserName", MaxLength = 255
            , ProductionDefaultValue = "ws-client"
            , StagingDefaultValue = "ws-client")]
        public const string UserName = "IGT.UserName";

        [Config(Comments = "Password", MaxLength = 255
            , ProductionDefaultValue = "password"
            , StagingDefaultValue = "password")]
        public const string Password = "IGT.Password";
    }
}
