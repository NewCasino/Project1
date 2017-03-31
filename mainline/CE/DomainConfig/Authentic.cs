
namespace CE.DomainConfig
{
    public class Authentic
    {

        [Config(Comments = "Game Base URL", MaxLength = 512
            , ProductionDefaultValue = "https://everymatrix.Authentic.co.uk/LaunchGame"
            , StagingDefaultValue = "http://game.authenticstage.live/game/loaderEVM.aspx")]
        public const string GameBaseURL = "Authentic.GameBaseURL";

        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "Authentic.CELaunchInjectScriptUrl";

        [Config(Comments = "Partner ID", MaxLength = 512
            , ProductionDefaultValue = "1"
            , StagingDefaultValue = "1")]
        public const string PartnerID = "Authentic.PartnerID";

        [Config(Comments = "Mode", MaxLength = 512
            , ProductionDefaultValue = "prod"
            , StagingDefaultValue = "dev")]
        public const string Mode = "Authentic.Mode";

        //CEShowLiveLobby
        [Config(Comments = "Show Live Lobby(true/false)", MaxLength = 512
            , ProductionDefaultValue = "false"
            , StagingDefaultValue = "false")]
        public const string ShowLiveLobby = "Authentic.ShowLiveLobby";
    }
}
