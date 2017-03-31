
namespace CE.DomainConfig
{
    public class CandleBets
    {
        [Config(Comments = "Game Base URL", MaxLength = 512
            , ProductionDefaultValue = "https://everymatrix.realisticgames.co.uk/LaunchGame"
            , StagingDefaultValue = "http://52.16.40.134/")]
        public const string GameBaseURL = "CandleBets.GameBaseURL";
        
        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "CandleBets.CELaunchInjectScriptUrl";

        //CELaunchUrlProtocol
        [Config(Comments = "CE Launch Url Protocol", MaxLength = 5
            , ProductionDefaultValue = "https"
            , StagingDefaultValue = "http")]
        public const string CELaunchUrlProtocol = "CandleBets.CELaunchUrlProtocol";

    }
}
