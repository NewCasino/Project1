namespace CE.DomainConfig
{
    public static class EGT
    {
        // EGTPlayGameBaseUrl
        [Config(Comments = "Game Base URL", MaxLength = 512
            , ProductionDefaultValue = "http://s3.egtmgs.com:8080/core-web-war/MGL"
            , StagingDefaultValue = "http://s3.egtmgs.com:8080/core-web-war/MGL")]
        public const string GameBaseURL = "EGT.GameBaseURL";

        // EGTFunModeGameBaseURL
        [Config(Comments = "Fun Mode Game Base URL", MaxLength = 512
            , ProductionDefaultValue = "https://free.egtmgs.com/everymatrix.php"
            , StagingDefaultValue = "https://free.egtmgs.com/everymatrix.php")]
        public const string FunModeGameBaseURL = "EGT.FunModeGameBaseURL";


        // EGTFunModeMobileGameBaseURL
        [Config(Comments = "Fun Mode Game Base URL", MaxLength = 512
            , ProductionDefaultValue = "https://free.egtmgs.com/mobile/StartGame.html"
            , StagingDefaultValue = "https://free.egtmgs.com/mobile/StartGame.html")]
        public const string FunModeMobileGameBaseURL = "EGT.FunModeMobileGameBaseURL";

        // EGTOperatorID
        [Config(Comments = "Operator ID", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string OperatorID = "EGT.OperatorID";

        //// EGTCasinoCode
        //[ConfigAttribute(Comments = "Casino Code", MaxLength = 255
        //    , ProductionDefaultValue = "EveryMatrix"
        //    , StagingDefaultValue = "EveryMatrix")]
        //public const string CasinoCode = "EGT.CasinoCode";

        //// EGTPortalName
        //[ConfigAttribute(Comments = "Portal Name", MaxLength = 255
        //    , ProductionDefaultValue = "EveryMatrix"
        //    , StagingDefaultValue = "EveryMatrix")]
        //public const string PortalName = "EGT.PortalName";


        //// EGTScreenName
        //[ConfigAttribute(Comments = "Screen Name", MaxLength = 255
        //    , ProductionDefaultValue = "dervish"
        //    , StagingDefaultValue = "dervish")]
        //public const string ScreenName = "EGT.ScreenName";
    }
}
