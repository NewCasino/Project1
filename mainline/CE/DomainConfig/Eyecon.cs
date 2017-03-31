using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CE.DomainConfig
{
    public class Eyecon
    {

        [Config(Comments = "Game Base URL", MaxLength = 512
            , ProductionDefaultValue = "http://everymatrix-int.test.eyecon.com.au/maroon/servlet/MaroonAPI"
            , StagingDefaultValue = "http://everymatrix-int.test.eyecon.com.au/maroon/servlet/MaroonAPI")]
        public const string GameBaseURL = "Eyecon.GameBaseURL";

        [Config(Comments = "Brand", MaxLength = 512
            , ProductionDefaultValue = "1"
            , StagingDefaultValue = "1")]
        public const string Brand = "Eyecon.Brand";

        [Config(Comments = "NID", MaxLength = 512
            , ProductionDefaultValue = "1"
            , StagingDefaultValue = "1")]
        public const string NID = "Eyecon.NID";

        [Config(Comments = "SID", MaxLength = 512
            , ProductionDefaultValue = "1"
            , StagingDefaultValue = "1")]
        public const string SID = "Eyecon.SID";

        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "Eyecon.CELaunchInjectScriptUrl";
    }
}
