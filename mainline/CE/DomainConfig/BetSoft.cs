namespace CE.DomainConfig
{
    public static class BetSoft
    {
        // BetSoftBankId
        [Config(Comments = "Bank ID", MaxLength = 10
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "218")]
        public const string BankID = "BetSoft.BankID";

        // BetSoftPlayFunGameUrl
        [Config(Comments = "Casino Game Fun Mode URL", MaxLength = 512
            , ProductionDefaultValue = "http://lobby.everymatrix.betsoftgaming.com/cwguestlogin.do?bankId={0}&gameId={1}&lang={2}"
            , StagingDefaultValue = "http://lobby.everymatrix.discreetgaming.com/cwguestlogin.do?bankId={0}&gameId={1}&lang={2}")]
        public const string CasinoGameFunModeURL = "BetSoft.CasinoGameFunModeURL";

        // BetSoftPlayRealGameUrl
        [Config(Comments = "Casino Game Real Money Mode URL", MaxLength = 512
            , ProductionDefaultValue = "http://lobby.everymatrix.betsoftgaming.com/cwstartgamev2.do?bankId={0}&gameId={1}&lang={2}&mode=real&token={3}"
            , StagingDefaultValue = "http://lobby.everymatrix.discreetgaming.com/cwstartgamev2.do?bankId={0}&gameId={1}&lang={2}&mode=real&token={3}")]
        public const string CasinoGameRealMoneyModeURL = "BetSoft.CasinoGameRealMoneyModeURL";

        // BetSoftGameListUrl
        [Config(Comments = "Casino Game List URL", MaxLength = 512
            , ProductionDefaultValue = "http://lobby.everymatrix.betsoftgaming.com/gamelist.do?bankId={0}"
            , StagingDefaultValue = "http://lobby.everymatrix.discreetgaming.com/gamelist.do?bankId={0}")]
        public const string CasinoGameListURL = "BetSoft.CasinoGameListURL";


        // CELaunchUrlProtocol
        [Config(Comments = "CE Launch Url Protocol", MaxLength = 5
            , ProductionDefaultValue = "https"
            , StagingDefaultValue = "http")]
        public const string CELaunchUrlProtocol = "BetSoft.CELaunchUrlProtocol";

        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "BetSoft.CELaunchInjectScriptUrl";
    }
}
