namespace CE.DomainConfig
{
    public static class CTXM
    {
        // CTXMPlayGameBaseUrl
        [Config(Comments = "Casino Game URL", MaxLength = 512
            , ProductionDefaultValue = "http://alba2.ctxm.com/whl_lobby/game.do?merch_id=DOMAINNAME"
            , StagingDefaultValue = "http://alba2.ctxm.com/whl_lobby/game.do?merch_id=DOMAINNAME")]
        public const string CasinoGameBaseURL = "CTXM.CasinoGameURL";


        //CELaunchUrlProtocol
        [Config(Comments = "CE Launch Url Protocol", MaxLength = 5
            , ProductionDefaultValue = "https"
            , StagingDefaultValue = "http")]
        public const string CELaunchUrlProtocol = "CTXM.CELaunchUrlProtocol";


        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "CTXM.CELaunchInjectScriptUrl";


    }
}
