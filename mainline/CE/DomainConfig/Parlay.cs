
namespace CE.DomainConfig
{
    public class Parlay
    {

        [Config(Comments = "Game Base URL", MaxLength = 512
            , ProductionDefaultValue = "https://juegoslatam.com/site-api/gamelaunch/launch.action"
            , StagingDefaultValue = "https://stag.juegoslatam.com/site-api/gamelaunch/launch.action")]
        public const string GameBaseURL = "Parlay.GameBaseURL";

        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "Parlay.CELaunchInjectScriptUrl";

        [Config(Comments = "Partner ID", MaxLength = 512
            , ProductionDefaultValue = "1"
            , StagingDefaultValue = "1")]
        public const string PartnerID = "Parlay.PartnerID";

        [Config(Comments = "Client ID", MaxLength = 512
            , ProductionDefaultValue = "1"
            , StagingDefaultValue = "1")]
        public const string ClientID = "Parlay.ClientID";

        [Config(Comments = "Mode", MaxLength = 512
            , ProductionDefaultValue = "prod"
            , StagingDefaultValue = "dev")]
        public const string Mode = "Parlay.Mode";

        [Config(Comments = "Key", MaxLength = 512
            , ProductionDefaultValue = "aIKSoke89"
            , StagingDefaultValue = "aIKSoke89")]
        public const string Key = "Parlay.Key";

        [Config(Comments = "SiteId", MaxLength = 512
            , ProductionDefaultValue = "DTB"
            , StagingDefaultValue = "DTB")]
        public const string SiteId = "Parlay.SiteId";

        [Config(Comments = "ForceChannel", MaxLength = 32
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "flash")]
        public const string ForceChannel = "Parlay.ForceChannel";
        
        //CELaunchUrlProtocol
        [Config(Comments = "CE Launch Url Protocol", MaxLength = 5
            , ProductionDefaultValue = "https"
            , StagingDefaultValue = "http")]
        public const string CELaunchUrlProtocol = "Parlay.CELaunchUrlProtocol";

    }
}
