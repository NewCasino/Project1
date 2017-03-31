namespace CE.DomainConfig
{
    public static class ViG
    {
        [Config(Comments = "Game Base URL", MaxLength = 512
            , ProductionDefaultValue = "http://live.viggames.com/launch.php"
            , StagingDefaultValue = "http://live.viggames.com/launch.php")]
        public const string GameBaseURL = "ViG.GameBaseURL";

        [Config(Comments = "Mobile Game Base URL", MaxLength = 512
            , ProductionDefaultValue = "http://live.viggames.com/launch.php"
            , StagingDefaultValue = "http://live.viggames.com/launch.php")]
        public const string MobileGameBaseURL = "ViG.MobileGameBaseURL";

        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
           , ProductionDefaultValue = ""
           , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "ViG.CELaunchInjectScriptUrl";

        [Config(Comments = "CE Launch Url Protocol", MaxLength = 5
            , ProductionDefaultValue = "https"
            , StagingDefaultValue = "http")]
        public const string CELaunchUrlProtocol = "ViG.CELaunchUrlProtocol";
    }
}
