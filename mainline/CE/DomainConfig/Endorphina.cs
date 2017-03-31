namespace CE.DomainConfig
{
    public static class Endorphina
    {
        // EndorphinaGameBaseUrl
        [Config(Comments = "Game Base URL", MaxLength = 512
            , ProductionDefaultValue = "https://test.endorphina.com/api/sessions/seamless/rest/v1?"
            , StagingDefaultValue = "https://test.endorphina.com/api/sessions/seamless/rest/v1?")]
        public const string GameBaseURL = "Endorphina.GameBaseURL";

        // Fun Mode Game Url
        [Config(Comments = "Fun Mode Game", MaxLength = 512
            , ProductionDefaultValue = "http://edemo.endorphina.com/public/integration/api/link/accountId/{0}/hash/{1}/returnURL/{2}"
            , StagingDefaultValue = "http://edemo.endorphina.com/public/integration/api/link/accountId/{0}/hash/{1}/returnURL/{2}")]
        public const string FunModeGameBaseURL = "Endorphina.FunModeGameBaseURL";

        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "Endorphina.CELaunchInjectScriptUrl";

        //AccountIdFromVendor
        [Config(Comments = "Account Id FromVendor", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string AccountIdFromVendor = "Endorphina.AccountIdFromVendor";

        //CELaunchUrlProtocol
        [Config(Comments = "CE Launch Url Protocol", MaxLength = 5
            , ProductionDefaultValue = "https"
            , StagingDefaultValue = "https")]
        public const string CELaunchUrlProtocol = "Endorphina.CELaunchUrlProtocol";
    }
}
