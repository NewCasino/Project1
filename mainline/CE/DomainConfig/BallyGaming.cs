namespace CE.DomainConfig
{
    public static class BallyGaming
    {
        // OperatorID
        [Config(Comments = "Casino Game Operator ID", MaxLength = 50
            , ProductionDefaultValue = "JETB"
            , StagingDefaultValue = "JETB")]
        public const string OperatorID = "BallyGaming.OperatorID";

        // SkinID
        [Config(Comments = "Casino Game Skin ID", MaxLength = 50
            , ProductionDefaultValue = "JETB"
            , StagingDefaultValue = "JETB")]
        public const string SkinID = "BallyGaming.SkinID";


        // PlayGameBaseUrl
        [Config(Comments = "Casino Game Base URL", MaxLength = 255
            , ProductionDefaultValue = "http://ec2-174-129-209-148.compute-1.amazonaws.com/JETBGAmeLaunch/"
            , StagingDefaultValue = "http://ec2-174-129-209-148.compute-1.amazonaws.com/JETBGAmeLaunch/")]
        public const string CasinoGameBaseURL = "BallyGaming.PlayGameBaseURL";


        // PlayGameBaseUrl
        [Config(Comments = "Mobile Game Base URL", MaxLength = 255
            , ProductionDefaultValue = "http://ec2-174-129-209-148.compute-1.amazonaws.com/JETBMobileGameLaunch/"
            , StagingDefaultValue = "http://ec2-174-129-209-148.compute-1.amazonaws.com/JETBMobileGameLaunch/")]
        public const string MobileGameBaseURL = "BallyGaming.MobileGameBaseURL";


        //CELaunchUrlProtocol
        [Config(Comments = "CE Launch Url Protocol", MaxLength = 5
            , ProductionDefaultValue = "https"
            , StagingDefaultValue = "http")]
        public const string CELaunchUrlProtocol = "BallyGaming.CELaunchUrlProtocol";

        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "BallyGaming.CELaunchInjectScriptUrl";
    }
}
