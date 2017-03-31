namespace CE.DomainConfig
{
    public static class PokerKlas
    {
        [Config(Comments = "Vendor API Url", MaxLength = 255
            , ProductionDefaultValue = "", StagingDefaultValue = "http://api.testpoker.klasgaming.com/")]
        public const string VendorAPIUrl = "PokerKlas.VendorAPIUrl";

        [Config(Comments = "API merchant login", MaxLength = 255
            , ProductionDefaultValue = "", StagingDefaultValue = "206")]
        public const string APIMerchantLogin = "PokerKlas.APIMerchantLogin";

        [Config(Comments = "API private key", MaxLength = 255
            , ProductionDefaultValue = "", StagingDefaultValue = "n7o942dprc_9f2g9p4")]
        public const string APIPrivateKey = "PokerKlas.APIPrivateKey";

        //CELaunchUrlProtocol
        [Config(Comments = "CE Launch Url Protocol", MaxLength = 5
            , ProductionDefaultValue = "https"
            , StagingDefaultValue = "http")]
        public const string CELaunchUrlProtocol = "PokerKlas.CELaunchUrlProtocol";
    }
}
