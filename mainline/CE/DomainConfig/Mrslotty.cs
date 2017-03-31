
namespace CE.DomainConfig
{
    public class Mrslotty
    {

        [Config(Comments = "Game Base URL", MaxLength = 512
            , ProductionDefaultValue = "http://play.staging.mrslotty.com/3rd/integrations/everymatrix/launch"
            , StagingDefaultValue = "http://play.staging.mrslotty.com/3rd/integrations/everymatrix/launch")]
        public const string GameBaseURL = "Mrslotty.GameBaseURL";

        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "Mrslotty.CELaunchInjectScriptUrl";

        [Config(Comments = "Partner ID", MaxLength = 512
            , ProductionDefaultValue = "1"
            , StagingDefaultValue = "1")]
        public const string PartnerID = "Mrslotty.PartnerID";

        [Config(Comments = "Client ID", MaxLength = 512
            , ProductionDefaultValue = "1"
            , StagingDefaultValue = "1")]
        public const string ClientID = "Mrslotty.ClientID";

        [Config(Comments = "Mode", MaxLength = 512
            , ProductionDefaultValue = "prod"
            , StagingDefaultValue = "dev")]
        public const string Mode = "Mrslotty.Mode";
    }
}
