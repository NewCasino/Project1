namespace CE.DomainConfig
{
    public static class OMI
    {
        // OMIOperatorID
        [Config(Comments = "Operator ID", MaxLength = 10
            , ProductionDefaultValue = "200"
            , StagingDefaultValue = "200")]
        public const string OperatorID = "OMI.OperatorID";


        // OMIMobileGameUrl
        [Config(Comments = "Mobile Game URL", MaxLength = 512
            , ProductionDefaultValue = "http://stage.vegasinstallation.com/games/slots/launch/{0}/{0}.html?wagerId=0&operatorId=200&domain=http://stage.vegasinstallation.com/server&detectDev=IPHONE_OR_IPAD&devOrientation=landscape/&gameId={1}&lang={2}&sessionId={3}&returnURL={4}"
            , StagingDefaultValue = "http://stage.vegasinstallation.com/games/slots/launch/{0}/{0}.html?wagerId=0&operatorId=200&domain=http://stage.vegasinstallation.com/server&detectDev=IPHONE_OR_IPAD&devOrientation=landscape/&gameId={1}&lang={2}&sessionId={3}&returnURL={4}")]
        public const string MobileGameURL = "OMI.MobileGameURL";


        // OMIPlayGameUrl
        [Config(Comments = "Casino Game URL", MaxLength = 512
            , ProductionDefaultValue = "http://stage.vegasinstallation.com/games/slots/launch/browser/{0}/browser-launcher.html?wagerId=0&operatorId=200&domain=http://stage.vegasinstallation.com/server&gameId={1}&lang={2}&sessionId={3}&returnURL="
            , StagingDefaultValue = "http://stage.vegasinstallation.com/games/slots/launch/browser/{0}/browser-launcher.html?wagerId=0&operatorId=200&domain=http://stage.vegasinstallation.com/server&gameId={1}&lang={2}&sessionId={3}&returnURL=")]
        public const string CasinoGameURL = "OMI.CasinoGameURL";


        //CELaunchUrlProtocol
        [Config(Comments = "CE Launch Url Protocol", MaxLength = 5
            , ProductionDefaultValue = "https"
            , StagingDefaultValue = "http")]
        public const string CELaunchUrlProtocol = "OMI.CELaunchUrlProtocol";


        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "OMI.CELaunchInjectScriptUrl";
    }
}
