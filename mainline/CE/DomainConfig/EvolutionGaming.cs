namespace CE.DomainConfig
{
    public static class EvolutionGaming
    {
        // EvolutionSkin
        [Config(Comments = "Skin", MaxLength = 10
            , ProductionDefaultValue = "-1"
            , StagingDefaultValue = "-1")]
        public const string Skin = "EvolutionGaming.Skin";


        //CELaunchUrlProtocol
        [Config(Comments = "CE Launch Url Protocol", MaxLength = 5
            , ProductionDefaultValue = "https"
            , StagingDefaultValue = "http")]
        public const string CELaunchUrlProtocol = "EvolutionGaming.CELaunchUrlProtocol";



        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "EvolutionGaming.CELaunchInjectScriptUrl";

        //Go Back to Mobile Lobby Url
        [Config(Comments = "Go Back to Mobile Lobby Url", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELiveCasinoMobileLobbyUrl = "EvolutionGaming.CELiveCasinoMobileLobbyUrl";


    }
}
