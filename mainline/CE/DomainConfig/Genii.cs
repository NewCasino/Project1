using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CE.DomainConfig
{
    public static class Genii
    {

        [Config(Comments = "Game Base URL", MaxLength = 512, AllowCountrySpecificValue = true
            , ProductionDefaultValue = "https://everymatrix-godwebclient-cur.geniigaming.net/GamesOnDemand/Type2"
            , StagingDefaultValue = "https://everymatrix-godwebclient-cur-genii7.aristx.net/GamesOnDemand/Type2")]
        public const string GameBaseURL = "Genii.GameBaseURL";

        [Config(Comments = "Mobile Game Base URL", MaxLength = 512, AllowCountrySpecificValue = true
            , ProductionDefaultValue = "https://everymatrix-godwebclient-cur.geniigaming.net/Mobile/GamesOnDemand/Type2"
            , StagingDefaultValue = "https://everymatrix-godwebclient-cur-genii7.aristx.net/Mobile/GamesOnDemand/Type2")]
        public const string MobileGameBaseURL = "Genii.MobileGameBaseURL";

        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
           , ProductionDefaultValue = ""
           , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "Genii.CELaunchInjectScriptUrl";

        //CELaunchUrlProtocol
        [Config(Comments = "CE Launch Url Protocol", MaxLength = 5
            , ProductionDefaultValue = "https"
            , StagingDefaultValue = "http")]
        public const string CELaunchUrlProtocol = "Genii.CELaunchUrlProtocol";
    }
}
