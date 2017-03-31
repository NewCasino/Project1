namespace CE.DomainConfig
{
    public class RCT
    {

        [Config(Comments = "Game Base URL", MaxLength = 512
            , ProductionDefaultValue = "https://www.allwayslpaying.com/drivers/openSession.php"
            , StagingDefaultValue = "https://www.allwayslpaying.com/drivers/openSession.php")]
        public const string GameBaseURL = "RCT.GameBaseURL";

        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "RCT.CELaunchInjectScriptUrl";

        [Config(Comments = "Partner ID", MaxLength = 512
            , ProductionDefaultValue = "1"
            , StagingDefaultValue = "1")]
        public const string PartnerID = "RCT.PartnerID";

        [Config(Comments = "Client ID", MaxLength = 512
            , ProductionDefaultValue = "1"
            , StagingDefaultValue = "1")]
        public const string ClientID = "RCT.ClientID";

        [Config(Comments = "Mode", MaxLength = 512
            , ProductionDefaultValue = "prod"
            , StagingDefaultValue = "dev")]
        public const string Mode = "RCT.Mode";
    }
}
