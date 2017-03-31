namespace CE.DomainConfig
{
    public class GTS
    {
        //https://test-thrills.virtuefusion.com/igames/play/game_page.do?gameType=***GAME_TYPE***&region=***REGION***&token=***TOKEN*** 

        [Config(Comments = "Game Base URL", MaxLength = 512
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "https://test-thrills.virtuefusion.com/igames/play/game_page.do")]
        public const string GameBaseURL = "GTS.GameBaseURL";

        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "GTS.CELaunchInjectScriptUrl";
    }
}
