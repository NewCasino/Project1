namespace CE.DomainConfig
{
    public static class Globalbet
    {
        // GlobalbetPlayGameBaseUrl
        [Config(Comments = "Game Base URL", MaxLength = 512
            , ProductionDefaultValue = "https://everymatrix-test.globalbet.com/engine/web/autologin/account?code={0}&webRedirectTo=/client/vspro.jsp%3Flocale=en_US&casino=vspro"
            , StagingDefaultValue = "https://everymatrix-test.globalbet.com/engine/web/autologin/account?code={0}&webRedirectTo=/client/vspro.jsp%3Flocale=en_US&casino=vspro")]
        public const string GameBaseURL = "Globalbet.GameBaseURL";

        // GlobalbetPlayGameBaseUrl mobile
        [Config(Comments = "Game Base Mobile URL", MaxLength = 512
            , ProductionDefaultValue = "https://everymatrix-test.globalbet.com/engine/web/autologin/account?code={0}&webRedirectTo=/client/vspro-headless.jsp%3Fembed=true"
            , StagingDefaultValue = "https://everymatrix-test.globalbet.com/engine/web/autologin/account?code={0}&webRedirectTo=/client/vspro-headless.jsp%3Fembed=true")]
        public const string FunModeGameBaseURL = "Globalbet.FunModeGameBaseURL";

        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "Globalbet.CELaunchInjectScriptUrl";

        //GlobalBetEasyXDMScriptUrl
        [Config(Comments = "EasyXDMS Script URL", MaxLength = 255
            , ProductionDefaultValue = "https://virtualsports-test3.globalbet.com/client/easyXDM.min.js"
            , StagingDefaultValue = "https://virtualsports-test3.globalbet.com/client/easyXDM.min.js")]
        public const string EasyXDMScriptUrl = "Globalbet.EasyXDMScriptUrl";

        //GlobalBetWidgetIntegrationScriptUrl
        [Config(Comments = "Widget Integration Script URL", MaxLength = 255
            , ProductionDefaultValue = "https://virtualsports-test3.globalbet.com/client/widgetIntegration.js"
            , StagingDefaultValue = "https://virtualsports-test3.globalbet.com/client/widgetIntegration.js")]
        public const string WidgetIntegrationScriptUrl = "Globalbet.WidgetIntegrationScriptUrl";        
    }
}
