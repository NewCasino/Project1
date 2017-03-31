namespace CE.DomainConfig
{
    public class Yggdrasil
    {
        //https://staticstagingcw.yggdrasilgaming.com/init/launchClient.html?gameid=7301&lang=sv&currency=EUR&channel=pc&org=zzz&key=xxx (production version)
        /// In Yggdrasil Live environment Play For Real money traffic is placed on the dedicated
        /// Production environment whilst Play For Free-traffic is placed on the separate environment,
        /// so:
        /// PFR is lauched from: https://staticlivecw.yggdrasilgaming.com/init/launchClient.html...
        /// PFF is lauched from: https://staticpff.yggdrasilgaming.com/init/launchClient.html...

        [Config(Comments = "Game Base URL", MaxLength = 512, AllowCountrySpecificValue = true
            , ProductionDefaultValue = "https://staticlivecw.yggdrasilgaming.com/init/launchClient.html"
            , StagingDefaultValue = "https://staticstagingcw.yggdrasilgaming.com/init/launchClient.html")]
        public const string GameBaseURL = "Yggdrasil.GameBaseURL";

        [Config(Comments = "FunMode Game Base URL", MaxLength = 512, AllowCountrySpecificValue = true
            , ProductionDefaultValue = "https://staticpff.yggdrasilgaming.com/init/launchClient.html"
            , StagingDefaultValue = "https://staticpff.yggdrasilgaming.com/init/launchClient.html")]
        public const string FunModeGameBaseURL = "Yggdrasil.GameBasePlayForFreeURL";

        //CELaunchUrlProtocol
        [Config(Comments = "CE Launch Url Protocol", MaxLength = 5
            , ProductionDefaultValue = "https"
            , StagingDefaultValue = "http")]
        public const string CELaunchUrlProtocol = "Yggdrasil.CELaunchUrlProtocol";

        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "Yggdrasil.CELaunchInjectScriptUrl";

    }
}
