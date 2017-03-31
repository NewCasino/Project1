namespace CE.DomainConfig
{
    public class Spigo
    {
        [Config(Comments = "Enabled Live or Stage('Live - 1' or 'Stage - 0')", MaxLength = 1
            , ProductionDefaultValue = "1"
            , StagingDefaultValue = "0")]
        public const string IsLive = "Spigo.Live";

        [Config(Comments = "Spigo site ID", MaxLength = 20
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string SiteID = "Spigo.SiteID";

        [Config(Comments = "Game Base URL", MaxLength = 512
            , ProductionDefaultValue = "https://api.spigoworld.com/"
            , StagingDefaultValue = "https://stagingapi.spigoworld.com/")]
        public const string GameBaseURL = "Spigo.GameBaseURL";

        //CELaunchUrlProtocol
        [Config(Comments = "CE Launch Url Protocol", MaxLength = 5
            , ProductionDefaultValue = "https"
            , StagingDefaultValue = "http")]
        public const string CELaunchUrlProtocol = "Spigo.CELaunchUrlProtocol";
    }
}
