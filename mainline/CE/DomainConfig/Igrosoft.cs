namespace CE.DomainConfig
{
    public static class Igrosoft
    {
        [Config(Comments = "Vendor API Url", 
            MaxLength = 255, 
            ProductionDefaultValue = "",
            StagingDefaultValue = "https://test.math-server.net:1443/icasino2/")]
        public const string VendorAPIUrl = "Igrosoft.VendorAPIUrl";

        [Config(Comments = "Merchant Id", 
            MaxLength = 255,
            ProductionDefaultValue = "",
            StagingDefaultValue = "everymatrix.com")]
        public const string MerchantId = "Igrosoft.MerchantId";

        [Config(Comments = "Salt", 
            MaxLength = 255,
            ProductionDefaultValue = "", 
            StagingDefaultValue = "CB1DF6673264704F1E9C500796C51C1E")]
        public const string Salt = "Igrosoft.Salt";
        
        [Config(Comments = "GIC End point (wallet api)", 
            MaxLength = 255,
            ProductionDefaultValue = "",
            StagingDefaultValue = "https://gamingapi-dev.gammatrix.com/gameapi/igrosoft/wallet")]
        public const string MakeTransaction = "Igrosoft.MakeTransaction";

        [Config(Comments = "CE Launch Inject Script URL", 
            MaxLength = 255,
            ProductionDefaultValue = "",
            StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "Igrosoft.CELaunchInjectScriptUrl";

    }
}
