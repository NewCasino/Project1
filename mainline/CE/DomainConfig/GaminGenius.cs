namespace CE.DomainConfig
{
    public static class GaminGenius
    {
        [Config(Comments = "Vendor API Url", 
            MaxLength = 255, 
            ProductionDefaultValue = "",
            StagingDefaultValue = "http://gamesdemo.gamingenius.com/")]
        public const string VendorAPIUrl = "GaminGenius.VendorAPIUrl";

        [Config(Comments = "Customer Id", 
            MaxLength = 255,
            ProductionDefaultValue = "",
            StagingDefaultValue = "EMTX")]
        public const string CustomerId = "GaminGenius.CustomerId";

        [Config(Comments = "Gaming Server URL", 
            MaxLength = 255,
            ProductionDefaultValue = "",
            StagingDefaultValue = "https://rgsstage.gamingenius.com")]
        public const string GamingServerURL = "GaminGenius.GamingServerURL";

        [Config(Comments = "CE Launch Inject Script URL", 
            MaxLength = 255,
            ProductionDefaultValue = "",
            StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "GaminGenius.CELaunchInjectScriptUrl";

        //CELaunchUrlProtocol
        [Config(Comments = "CE Launch Url Protocol", MaxLength = 5
            , ProductionDefaultValue = "https"
            , StagingDefaultValue = "http")]
        public const string CELaunchUrlProtocol = "GaminGenius.CELaunchUrlProtocol";

    }
}
