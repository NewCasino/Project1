using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CE.DomainConfig
{
    public class Pariplay
    {
        [Config(Comments = "Game Base URL", MaxLength = 512
           , ProductionDefaultValue = "http://integration.intopenv.com:6552/play/everymatrix"
           , StagingDefaultValue = "http://integration.intopenv.com:6552/play/everymatrix")]
        public const string GameBaseURL = "Pariplay.GameBaseURL";

        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "Pariplay.CELaunchInjectScriptUrl";

        [Config(Comments = "Partner ID", MaxLength = 512
            , ProductionDefaultValue = "1"
            , StagingDefaultValue = "1")]
        public const string PartnerID = "Pariplay.PartnerID";

        [Config(Comments = "Client ID", MaxLength = 512
            , ProductionDefaultValue = "1"
            , StagingDefaultValue = "1")]
        public const string ClientID = "Pariplay.ClientID";

        [Config(Comments = "Mode", MaxLength = 512
            , ProductionDefaultValue = "prod"
            , StagingDefaultValue = "dev")]
        public const string Mode = "Pariplay.Mode";
    }
}
