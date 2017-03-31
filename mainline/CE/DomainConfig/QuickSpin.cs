namespace CE.DomainConfig
{
    public class QuickSpin
    {

        [Config(Comments = "Game Base URL", MaxLength = 512, AllowCountrySpecificValue = true
            , ProductionDefaultValue = "https://d3nsdzdtjbr5ml.cloudfront.net/casino/examples/relax/launch.html"
            , StagingDefaultValue = "https://d3nsdzdtjbr5ml.cloudfront.net/casino/examples/relax/launch.html")]
        public const string GameBaseURL = "QuickSpin.GameBaseURL";
        
        [Config(Comments = "Game Mobile Base URL", MaxLength = 512, AllowCountrySpecificValue = true
            , ProductionDefaultValue = "https://d2drhksbtcqozo.cloudfront.net/mcasino/betit/{0}/index.html?gameid={0}"
            , StagingDefaultValue = "https://d2drhksbtcqozo.cloudfront.net/mcasino/betit/{0}/index.html?gameid={0}")]
            
        public const string GameMobileBaseURL = "QuickSpin.GameMobileBaseURL";
        
        // [dev|intg|prod] Environment switch, testing, staging or production
        [Config(Comments = "Mode", MaxLength = 512
            , ProductionDefaultValue = "prod"
            , StagingDefaultValue = "dev")]
        public const string Mode = "QuickSpin.Mode";

        [Config(Comments = "Partner ID", MaxLength = 512
            , ProductionDefaultValue = "1"
            , StagingDefaultValue = "1")]
        public const string PartnerID = "QuickSpin.PartnerID";

        [Config(Comments = "Client ID", MaxLength = 512
            , ProductionDefaultValue = "1"
            , StagingDefaultValue = "1")]
        public const string ClientID = "QuickSpin.ClientID";

        //CELaunchUrlProtocol
        [Config(Comments = "CE Launch Url Protocol", MaxLength = 5
            , ProductionDefaultValue = "https"
            , StagingDefaultValue = "http")]
        public const string CELaunchUrlProtocol = "QuickSpin.CELaunchUrlProtocol";

        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "QuickSpin.CELaunchInjectScriptUrl";

    }
}
