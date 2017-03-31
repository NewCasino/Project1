namespace CE.DomainConfig
{
    public class StakeLogic
    {
        [Config(Comments = "Game Demo Base Url", MaxLength = 255
            , ProductionDefaultValue = "http://ngpd.dev03-ngs.v-env.net/demo/game.json"
            , StagingDefaultValue = "http://ngpd.dev03-ngs.v-env.net/demo/game.json")]
        public const string DemoBaseUrl = "StakeLogic.DemoBaseUrl";

        [Config(Comments = "User Name", MaxLength = 255
            , ProductionDefaultValue = "everymatrix"
            , StagingDefaultValue = "everymatrix")]
        public const string UserName = "StakeLogic.UserName";

        [Config(Comments = "Passsword", MaxLength = 255
            , ProductionDefaultValue = "everymatrix123"
            , StagingDefaultValue = "everymatrix123")]
        public const string Password = "StakeLogic.Password";

        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "StakeLogic.CELaunchInjectScriptUrl";
    }
}
