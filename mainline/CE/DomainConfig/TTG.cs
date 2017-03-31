using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CE.DomainConfig
{
    public class TTG
    {
        [Config(Comments = "Game Base URL", MaxLength = 512
            , ProductionDefaultValue = "https://ams-games.stg.ttms.co/casino/default/game/game.html"
            , StagingDefaultValue = "https://ams-games.stg.ttms.co/casino/default/game/game.html")]
        public const string GameBaseURL = "TTG.GameBaseURL";

        [Config(Comments = "Game Base Mobile URL", MaxLength = 512
            , ProductionDefaultValue = "https://ams-games.stg.ttms.co/casino/default/game/game.html"
            , StagingDefaultValue = "https://ams-games.stg.ttms.co/casino/default/game/game.html")]
        public const string GameBaseMobileURL = "TTG.GameBaseMobileURL";

        [Config(Comments = "Game Base Lobby URL", MaxLength = 512
            , ProductionDefaultValue = "http://ams-games.stg.ttms.co/casino/mobile/lobby/index.html"
            , StagingDefaultValue = "http://ams-games.stg.ttms.co/casino/mobile/lobby/index.html")]
        public const string GameBaseLobbyURL = "TTG.GameBaseLobbyURL";

        [Config(Comments = "IsdId", MaxLength = 255
           , ProductionDefaultValue = ""
           , StagingDefaultValue = "")]
        public const string IsdId = "TTG.IsdId";

        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
           , ProductionDefaultValue = ""
           , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "TTG.CELaunchInjectScriptUrl";

        //CEShowLiveLobby
        [Config(Comments = "Show Live Lobby(true/false)", MaxLength = 512
            , ProductionDefaultValue = "false"
            , StagingDefaultValue = "false")]
        public const string ShowLiveLobby = "TTG.ShowLiveLobby";

        [Config(Comments = "CE Launch Url Protocol", MaxLength = 5
            , ProductionDefaultValue = "https"
            , StagingDefaultValue = "http")]
        public const string CELaunchUrlProtocol = "TTG.CELaunchUrlProtocol";
    }
}
