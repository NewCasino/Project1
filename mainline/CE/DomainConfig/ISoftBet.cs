namespace CE.DomainConfig
{
    public static class ISoftBet
    {
        // LicenseID
        [Config(Comments = "License ID", MaxLength = 10
            , ProductionDefaultValue = "68"
            , StagingDefaultValue = "68")]
        public const string LicenseID = "ISoftBet.LicenseID";

        // AlwaysLoadSettingsFormTargetServer
        [Config(Comments = "Always Load Settings Form Target Server (yes or no)", MaxLength = 10, AllowCountrySpecificValue = true
            , ProductionDefaultValue = "no"
            , StagingDefaultValue = "no")]
        public const string AlwaysLoadSettingsFormTargetServer = "ISoftBet.AlwaysLoadSettingsFormTargetServer";

        // TargetServer
        [Config(Comments = "Target Server", MaxLength = 512, AllowCountrySpecificValue = true
            , ProductionDefaultValue = "http://static-fun-everymatrix.isoftbet.com"
            , StagingDefaultValue = "http://static-fun-everymatrix.isoftbet.com/games")]
        public const string TargetServer = "ISoftBet.TargetServer";

        [Config(Comments = "Real Mode Target Server", MaxLength = 512, AllowCountrySpecificValue = true
            , ProductionDefaultValue = "http://static-real-everymatrix.isoftbet.com"
            , StagingDefaultValue = "http://static-real-everymatrix.isoftbet.com/games")]
        public const string RealModeTargetServer = "ISoftBet.RealModeTargetServer";

        [Config(Comments = "Lobby url", MaxLength = 512
            , ProductionDefaultValue = "https://lobby.com"
            , StagingDefaultValue = "https://lobby.com")]
        public const string LobbyUrl = "ISoftBet.LobbyUrl";
        
        // FlashGameFeedsURL
        [Config(Comments = "Flash Game Feeds URL", MaxLength = 512, AllowCountrySpecificValue = true
            , ProductionDefaultValue = "{0}/all_games_general_{1}.xml"
            , StagingDefaultValue = "{0}/all_games_general_{1}.xml")]
        public const string FlashGameFeedsURL = "ISoftBet.FlashGameFeedsURL";

        // HTML5GameFeedsURL
        [Config(Comments = "HTML5 Game Feeds URL", MaxLength = 512, AllowCountrySpecificValue = true
            , ProductionDefaultValue = "{0}/all_games_index_{1}.xml"
            , StagingDefaultValue = "{0}/all_games_index_{1}.xml")]
        public const string HTML5GameFeedsURL = "ISoftBet.HTML5GameFeedsURL";

        // GameInfoUrl
        [Config(Comments = "Game Info URL", MaxLength = 512
            , ProductionDefaultValue = "{0}/xml_game_info/{1}_info.xml"
            , StagingDefaultValue = "{0}/xml_game_info/{1}_info.xml")]
        public const string GameInfoUrl = "ISoftBet.GameInfoUrl";

        // SettingsXMLProviderUrl
        [Config(Comments = "Settings XML Provider Url", MaxLength = 512
            , ProductionDefaultValue = "{0}/{1}/xml/{2}/{3}_settings_{4}.xml"
            , StagingDefaultValue = "{0}/{1}/xml/{2}/{3}_settings_{4}.xml")]
        public const string SettingsXMLProviderUrl = "ISoftBet.SettingsXMLProviderUrl";

        // TranslationsXMLProviderUrl
        [Config(Comments = "Translations XML Provider Url", MaxLength = 512
            , ProductionDefaultValue = "{0}/{1}/xml/{2}/{3}_translations.xml"
            , StagingDefaultValue = "{0}/{1}/xml/{2}/{3}_translations.xml")]
        public const string TranslationsXMLProviderUrl = "ISoftBet.TranslationsXMLProviderUrl";

        //CELaunchUrlProtocol
        [Config(Comments = "CE Launch Url Protocol", MaxLength = 5
            , ProductionDefaultValue = "https"
            , StagingDefaultValue = "http")]
        public const string CELaunchUrlProtocol = "ISoftBet.CELaunchUrlProtocol";

        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "ISoftBet.CELaunchInjectScriptUrl";
    }
}
