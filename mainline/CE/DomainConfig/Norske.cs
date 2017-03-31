namespace CE.DomainConfig
{
    public static class Norske
    {
        // PlayGameBaseUrl
        [Config(Comments = "Casino Game Base URL", MaxLength = 255
            , ProductionDefaultValue = "http://5.35.212.50:8091/Main/Index"
            , StagingDefaultValue = "http://5.35.212.50:8091/Main/Index")]
        public const string CasinoGameBaseURL = "Norske.PlayGameBaseURL";

        //CELaunchUrlProtocol
        [Config(Comments = "CE Launch Url Protocol", MaxLength = 5
            , ProductionDefaultValue = "https"
            , StagingDefaultValue = "http")]
        public const string CELaunchUrlProtocol = "Norske.CELaunchUrlProtocol";

        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "Norske.CELaunchInjectScriptUrl";
    }
}
