
namespace CE.DomainConfig
{
    public class AsiaGaming
    {
        [Config(Comments = "Game Base URL", MaxLength = 512
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string GameBaseURL = "AsiaGaming.GameBaseURL";

        [Config(Comments = "Mobile Game Base URL", MaxLength = 512
         , ProductionDefaultValue = ""
         , StagingDefaultValue = "")]
        public const string MobileGameBaseURL = "AsiaGaming.MobileGameBaseURL";

        [Config(Comments = "Cagent secret value", MaxLength = 512
         , ProductionDefaultValue = ""
         , StagingDefaultValue = "")]
        public const string Cagent = "AsiaGaming.Cagent";

        [Config(Comments = "Md5 secret key", MaxLength = 512
          , ProductionDefaultValue = ""
          , StagingDefaultValue = "")]
        public const string Md5Key = "AsiaGaming.Md5Key";

        [Config(Comments = "Des secret key", MaxLength = 512
         , ProductionDefaultValue = ""
         , StagingDefaultValue = "")]
        public const string DesKey = "AsiaGaming.DesKey";

        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "AsiaGaming.CELaunchInjectScriptUrl";
    }
}
