namespace CE.DomainConfig
{
    public class Multislot
    {
        [Config(Comments = "Game Base URL Login", MaxLength = 512
            , ProductionDefaultValue = "http://81.88.163.2/EMatrixDev/Games/aspNET/ChipTransfer/WSLogin.aspx"
            , StagingDefaultValue = "http://81.88.163.2/EMatrixDev/Games/aspNET/ChipTransfer/WSLogin.aspx")]
        public const string GameTokenBaseURL = "Multislot.GameTokenBaseURL";
        
        [Config(Comments = "Game Base URL Token", MaxLength = 512
            , ProductionDefaultValue = "http://81.88.163.2/EMatrixDev/Games/aspNET/launch/enter.aspx"
            , StagingDefaultValue = "http://81.88.163.2/EMatrixDev/Games/aspNET/launch/enter.aspx")]
        public const string GameLaunchBaseURL = "Multislot.GameLaunchBaseURL";

        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "Multislot.CELaunchInjectScriptUrl";

        [Config(Comments = "Provider", MaxLength = 512
            , ProductionDefaultValue = "EMATRIX"
            , StagingDefaultValue = "EMATRIX")]
        public const string Provider = "Multislot.Provider";
    }
}
