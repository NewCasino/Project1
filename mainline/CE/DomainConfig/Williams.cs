namespace CE.DomainConfig
{
    public class Williams
    {
        [Config(Comments = "Game Base URL", MaxLength = 512
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "https://vanilla.integration.casinarena.com/casinomatrix/matrix.html")]
        public const string GameBaseURL = "WilliamsInteractive.GameBaseURL";

        [Config(Comments = "Mobile Game Base URL", MaxLength = 512
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "https://vanilla-mob.integration.casinarena.com/casinomatrix/matrix.html")]
        public const string MobileGameBaseURL = "WilliamsInteractive.MobileGameBaseURL";

        [Config(Comments = "Partner Code", MaxLength = 255
            , ProductionDefaultValue = "everymatrix"
            , StagingDefaultValue = "everymatrix")]
        public const string PartnerCode = "WilliamsInteractive.PartnerCode";

        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "WilliamsInteractive.CELaunchInjectScriptUrl";
    }
}
