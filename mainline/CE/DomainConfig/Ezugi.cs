namespace CE.DomainConfig
{
    public static class Ezugi
    {
        // EzugiPlayGameBaseUrl
        [Config(Comments = "Live Casino Game URL", MaxLength = 512
            , ProductionDefaultValue = "https://lobby-int.ezugi.com/game/auth/"
            , StagingDefaultValue = "https://lobby-int.ezugi.com/game/auth/")]
        public const string LiveCasinoBaseUrl = "Ezugi.LiveCasinoBaseUrl";        

        //CELaunchUrlProtocol
        [Config(Comments = "CE Launch Url Protocol", MaxLength = 5
            , ProductionDefaultValue = "https"
            , StagingDefaultValue = "http")]
        public const string CELaunchUrlProtocol = "Ezugi.CELaunchUrlProtocol";


        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "Ezugi.CELaunchInjectScriptUrl";


        //CEShowLiveLobby
        [Config(Comments = "Show Live Lobby(true/false)", MaxLength = 512
            , ProductionDefaultValue = "false"
            , StagingDefaultValue = "false")]
        public const string ShowLiveLobby = "Ezugi.ShowLiveLobby";
    }
}
