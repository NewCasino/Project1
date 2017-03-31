namespace CE.DomainConfig
{
    public static class OneXTwoGaming
    {
        // PlayGameBaseUrl
        [Config(Comments = "Casino Game Base URL", MaxLength = 255
            , ProductionDefaultValue = "http://89.151.126.7/f1x2gamesEM/loadGame.jsp"
            , StagingDefaultValue = "http://89.151.126.7/f1x2gamesEM/loadGame.jsp")]
        public const string CasinoGameBaseURL = "OneXTwoGaming.PlayGameBaseURL";

        // MobilePlayGameBaseUrl
        [Config(Comments = "Mobile Casino Game Base URL", MaxLength = 255
            , ProductionDefaultValue = "http://89.151.126.7/f1x2gamesEM/loadMobileGame.jsp"
            , StagingDefaultValue = "http://89.151.126.7/f1x2gamesEM/loadMobileGame.jsp")]
        public const string MobileCasinoGameBaseURL = "OneXTwoGaming.MobilePlayGameBaseURL";

        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "OneXTwoGaming.CELaunchInjectScriptUrl";
    }
}
