namespace CE.DomainConfig
{
    public static class PlaynGO
    {
        // PlaynGOPlayGameBaseUrl
        [Config(Comments = "Casino Game Base URL", MaxLength = 255
            , ProductionDefaultValue = "https://cw.playngonetwork.com/casino/js"
            , StagingDefaultValue = "http://corestage.playngo.com:47010/Casino/js")]
        public const string CasinoGameBaseURL = "PlaynGO.CasinoGameBaseURL";


        // PlaynGOPID
        [Config(Comments = "Casino Game PID", MaxLength = 50
            , ProductionDefaultValue = "71"
            , StagingDefaultValue = "1")]
        public const string PID = "PlaynGO.PID";

        // PlaynGOPlayMobileGameBaseUrl
        [Config(Comments = "Mobile Game Base URL", MaxLength = 255
            , ProductionDefaultValue = "https://m.playngonetwork.com/Casino/PlayMobile?"
            , StagingDefaultValue = "http://m.playngo.com/Casino/PlayMobile?")]
        public const string MobileGameBaseURL = "PlaynGO.MobileGameBaseURL";


        //CELaunchUrlProtocol
        [Config(Comments = "CE Launch Url Protocol", MaxLength = 5
            , ProductionDefaultValue = "https"
            , StagingDefaultValue = "http")]
        public const string CELaunchUrlProtocol = "PlaynGO.CELaunchUrlProtocol";


        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "PlaynGO.CELaunchInjectScriptUrl";

    }
}
