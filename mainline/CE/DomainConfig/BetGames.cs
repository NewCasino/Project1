namespace CE.DomainConfig
{
    public class BetGames
    {
        [Config(Comments = "Server", MaxLength = 512
            , ProductionDefaultValue = "http://demo.betgames.tv"
            , StagingDefaultValue = "http://demo.betgames.tv")]
        public const string Server = "BetGames.Server";

        [Config(Comments = "Partner Code", MaxLength = 512
            , ProductionDefaultValue = "everymatrix"
            , StagingDefaultValue = "everymatrix")]
        public const string PartnerCode = "BetGames.PartnerCode";

        [Config(Comments = "Turkish Partner Code", MaxLength = 512
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string SubPartnerCode = "BetGames.SubPartnerCode";

        [Config(Comments = "Launch JavaScript Src", MaxLength = 512
            , ProductionDefaultValue = "{0}/design/client/js/betgames.js"
            , StagingDefaultValue = "{0}/design/client/js/betgames.js")]
        public const string LaunchJavaScriptSrc = "BetGames.LaunchJavaScriptSrc";

        [Config(Comments = "Show Live Lobby(true/false)", MaxLength = 512
            , ProductionDefaultValue = "false"
            , StagingDefaultValue = "false")]
        public const string ShowLiveLobby = "BetGames.ShowLiveLobby";

        [Config(Comments = "Default Lobby GameId", MaxLength = 512
            , ProductionDefaultValue = "6"
            , StagingDefaultValue = "6")]
        public const string DefaultLobbyGameId = "BetGames.DefaultLobbyGameId";

        //CELaunchUrlProtocol
        [Config(Comments = "CE Launch Url Protocol", MaxLength = 5
            , ProductionDefaultValue = "https"
            , StagingDefaultValue = "http")]
        public const string CELaunchUrlProtocol = "BetGames.CELaunchUrlProtocol";

        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "BetGames.CELaunchInjectScriptUrl";
    }
}
