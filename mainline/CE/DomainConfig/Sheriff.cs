namespace CE.DomainConfig
{
    public static class Sheriff
    {
        // SheriffPlayGameBaseUrl
        [Config(Comments = "Casino Game URL", MaxLength = 512
            , ProductionDefaultValue = "https://games.sheriffgaming.com/loader/?site_id=4&locale={0}&game_id={1}&mode={2}&player_reference={3}&currency={4}&session_id={5}"
            , StagingDefaultValue = "http://games.sheriffgaming.com/loader/?site_id=4&locale={0}&game_id={1}&mode={2}&player_reference={3}&currency={4}&session_id={5}")]
        public const string CasinoGameURL = "Sheriff.CasinoGameURL";

        // SheriffJackpotJsonUrl
        [Config(Comments = "Jackpot JSON URL", MaxLength = 512
            , ProductionDefaultValue = "http://jetbull.nl1.gamingclient.com/jackpot/retrieve/{0}"
            , StagingDefaultValue = "http://jetbull.nl1.gamingclient.com/jackpot/retrieve/{0}")]
        public const string JackpotJsonURL = "Sheriff.JackpotJsonURL";

        //CELaunchUrlProtocol
        [Config(Comments = "CE Launch Url Protocol", MaxLength = 5
            , ProductionDefaultValue = "https"
            , StagingDefaultValue = "http")]
        public const string CELaunchUrlProtocol = "Sheriff.CELaunchUrlProtocol";


        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "Sheriff.CELaunchInjectScriptUrl";

    }
}
