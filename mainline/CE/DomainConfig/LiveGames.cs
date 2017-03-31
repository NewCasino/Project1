namespace CE.DomainConfig
{
    public class LiveGames
    {
        [Config(Comments = "Script Base URL", MaxLength = 512
         , ProductionDefaultValue = "//embed.livegames.io/e-if.js"
         , StagingDefaultValue = "//embed.livegames.io/e-if.js")]
        public const string ScriptBaseUrl = "LiveGames.ScriptBaseURL";

        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "LiveGames.CELaunchInjectScriptUrl";
    }
}
