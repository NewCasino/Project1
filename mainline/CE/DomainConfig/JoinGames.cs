namespace CE.DomainConfig
{
    public class JoinGames
    {
        [Config(Comments = "Game Base URL", MaxLength = 512
           , ProductionDefaultValue = "http://test.joingames.com/PlayGame"
           , StagingDefaultValue = "http://test.joingames.com/PlayGame")]
        public const string GameBaseURL = "JoinGames.GameBaseURL";

        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "JoinGames.CELaunchInjectScriptUrl";

        [Config(Comments = "Partner ID", MaxLength = 512
            , ProductionDefaultValue = "1"
            , StagingDefaultValue = "1")]
        public const string PartnerID = "JoinGames.PartnerID";

        [Config(Comments = "Client ID", MaxLength = 512
            , ProductionDefaultValue = "1"
            , StagingDefaultValue = "1")]
        public const string ClientID = "JoinGames.ClientID";

        [Config(Comments = "Mode", MaxLength = 512
            , ProductionDefaultValue = "prod"
            , StagingDefaultValue = "dev")]
        public const string Mode = "JoinGames.Mode";
    }
}
