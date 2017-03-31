namespace CE.DomainConfig
{
    public class HoGaming
    {
        [Config(Comments = "Game Base Login URL", MaxLength = 512
          , ProductionDefaultValue = ""
          , StagingDefaultValue = "")]
        public const string GameBaseLoginURL = "HoGaming.GameBaseLoginURL";

        [Config(Comments = "Game Base Lobby URL", MaxLength = 512
          , ProductionDefaultValue = ""
          , StagingDefaultValue = "")]
        public const string GameBaseLobbyURL = "HoGaming.GameBaseLobbyURL";

        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "HoGaming.CELaunchInjectScriptUrl";

        //CEShowLiveLobby
        [Config(Comments = "Show Live Lobby(true/false)", MaxLength = 512
            , ProductionDefaultValue = "false"
            , StagingDefaultValue = "false")]
        public const string ShowLiveLobby = "HoGaming.ShowLiveLobby";
    }
}
