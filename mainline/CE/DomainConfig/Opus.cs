namespace CE.DomainConfig
{
    public class Opus
    {
        [Config(Comments = "Game Base URL", MaxLength = 512
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string GameBaseURL = "Opus.GameBaseURL";

        [Config(Comments = "Game Domain", MaxLength = 512
           , ProductionDefaultValue = ""
           , StagingDefaultValue = "")]
        public const string GameDomain = "Opus.GameDomain";

        [Config(Comments = "SubVendor GameOS Launch part", MaxLength = 512
           , ProductionDefaultValue = "/GameLoader.aspx?gameID={0}&gamePlay={1}"
           , StagingDefaultValue = "/GameLoader.aspx?gameID={0}&gamePlay={1}")]
        public const string SubVendorGameOSLaunchPart = "Opus.SubVendorGameOSLaunchPart";

        [Config(Comments = "SubVendor GameOS Mobile Launch part", MaxLength = 512
       , ProductionDefaultValue = "/GameloaderCTXMMobile.aspx?gameID={0}&gameplay={1}"
       , StagingDefaultValue = "/GameloaderCTXMMobile.aspx?gameID={0}&gameplay={1}")]
        public const string SubVendorGameOSMobileLaunchPart = "Opus.SubVendorGameOSMobileLaunchPart";

        [Config(Comments = "SubVendor Pragmatic Launch part", MaxLength = 512
           , ProductionDefaultValue = "/GameLoaderPP.aspx?gid={0}&gamePlay={1}"
           , StagingDefaultValue = "/GameLoaderPP.aspx?gid={0}&gamePlay={1}")]
        public const string SubVendorPragmaticLaunchPart = "Opus.SubVendorPragmaticLaunchPart";

        [Config(Comments = "SubVendor MG Launch part", MaxLength = 512
           , ProductionDefaultValue = "/gameloaderHB1.aspx?gid={0}&gameplay={1}"
           , StagingDefaultValue = "/gameloaderHB1.aspx?gid={0}&gameplay={1}")]
        public const string SubVendorMGLaunchPart = "Opus.SubVendorMGLaunchPart";

        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "Opus.CELaunchInjectScriptUrl";
    }
}
