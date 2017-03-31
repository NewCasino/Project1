namespace CE.DomainConfig
{
    public class Lega
    {
        [Config(Comments = "Game Base URL", MaxLength = 512
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "http://assets.repo1.legadev.leandergames.com:81/launcher/GameManager.php")]
        public const string GameBaseURL = "Lega.GameBaseURL";

        [Config(Comments = "Site ID", MaxLength = 512
            , ProductionDefaultValue = "everymatrix"
            , StagingDefaultValue = "everymatrix")]
        public const string SiteID = "Lega.SiteID";

        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "Lega.CELaunchInjectScriptUrl";
    }
}
