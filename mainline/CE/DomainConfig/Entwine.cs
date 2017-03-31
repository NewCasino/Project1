namespace CE.DomainConfig
{
    public static class Entwine
    {
        // EntwineDesktopGameBaseUrl
        [Config(Comments = "Live Casino Game URL", MaxLength = 512
            , ProductionDefaultValue = "https://entwine.casinoeverymatrix.com/"
            , StagingDefaultValue = "http://entwine.casinodeveverymatrix.com/")]
        public const string DesktopGameBaseUrl = "Entwine.DesktopGameBaseUrl";

        //EntwineMobileGameBaseUrl
        [Config(Comments = "Live Casino Mobile Game URL", MaxLength = 512
            , ProductionDefaultValue = "https://entwine-mob.casinoeverymatrix.com/"
            , StagingDefaultValue = "http://entwine-mob.casinodeveverymatrix.com/")]
        public const string MobileGameBaseUrl = "Entwine.MobileGameBaseUrl";

        //EntwineMerchantCode
        [Config(Comments = "Entwine Merchant Code", MaxLength = 512
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "IDN")]
        public const string MerchantCode = "Entwine.MerchantCode";

        //CELaunchUrlProtocol
        [Config(Comments = "CE Launch Url Protocol", MaxLength = 5
            , ProductionDefaultValue = "https"
            , StagingDefaultValue = "http")]
        public const string CELaunchUrlProtocol = "Entwine.CELaunchUrlProtocol";

        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "Entwine.CELaunchInjectScriptUrl";

        
    }
}
