namespace CE.DomainConfig
{
    public class NetEnt : IConfigBase
    {
        // NetEntSkinName
        [Config( Comments = "Casino Game Skin Name", MaxLength = 25 )]
        public const string CasinoBrand = "NetEnt.CasinoBrand";

        // NetEntLoadGameBaseUrl
        [Config(Comments = "Casino Game Host Base URL", MaxLength = 255
            , ProductionDefaultValue = "https://oddsmatrix-static.casinomodule.com"
            , StagingDefaultValue = "https://oddsmatrix-static-test.casinomodule.com")]
        public const string CasinoGameHostBaseURL = "NetEnt.CasinoGameHostBaseURL";

        // NetEntPlayGameBaseUrl
        [Config(Comments = "Casino Game API Base URL", MaxLength = 255
            , ProductionDefaultValue = "https://oddsmatrix-game.casinomodule.com"
            , StagingDefaultValue = "http://oddsmatrix-game-test.casinomodule.com")]
        public const string CasinoGameApiBaseURL = "NetEnt.CasinoGameApiBaseURL";

        // NetEntHelpBaseUrl
        [Config(Comments = "Game Rules Base URL", MaxLength = 255
            , ProductionDefaultValue = "https://oddsmatrix-game.casinomodule.com"
            , StagingDefaultValue = "https://oddsmatrix-game.casinomodule.com")]
        public const string GameRulesBaseURL = "NetEnt.GameRulesBaseURL";

        // NetEntMobileGameUrl
        [Config(Comments = "Mobile Game URL", MaxLength = 512
            , ProductionDefaultValue = "https://oddsmatrix-static.casinomodule.com/games/{0}/game/{0}.xhtml?gameId={1}&lang={2}&historyURL=/{2}/&sessId={3}&lobbyURL={4}&operatorId=oddsmatrix&server=https%3A%2F%2Foddsmatrix-game.casinomodule.com%2F&depositAvailable=true&disableAudio=false"
            , StagingDefaultValue = "https://oddsmatrix-static-test.casinomodule.com/games/{0}/game/{0}.xhtml?gameId={1}&lang={2}&historyURL=/{2}/&sessId={3}&lobbyURL={4}&operatorId=oddsmatrix&server=https%3A%2F%2Foddsmatrix-game-test.casinomodule.com%2F&depositAvailable=true&disableAudio=false")]
        public const string MobileGameURL = "NetEnt.MobileGameURL";

        [Config(Comments = "Live Casino Game Brand", MaxLength = 25)]
        public const string LiveCasinoBrand = "NetEnt.LiveCasinoBrand";

        [Config(Comments = "Live Casino ID", MaxLength = 25)]
        public const string LiveCasinoID = "NetEnt.LiveCasinoID";

        [Config(Comments = "Live Casino Game Host Base URL", MaxLength = 255
            , ProductionDefaultValue = "https://oddsmatrix-static.casinomodule.com"
            , StagingDefaultValue = "https://oddsmatrix-static-test.casinomodule.com")]
        public const string LiveCasinoGameHostBaseURL = "NetEnt.LiveCasinoGameHostBaseURL";

        [Config(Comments = "Live Casino Game API Base URL", MaxLength = 255
            , ProductionDefaultValue = "https://oddsmatrix-livegame.casinomodule.com"
            , StagingDefaultValue = "https://oddsmatrix-livegame-test.casinomodule.com")]
        public const string LiveCasinoGameApiBaseURL = "NetEnt.LiveCasinoGameApiBaseURL";

        [Config(Comments = "Live Casino Query Open Tables API URL", MaxLength = 512
            , ProductionDefaultValue = "https://oddsmatrix-liveapi.casinomodule.com/lobbycomm/services/LobbyApi/tables/allOpen/oddsmatrix/{0}/SEAMLESS_WALLET"
            , StagingDefaultValue = "https://oddsmatrix-liveapi-test.casinomodule.com/lobbycomm/services/LobbyApi/tables/allOpen/oddsmatrix/{0}/SEAMLESS_WALLET")]
        public const string LiveCasinoQueryOpenTablesApiURL = "NetEnt.LiveCasinoQueryOpenTablesApiURL";


        //CELaunchUrlProtocol
        [Config(Comments = "CE Launch Url Protocol", MaxLength = 5
            , ProductionDefaultValue = "https"
            , StagingDefaultValue = "http")]
        public const string CELaunchUrlProtocol = "NetEnt.CELaunchUrlProtocol";

        //CELaunchUrlProtocol
        [Config(Comments = "Live Casino - Show Mini Lobby ( true or false )", MaxLength = 5
            , ProductionDefaultValue = "false"
            , StagingDefaultValue = "false")]
        public const string LiveCasinoShowMiniLobby = "NetEnt.LiveCasinoShowMiniLobby";

        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "NetEnt.CELaunchInjectScriptUrl";
    }
}
