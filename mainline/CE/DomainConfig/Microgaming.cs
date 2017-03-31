namespace CE.DomainConfig
{
    public static class Microgaming
    {
        // MicrogamingPlayFunGameUrl
        [Config(Comments = "Casino Game Fun Mode URL", MaxLength = 512
            , ProductionDefaultValue = "https://webserver1.bluemesa.mgsops.net/quickfire{0}/?sext1=demo&sext2=demo&gameid={1}&csid=5002&ul={0}&bc=config-quickfire--{0}--MAL-Demo"
            , StagingDefaultValue = "http://webserver1.bluemesa.mgsops.net/quickfire{0}/?sext1=demo&sext2=demo&gameid={1}&csid=5002&ul={0}&bc=config-quickfire--{0}--MAL-Demo")]
        public const string CasinoGameFunModeURL = "Microgaming.CasinoGameFunModeURL";

        // MicrogamingPlayRealGameUrl
        [Config(Comments = "Casino Game Real Money Mode URL", MaxLength = 512, AllowCountrySpecificValue = true
            , ProductionDefaultValue = "https://webserver1.bluemesa.mgsops.net/quickfire{0}/?AuthToken={2}&sext1=genauth&sext2=genauth&gameid={1}&csid=5022&ul={0}&bc=config-quickfire--{0}--MAL"
            , StagingDefaultValue = "http://webserver1.bluemesa.mgsops.net/quickfire{0}/?AuthToken={2}&sext1=genauth&sext2=genauth&gameid={1}&csid=5022&ul={0}&bc=config-quickfire--{0}--MAL")]
        public const string CasinoGameRealMoneyModeURL = "Microgaming.CasinoGameRealMoneyModeURL";

        // MicrogamingMiniGameFunModeCasinoID
        [Config(Comments = "Mini Game Fun Mode Casino ID", MaxLength = 10
            , ProductionDefaultValue = "1866"
            , StagingDefaultValue = "5002")]
        public const string MiniGameFunModeCasinoID = "Microgaming.MiniGameFunModeCasinoID";

        // MicrogamingMiniGameRealModeCasinoID
        [Config(Comments = "Mini Game Real Money Mode Casino ID", MaxLength = 10, AllowCountrySpecificValue = true
            , ProductionDefaultValue = "1113"
            , StagingDefaultValue = "5022")]
        public const string MiniGameRealMoneyModeCasinoID = "Microgaming.MiniGameRealMoneyModeCasinoID";

        // MicrogamingMiniGameXManUrl
        [Config(Comments = "Mini Game XMan URL", MaxLength = 255
            , ProductionDefaultValue = "https://qplay3.gameassists.co.uk/xman/x.x"
            , StagingDefaultValue = "http://webserver1.bluemesa.mgsops.net/casino/XManHandler/x.x")]
        public const string MiniGameXManURL = "Microgaming.MiniGameXManURL";

        // MicrogamingMiniGameNanoXProSwfUrl
        [Config(Comments = "Mini Game xpro.swf URL", MaxLength = 255
            , ProductionDefaultValue = "https://minigames.gameassists.co.uk/minigames/xprox.swf"
            , StagingDefaultValue = "http://webserver1.bluemesa.mgsops.net/flash/minigames/xprox.swf")]
        public const string MiniGameXProSwfURL = "Microgaming.MiniGameXProSwfURL";

        // MicrogamingMiniGameNanoSysSwfUrl
        [Config(Comments = "Mini Game minisys.swf URL", MaxLength = 255
            , ProductionDefaultValue = "https://minigames.gameassists.co.uk/minigames/system/miniSys.swf"
            , StagingDefaultValue = "http://webserver1.bluemesa.mgsops.net/flash/minigames/system/minisys.swf")]
        public const string MiniGameMiniSysSwfURL = "Microgaming.MiniGameMiniSysSwfURL";

        // MicrogamingNanoGameNanoXProSwfUrl
        [Config(Comments = "Nano Game xpro.swf URL", MaxLength = 255
            , ProductionDefaultValue = "https://nanogames.gameassists.co.uk/nanogames/xprox.swf"
            , StagingDefaultValue = "http://webserver1.bluemesa.mgsops.net/flash/nanogames/xprox.swf")]
        public const string NanoGameXProSwfURL = "Microgaming.NanoGameXProSwfURL";

        // MicrogamingNanoGameNanoSysSwfUrl
        [Config(Comments = "Nano Game nanosys.swf URL", MaxLength = 255
            , ProductionDefaultValue = "https://nanogames.gameassists.co.uk/nanogames/system/nanoSys.swf"
            , StagingDefaultValue = "http://webserver1.bluemesa.mgsops.net/flash/nanogames/system/nanosys.swf")]
        public const string NanoGameNanoSysSwfURL = "Microgaming.NanoGameNanoSysSwfURL";

        // MicrogamingMobilePlayFunGameUrl
        [Config(Comments = "Mobile Game Fun Mode URL", MaxLength = 512
            , ProductionDefaultValue = "http://41.223.121.12/MobileWebgames1_4/game/?moduleID={0}&clientID={1}&gameName={2}&gametitle={3}&LanguageCode={4}&clientTypeID=40&casinoID=5002&lobbyName=vanguardTest&loginType=VanguardSessionToken&xmanEndPoints=http%3a%2f%2f41.223.121.12%2fXManHandler%2fx.x&routerEndPoints=&isRGI=true&isPracticePlay=true&disableRealPlayBanner=true&lobbyurl={5}"
            , StagingDefaultValue = "http://41.223.121.12/MobileWebgames1_4/game/?moduleID={0}&clientID={1}&gameName={2}&gametitle={3}&LanguageCode={4}&clientTypeID=40&casinoID=5002&lobbyName=vanguardTest&loginType=VanguardSessionToken&xmanEndPoints=http%3a%2f%2f41.223.121.12%2fXManHandler%2fx.x&routerEndPoints=&isRGI=true&isPracticePlay=true&disableRealPlayBanner=true&lobbyurl={5}")]
        public const string MobileGameFunModeURL = "Microgaming.MobileGameFunModeURL";

        // MicrogamingMobilePlayRealGameUrl
        [Config(Comments = "Mobile Game Real Money Mode URL", MaxLength = 512, AllowCountrySpecificValue = true
            , ProductionDefaultValue = "http://41.223.121.12/MobileWebgames1_4/game/?moduleID={0}&clientID={1}&gameName={2}&gametitle={3}&LanguageCode={4}&clientTypeID=40&casinoID=5031&lobbyName=vanguardTest&loginType=VanguardSessionToken&xmanEndPoints=http%3a%2f%2f41.223.121.12%2fXManHandler%2fx.x&routerEndPoints=&isRGI=true&isPracticePlay=false&disableRealPlayBanner=true&lobbyurl={6}&authToken={5}"
            , StagingDefaultValue = "http://41.223.121.12/MobileWebgames1_4/game/?moduleID={0}&clientID={1}&gameName={2}&gametitle={3}&LanguageCode={4}&clientTypeID=40&casinoID=5031&lobbyName=vanguardTest&loginType=VanguardSessionToken&xmanEndPoints=http%3a%2f%2f41.223.121.12%2fXManHandler%2fx.x&routerEndPoints=&isRGI=true&isPracticePlay=false&disableRealPlayBanner=true&lobbyurl={6}&authToken={5}")]
        public const string MobileGameRealMoneyModeURL = "Microgaming.MobileGameRealMoneyModeURL";

        // MobileGameRealityCheckScriptURL
        [Config(Comments = "Reality check bridge script URL", MaxLength = 512, AllowCountrySpecificValue = true
            , ProductionDefaultValue = "http://41.223.121.12/MobileWebgames1_4/js/InterfaceApi/InterfaceApi.js"
            , StagingDefaultValue = "http://41.223.121.12/MobileWebgames1_4/js/InterfaceApi/InterfaceApi.js" )]
        public const string MobileGameRealityCheckScriptURL = "Microgaming.MobileGameRealityCheckScriptURL";

        // MicrogamingLiveDealerLobbyUrl
        [Config(Comments = "Live Casino Lobby URL", MaxLength = 255, AllowCountrySpecificValue = true
            , ProductionDefaultValue = "https://etiloader3.valueactive.eu/ETILoader/default.aspx?token={1}&casinoid=1166&UL={0}&VideoQuality=2&ModuleID=70004&ClientID=4&ClientType=1&UserType=0&ProductID=2&BetProfileID=0&ActiveCurrency=Credits&LoginName=&Password=&StartingTab={2}&CustomLDParam=NULL"
            , StagingDefaultValue = "http://webserver1.bluemesa.mgsops.net/global/ETILoader/Default.aspx?token={1}&casinoid=5027&UL={0}&VideoQuality=2&ModuleID=70004&ClientID=2&ClientType=1&UserType=0&ProductID=2&BetProfileID=0&ActiveCurrency=Credits&LoginName=&Password=&StartingTab={2}")]
        public const string LiveCasinoLobbyURL = "Microgaming.LiveCasinoLobbyURL";


        //CELaunchUrlProtocol
        [Config(Comments = "CE Launch Url Protocol", MaxLength = 5
            , ProductionDefaultValue = "https"
            , StagingDefaultValue = "http")]
        public const string CELaunchUrlProtocol = "Microgaming.CELaunchUrlProtocol";



        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "Microgaming.CELaunchInjectScriptUrl";
    }
}
