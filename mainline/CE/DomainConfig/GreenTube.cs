namespace CE.DomainConfig
{
    public static class GreenTube
    {
        //FlashLoaderUrl http:\/\/static.energycasino.com/GameLoader/loader.swf
        [Config(Comments = "Flash Loader Url", MaxLength = 255
            , ProductionDefaultValue = "" , StagingDefaultValue = "")]
        public const string FlashLoaderUrl = "GreenTube.FlashLoaderUrl";

        // GameLoaderJavascriptUrl http:\/\/static.energycasino.com/GameLoader/game_loader.js
        [Config(Comments = "Game loader javascript Url", MaxLength = 255
            , ProductionDefaultValue = "", StagingDefaultValue = "")]
        public const string GameLoaderJavascriptUrl = "GreenTube.GameLoaderJavascriptUrl";

        [Config(Comments = "Vendor API Url", MaxLength = 255
            , ProductionDefaultValue = "", StagingDefaultValue = "https://gg-nrgs-b2b-staging.greentube.com/Nrgs/B2B/Service/Storm/V5/{0}/Games/{1}/Sessions/PresentationURL?Protocol={2}")]
        public const string VendorAPIUrl = "GreenTube.VendorAPIUrl";

        [Config(Comments = "API public key", MaxLength = 255
            , ProductionDefaultValue = "", StagingDefaultValue = "storm.uk.b2b.casino")]
        public const string APIPublicKey = "GreenTube.APIPublicKey";

        [Config(Comments = "API secret key", MaxLength = 255
            , ProductionDefaultValue = "", StagingDefaultValue = "98D1EA52-C662-49A0-B3AE-6B4C3C53B1F6")]
        public const string APISecretKey = "GreenTube.APISecretKey";

        //CELaunchUrlProtocol
        [Config(Comments = "CE Launch Url Protocol", MaxLength = 5
            , ProductionDefaultValue = "https"
            , StagingDefaultValue = "http")]
        public const string CELaunchUrlProtocol = "GreenTube.CELaunchUrlProtocol";



        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "GreenTube.CELaunchInjectScriptUrl";



    }
}
