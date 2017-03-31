namespace CE.DomainConfig
{
    public static class Tombala
    {
        [Config(Comments = "Game Base URL", MaxLength = 512
         , ProductionDefaultValue = "http://www.tombalalive.com/service"
         , StagingDefaultValue = "http://www.tombalalive.com/service")] //Should be changed after Vendor fix url for stage
        public const string GameBaseURL = "Tombala.GameBaseURL";

        [Config(Comments = "Mobile Game Base URL", MaxLength = 512
            , ProductionDefaultValue = "http://www.tombalalive.com/service"
            , StagingDefaultValue = "http://www.tombalalive.com/service")]
        public const string MobileGameBaseURL = "Tombala.MobileGameBaseURL";

        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
           , ProductionDefaultValue = ""
           , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "Tombala.CELaunchInjectScriptUrl";

        //CELaunchUrlProtocol
        [Config(Comments = "CE Launch Url Protocol", MaxLength = 5
            , ProductionDefaultValue = "https"
            , StagingDefaultValue = "http")]
        public const string CELaunchUrlProtocol = "Tombala.CELaunchUrlProtocol";
    }
}
