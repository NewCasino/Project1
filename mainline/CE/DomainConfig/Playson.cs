namespace CE.DomainConfig
{
    public static class Playson
    {
        [Config(Comments = "Game Base URL", MaxLength = 512
            , ProductionDefaultValue = "https://cdn.ps-gamespace.com/gm/index.html?partner=everymatrix-preprod"
            , StagingDefaultValue = "https://cdn.ps-gamespace.com/gm/index.html?partner=everymatrix-preprod")]
        public const string GameBaseURL = "Playson.GameBaseURL";

        [Config(Comments = "Mobile Game Base URL", MaxLength = 512
            , ProductionDefaultValue = "https://cdn.ps-gamespace.com/gm/index.html?partner=everymatrix-preprod"
            , StagingDefaultValue = "https://cdn.ps-gamespace.com/gm/index.html?partner=everymatrix-preprod")]
        public const string MobileGameBaseURL = "Playson.MobileGameBaseURL";

        [Config(Comments = "Partner code", MaxLength = 5, AllowCountrySpecificValue = true
            , ProductionDefaultValue = "ABC"
            , StagingDefaultValue = "ABC")]
        public const string Partner = "Playson.Partner";
        
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
           , ProductionDefaultValue = ""
           , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "Playson.CELaunchInjectScriptUrl";

        [Config(Comments = "CE Launch Url Protocol", MaxLength = 5
            , ProductionDefaultValue = "https"
            , StagingDefaultValue = "http")]
        public const string CELaunchUrlProtocol = "Playson.CELaunchUrlProtocol";

    }
}
