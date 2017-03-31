namespace CE.DomainConfig
{
    public static class Odobo
    {
        // OdoboPlayRealGameUrl
        [Config(Comments = "Casino Game Real Money Mode URL", MaxLength = 512
            , ProductionDefaultValue = "https://gcds.odobo.co/rest/{0}/{1}?sessionid={2}&language={3}"
            , StagingDefaultValue = "https://gcds.odobo.co/rest/{0}/{1}?sessionid={2}&language={3}")]
        public const string CasinoGameRealMoneyModeURL = "Odobo.CasinoGameRealMoneyModeURL";

        // OdoboPlayFunGameUrl
        [Config(Comments = "Casino Game Fun Mode URL", MaxLength = 512
            , ProductionDefaultValue = "http://gl.odobo.co/{2}?gameId={0}&lang={1}&fun=true"
            , StagingDefaultValue = "http://gl.odobo.co/{2}?gameId={0}&lang={1}&fun=true")]
        public const string CasinoGameFunModeURL = "Odobo.CasinoGameFunModeURL";

        // CELaunchUrlProtocol
        [Config(Comments = "CE Launch Url Protocol", MaxLength = 5
            , ProductionDefaultValue = "https"
            , StagingDefaultValue = "http")]
        public const string CELaunchUrlProtocol = "Odobo.CELaunchUrlProtocol";

        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "Odobo.CELaunchInjectScriptUrl";

        //CEOperatorEnvirement
        [Config(Comments = "CE Operator Envirement", MaxLength = 255
            , ProductionDefaultValue = "15001"
            , StagingDefaultValue = "15001")]
        public const string CEOperatorEnvirement = "Odobo.CEOperatorEnvirement";

        //CEStaticString
        [Config(Comments = "CE Static String", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CEStaticString = "Odobo.CEStaticString";
    }
}
