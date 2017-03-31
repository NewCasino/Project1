namespace CE.DomainConfig
{
    public class Vivo
    {
        [Config(Comments = "Operator ID", MaxLength = 512
            , ProductionDefaultValue = "1743"
            , StagingDefaultValue = "1743")]
        public const string OperatorID = "Vivo.OperatorID";

        [Config(Comments = "Server ID", MaxLength = 512
            , ProductionDefaultValue = "3649143"
            , StagingDefaultValue = "3649143")]
        public const string ServerID = "Vivo.ServerID";

        // VivoPlayGameBaseUrl    https://www.vazagaming.com/vivo/games/roulette_game_contained_v2.php?token=3ffad54d3da94da88097a582b75a18ee~24&operatorID=1743&language=EN&tableID=1&LimitID=2744196&serverID=3649143&logoSetup=VIVO_LOGO&isKochip=false&isPlaceBetCTA=false
        [Config(Comments = "Live Casino Base Url", MaxLength = 512
            , ProductionDefaultValue = "https://www.vazagaming.com/vivo/games/{0}.php"
            , StagingDefaultValue = "https://www.vazagaming.com/vivo/games/{0}.php")]
        public const string LiveCasinoBaseUrl = "Vivo.LiveCasinoBaseUrl";

        // VivoSpinomenallPlayGameBaseUrl    http://www.1vivo.com/flashRunGame/RunSPNRngGame.aspx?token=0fde82a2-6eaf-4994-b6e2-2f60d8c1c83caeecc0dd-d0d%7e6&operatorID=1743&GameID=SlotMachine_AtlanticTreasures
        [Config(Comments = "Spinomenal Casino Base Url", MaxLength = 512
            , ProductionDefaultValue = "http://www.1vivo.com/flashRunGame/RunSPNRngGame.aspx?token={0}&operatorID={2}&GameID={1}"
            , StagingDefaultValue = "http://www.1vivo.com/flashRunGame/RunSPNRngGame.aspx?token={0}&operatorID={2}&GameID={1}")]
        public const string SpinomenalCasinoBaseUrl = "Vivo.SpinomenalCasinoBaseUrl";

        // VivoBBTECHPlayGameBaseUrl    https://1vivo.com/flashrungame/RunBTechGame.aspx?Token=123456789&OperatorID=1743&room=150607&gameconfig=wakatsuki&lobby=http://www.vivogaming.com&config=vivo_en
        [Config(Comments = "BBTECH Casino Base Url", MaxLength = 512
            , ProductionDefaultValue = "https://1vivo.com/flashrungame/RunBTechGame.aspx?Token={0}&OperatorID={2}&room=150607&gameconfig={1}&lobby=http://www.vivogaming.com&config=vivo_en"
            , StagingDefaultValue = "https://1vivo.com/flashrungame/RunBTechGame.aspx?Token={0}&OperatorID={2}&room=150607&gameconfig={1}&lobby=http://www.vivogaming.com&config=vivo_en")]
        public const string BBTECHCasinoBaseUrl = "Vivo.BBTECHCasinoBaseUrl";

        // VivoBetsoftPlayGameBaseUrl    http://1vivo.com/FlashRunGame/RunRngGame.aspx?Token=5317133966162379548560657329446018879&GameID=222&OperatorId=1743&lang=EN&cashierUrl=http://www.vivogaming.com&homeUrl=http://www.vivogaming.com
        [Config(Comments = "Betsoft Casino Base Url", MaxLength = 512
            , ProductionDefaultValue = "http://1vivo.com/FlashRunGame/RunRngGame.aspx?Token={0}&GameID={1}&OperatorId={2}&lang=EN&cashierUrl=http://www.vivogaming.com&homeUrl=http://www.vivogaming.com"
            , StagingDefaultValue = "http://1vivo.com/FlashRunGame/RunRngGame.aspx?Token={0}&GameID={1}&OperatorId={2}&lang=EN&cashierUrl=http://www.vivogaming.com&homeUrl=http://www.vivogaming.com")]
        public const string BetsoftCasinoBaseUrl = "Vivo.BetsoftCasinoBaseUrl";

        // VivoSpinomenallPlayGameFunUrl    http://www.1vivo.com/flashRunGame/RunSPNRngGame.aspx?token=0fde82a2-6eaf-4994-b6e2-2f60d8c1c83caeecc0dd-d0d%7e6&operatorID=1743&GameID=SlotMachine_AtlanticTreasures
        [Config(Comments = "Spinomenal Casino Fun Url", MaxLength = 512
            , ProductionDefaultValue = "http://www.1vivo.com/flashRunGame/RunSPNRngGame.aspx?operatorID={2}&partnerid=1453&GameID={1}&funMode=true"
            , StagingDefaultValue = "http://www.1vivo.com/flashRunGame/RunSPNRngGame.aspx?operatorID={2}&partnerid=1453&GameID={1}&funMode=true")]
        public const string SpinomenalCasinoFunUrl = "Vivo.SpinomenalCasinoFunUrl";

        // VivoBBTECHPlayGameFunUrl    http://gspotslots.bbtech.asia/onlinecasino/GetGames/GetGameDemo?config=vivo_en&gameconfig=wakatsuki&lobby=http://www.happyluke.com
        [Config(Comments = "BBTECH Casino Fun Url", MaxLength = 512
            , ProductionDefaultValue = "http://gspotslots.bbtech.asia/onlinecasino/GetGames/GetGameDemo?config=vivo_en&gameconfig=wakatsuki&lobby=http://www.happyluke.com"
            , StagingDefaultValue = "http://gspotslots.bbtech.asia/onlinecasino/GetGames/GetGameDemo?config=vivo_en&gameconfig=wakatsuki&lobby=http://www.happyluke.com")]
        public const string BBTECHCasinoFunUrl = "Vivo.BBTECHCasinoFunUrl";

        // VivoBetsoftPlayGameFunUrl    http://1vivo.com/FlashRunGame/RunRngGame.aspx?Token=5317133966162379548560657329446018879&GameID=222&OperatorId=1743&lang=EN&cashierUrl=http://www.vivogaming.com&homeUrl=http://www.vivogaming.com
        [Config(Comments = "Betsoft Casino Fun Url", MaxLength = 512
            , ProductionDefaultValue = "https://lobby-streamtech.betsoftgaming.com/cwguestlogin.do?&GameID={1}&lang=zh-cn&bankId=YS"
            , StagingDefaultValue = "https://lobby-streamtech.betsoftgaming.com/cwguestlogin.do?&GameID={1}&lang=zh-cn&bankId=YS")]
        public const string BetsoftCasinoFunUrl = "Vivo.BetsoftCasinoFunUrl";

        // VivoLobbyBaseUrl    https://www.vazagaming.com/vivo/games/roulette_game_contained_v2.php?token=3ffad54d3da94da88097a582b75a18ee~24&operatorID=1743&language=EN&tableID=1&LimitID=2744196&serverID=3649143&logoSetup=VIVO_LOGO&isKochip=false&isPlaceBetCTA=false
        [Config(Comments = "Live Casino Lobby Base Url", MaxLength = 512
            , ProductionDefaultValue = "http://www.vazagaming.com/lobby/game_lobby_live.php"
            , StagingDefaultValue = "http://www.vazagaming.com/lobby/game_lobby_live.php")]
        public const string LiveCasinoLobbyBaseUrl = "Vivo.LiveCasinoLobbyBaseUrl";

        //CELaunchUrlProtocol
        [Config(Comments = "CE Launch Url Protocol", MaxLength = 5
            , ProductionDefaultValue = "https"
            , StagingDefaultValue = "http")]
        public const string CELaunchUrlProtocol = "Vivo.CELaunchUrlProtocol";

        //Vivo web service url
        [Config(Comments = "Vivo web service url", MaxLength = 255
            , ProductionDefaultValue = "http://www.1vivo.com/flash/"
            , StagingDefaultValue = "http://www.1vivo.com/flash/")]
        public const string VivoWebServiceUrl = "Vivo.VivoWebServiceUrl";


        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "Vivo.CELaunchInjectScriptUrl";

        //CELaunchUrlProtocol
        [Config(Comments = "Live Casino - Show Mini Lobby ( true or false )", MaxLength = 5
            , ProductionDefaultValue = "false"
            , StagingDefaultValue = "false")]
        public const string LiveCasinoShowLobby = "Vivo.LiveCasinoShowMiniLobby";

        //LogoSetup
        [Config(Comments = "Logo Setup", MaxLength = 255
            , ProductionDefaultValue = "VIVO_LOGO"
            , StagingDefaultValue = "VIVO_LOGO")]
        public const string CELogoSetup = "Vivo.CELogoSetup";

        //Slot operator id
        [Config(Comments = "Slot Operator Id", MaxLength = 255
            , ProductionDefaultValue = "1743"
            , StagingDefaultValue = "1743")]
        public const string SlotOperatorId = "Vivo.SlotOperatorId";

        // LiveCasinoMobileUrl    https://www.vazagaming.com/vivo/games/roulette_game_contained_v2.php?token=3ffad54d3da94da88097a582b75a18ee~24&operatorID=1743&language=EN&tableID=1&LimitID=2744196&serverID=3649143&logoSetup=VIVO_LOGO&isKochip=false&isPlaceBetCTA=false
        [Config(Comments = "Live Casino Mobile Url", MaxLength = 512
            , ProductionDefaultValue = "https://www.1vivo.com/mobile/game/{0}"
            , StagingDefaultValue = "https://www.1vivo.com/mobile/game/{0}")]
        public const string LiveCasinoMobileUrl = "Vivo.LiveCasinoMobileUrl";

        // LiveCasinoLobbyMobileUrl    https://www.1vivo.com/mobile/lobby?token=3ffad54d3da94da88097a582b75a18ee~24&operatorID=1743&language=EN&tableID=1&LimitID=2744196&serverID=3649143&logoSetup=VIVO_LOGO&isKochip=false&isPlaceBetCTA=false
        [Config(Comments = "Live Casino Lobby Mobile Url", MaxLength = 512
            , ProductionDefaultValue = "https://www.1vivo.com/mobile/lobby"
            , StagingDefaultValue = "https://www.1vivo.com/mobile/lobby")]
        public const string LiveCasinoLobbyMobileUrl = "Vivo.LiveCasinoLobbyMobileUrl";
    }
}
