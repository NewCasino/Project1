namespace CE.DomainConfig
{
    public class PlayStar
    {
        [Config(Comments = "Game Base URL", MaxLength = 512
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string GameBaseUrl = "PlayStar.GameBaseURL";

        [Config(Comments = "Access Host Id", MaxLength = 512
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string HostId = "PlayStar.HostId";

        [Config(Comments = "Return Url To Lobby", MaxLength = 512
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string ReturnUrl = "PlayStar.ReturnUrl";

        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "PlayStar.CELaunchInjectScriptUrl";
    }
}
