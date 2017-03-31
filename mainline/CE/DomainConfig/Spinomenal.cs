namespace CE.DomainConfig
{
    public class Spinomenal
    {
        [Config(Comments = "Game Base URL", MaxLength = 512
        , ProductionDefaultValue = "http://api.spinomenal-dev.com/GameLauncher/GetEveryMatrixUrl"
        , StagingDefaultValue = "http://api.spinomenal-dev.com/GameLauncher/GetEveryMatrixUrl")]
        public const string GameBaseURL = "Spinomenal.GameBaseURL";

        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "Spinomenal.CELaunchInjectScriptUrl";

        [Config(Comments = "Partner ID", MaxLength = 512
            , ProductionDefaultValue = "1"
            , StagingDefaultValue = "1")]
        public const string PartnerID = "Spinomenal.PartnerID";

        [Config(Comments = "Client ID", MaxLength = 512
            , ProductionDefaultValue = "1"
            , StagingDefaultValue = "1")]
        public const string ClientID = "Spinomenal.ClientID";

        [Config(Comments = "Mode", MaxLength = 512
            , ProductionDefaultValue = "prod"
            , StagingDefaultValue = "dev")]
        public const string Mode = "Spinomenal.Mode";
    }
}
