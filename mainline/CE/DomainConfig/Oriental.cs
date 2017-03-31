namespace CE.DomainConfig
{
    public static class Oriental
    {
        [Config(Comments = "Agent", MaxLength = 100
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string Agent = "Oriental.Agent";

        [Config(Comments = "Agent Key", MaxLength = 100
        , ProductionDefaultValue = ""
        , StagingDefaultValue = "")]
        public const string AgentKey = "Oriental.AgentKey";


        [Config(Comments = "Mobile Game URL", MaxLength = 512
            , ProductionDefaultValue = "http://cashapi.673ing.com/cashapi/DoBusiness.aspx"
            , StagingDefaultValue = "http://cashapi.673ing.com/cashapi/DoBusiness.aspx")]
        public const string MobileGameURL = "Oriental.MobileGameURL";


        [Config(Comments = "Casino Game URL", MaxLength = 512
            , ProductionDefaultValue = "http://cashapi.673ing.com/cashapi/DoBusiness.aspx"
            , StagingDefaultValue = "http://cashapi.673ing.com/cashapi/DoBusiness.aspx")]
        public const string CasinoGameURL = "Oriental.CasinoGameURL";      


        [Config(Comments = "CE Launch Url Protocol", MaxLength = 5
            , ProductionDefaultValue = "https"
            , StagingDefaultValue = "http")]
        public const string CELaunchUrlProtocol = "Oriental.CELaunchUrlProtocol";


        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "Oriental.CELaunchInjectScriptUrl";
    }
}
