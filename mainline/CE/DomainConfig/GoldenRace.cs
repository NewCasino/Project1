namespace CE.DomainConfig
{
    public static class GoldenRace
    {
        // Game configs
        [Config(Comments = "Game Base Url for virtual games", MaxLength = 512, ProductionDefaultValue = "", StagingDefaultValue = "http://test-online.golden-race.net/web/themes/_base/")]
        public const string VirtualGameBaseUrl = "GoldenRace.VirtualGameBaseUrl";

        [Config(Comments = "Game Base Url for casino games", MaxLength = 512, ProductionDefaultValue = "", StagingDefaultValue = "http://test-online.golden-race.net/cashier/tablet.html/")]
        public const string CasinoGameBaseUrl = "GoldenRace.CasinoGameBaseUrl";

        [Config(Comments = "Special parameter to run game in Demo mode", MaxLength = 64, ProductionDefaultValue = "", StagingDefaultValue = "f7e64a43-ea88-4f1b-bd13-8432031d6396")]
        public const string DemoGameModeValue = "GoldenRace.DemoGameModeValue";

        [Config(Comments = "GameId for Virtual game", MaxLength = 64, ProductionDefaultValue = "", StagingDefaultValue = "virtual")]
        public const string VirtualGameId = "GoldenRace.VirtualGameId";

        [Config(Comments = "Time in minutes to elapse between events is Casino or Keno games. From 2 to 9.", MaxLength = 1, ProductionDefaultValue = "", StagingDefaultValue = "3")]
        public const string CasinoGameCountdown = "GoldenRace.CasinoGameCountdown";

        [Config(Comments = "Additional parameters to launch virtual games in format p1=xx&p2=yy", MaxLength = 256, ProductionDefaultValue = "", StagingDefaultValue = "")]
        public const string VirtualsAdditionalLaunchParameters = "GoldenRace.VirtualsAdditionalLaunchParameters";

        // CE
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255, ProductionDefaultValue = "", StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "GoldenRace.CELaunchInjectScriptUrl";
    }
}
