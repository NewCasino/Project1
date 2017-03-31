namespace CE.DomainConfig
{
    public class EGB
    {
        //https://<egb_host_name>/<egb_path>/gamestart.html?playerName=***PLAYER_NAME***&sessionToken=***SESSION_TOKEN***&gameKey=***GAME_KEY***&templateName=***TEMPLATE_NAME***&gameMode=***GAME_MODE***&lang=***LANG***
        //lang - ISO 639-1 code

        [Config(Comments = "Game Base URL", MaxLength = 512
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string GameBaseURL = "EGB.GameBaseURL";

        [Config(Comments = "Template for game to be launched", MaxLength = 512
            , ProductionDefaultValue = "default"
            , StagingDefaultValue = "default")]
        public const string TemplateName = "EGB.TemplateName";

        //CELaunchUrlProtocol
        [Config(Comments = "CE Launch Url Protocol", MaxLength = 5
            , ProductionDefaultValue = "https"
            , StagingDefaultValue = "http")]
        public const string CELaunchUrlProtocol = "EGB.CELaunchUrlProtocol";

        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "EGB.CELaunchInjectScriptUrl";

    }
}
