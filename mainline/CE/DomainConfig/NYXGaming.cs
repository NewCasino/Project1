namespace CE.DomainConfig
{
    public static class NYXGaming
    {
        // NYXGamingPlayFunGameUrl
        [Config(Comments = "Casino Game Fun Mode URL", MaxLength = 512
            , ProductionDefaultValue = "https://nogs-gl.nyxinteractive.eu/game/?nogsgameid={0}&nogslang={1}&nogscurrency={2}&nogsmode=demo&nogsoperatorid=1"
            , StagingDefaultValue = "http://nogs-gl-stage.nyxinteractive.eu/game/?nogsgameid={0}&nogslang={1}&nogscurrency={2}&nogsmode=demo&nogsoperatorid=1")]
        public const string CasinoGameFunModeURL = "NYXGaming.CasinoGameFunModeURL";


        // NYXGamingPlayRealGameUrl
        [Config(Comments = "Casino Game Real Money Mode URL", MaxLength = 512, AllowCountrySpecificValue = true
            , ProductionDefaultValue = "https://nogs-gl.nyxinteractive.eu/game/?nogsgameid={0}&nogslang={1}&nogscurrency={2}&accountid={3}&sessionid={4}&nogsmode=real&nogsoperatorid=1"
            , StagingDefaultValue = "http://nogs-gl-stage.nyxinteractive.eu/game/?nogsgameid={0}&nogslang={1}&nogscurrency={2}&accountid={3}&sessionid={4}&nogsmode=real&nogsoperatorid=1")]
        public const string CasinoGameRealMoneyModeURL = "NYXGaming.CasinoGameRealMoneyModeURL";


        //CELaunchUrlProtocol
        [Config(Comments = "CE Launch Url Protocol", MaxLength = 5
            , ProductionDefaultValue = "https"
            , StagingDefaultValue = "http")]
        public const string CELaunchUrlProtocol = "NYXGaming.CELaunchUrlProtocol";



        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "NYXGaming.CELaunchInjectScriptUrl";
    }
}
