
namespace CE.DomainConfig
{
    public class BetOnFinance
    {

        [Config(Comments = "Game Base URL", MaxLength = 512
            , ProductionDefaultValue = "https://everymatrix‐game.fibetco.com"
            , StagingDefaultValue = "https://everymatrix‐game.fibetco.com")]
        public const string GameBaseURL = "BetOnFinance.GameBaseURL";

        [Config(Comments = "Game Base Mobile URL", MaxLength = 512
            , ProductionDefaultValue = "https://everymatrix‐game.fibetco.com/cutv2/index.html"
            , StagingDefaultValue = "https://everymatrix‐game.fibetco.com")]
        public const string GameBaseMobileURL = "BetOnFinance.GameBaseMobileURL";

        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "BetOnFinance.CELaunchInjectScriptUrl";

        [Config(Comments = "Client ID", MaxLength = 512
            , ProductionDefaultValue = "1"
            , StagingDefaultValue = "1")]
        public const string ClientID = "BetOnFinance.ClientID";

    }
}
