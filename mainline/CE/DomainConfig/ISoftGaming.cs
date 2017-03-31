using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CE.DomainConfig
{
    public class ISoftGaming
    {
        [Config(Comments = "Game Base URL", MaxLength = 512
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string GameBaseURL = "ISoftGaming.GameBaseURL";

        [Config(Comments = "Mobile Game Base URL", MaxLength = 512
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string MobileGameBaseURL = "ISoftGaming.MobileGameBaseURL";


        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
           , ProductionDefaultValue = ""
           , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "ISoftGaming.CELaunchInjectScriptUrl";

    }
}
