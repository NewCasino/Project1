
namespace CE.DomainConfig
{
    public class Hybrino
    {

        [Config(Comments = "Game Base URL", MaxLength = 512
            , ProductionDefaultValue = "http://test.hybrino.com/PlayGame"
            , StagingDefaultValue = "http://test.hybrino.com/PlayGame")]
        public const string GameBaseURL = "Hybrino.GameBaseURL";

        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "Hybrino.CELaunchInjectScriptUrl";

        [Config(Comments = "Partner ID", MaxLength = 512
            , ProductionDefaultValue = "1"
            , StagingDefaultValue = "1")]
        public const string PartnerID = "Hybrino.PartnerID";

        [Config(Comments = "Client ID", MaxLength = 512
            , ProductionDefaultValue = "1"
            , StagingDefaultValue = "1")]
        public const string ClientID = "Hybrino.ClientID";

        [Config(Comments = "Mode", MaxLength = 512
            , ProductionDefaultValue = "prod"
            , StagingDefaultValue = "dev")]
        public const string Mode = "Hybrino.Mode";
    }
}
