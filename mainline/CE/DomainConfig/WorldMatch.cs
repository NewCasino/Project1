namespace CE.DomainConfig
{
    public class WorldMatch
    {
        //Fun Mode        //https://{server_name}/games/{launch_mode}/{licensee_id}/{game_id}/{configuration_id}/?language={language_code}&age={age_flag}
        //https://casino.wmdev.eu/games/free/123/456/789/?language=EN&age=false

        //Real Mode        //https://{server_name}/games/real/{licensee_id}/{game_id}/{configuration_id}/?authuser={auth_user}&authkey={auth_key}&authskin={auth_skin}&language={language_code}&age={age_flag}        //https://casino.wmdev.eu/games/real/123/456/789/?authuser=12345678&authkey=1234567890&authskin=DEMO&language=EN&age=false

        //language_code - ISO 639-1 code


        [Config(Comments = "Game Base URL", MaxLength = 512
            , ProductionDefaultValue = "https://casino.worldmatch.eu/games/"
            , StagingDefaultValue = "https://casino.wmdev.eu/games/")]
        public const string GameBaseURL = "WorldMatch.GameBaseURL";

        [Config(Comments = "Show Age Warning for Games", MaxLength = 512
            , ProductionDefaultValue = "false"
            , StagingDefaultValue = "false")]
        public const string ShowAgeWarning = "WorldMatch.ShowAgeWarning";

        //CELaunchUrlProtocol
        [Config(Comments = "CE Launch Url Protocol", MaxLength = 5
            , ProductionDefaultValue = "https"
            , StagingDefaultValue = "http")]
        public const string CELaunchUrlProtocol = "WorldMatch.CELaunchUrlProtocol";

        //CELaunchInjectScriptUrl
        [Config(Comments = "CE Launch Inject Script URL", MaxLength = 255
            , ProductionDefaultValue = ""
            , StagingDefaultValue = "")]
        public const string CELaunchInjectScriptUrl = "WorldMatch.CELaunchInjectScriptUrl";

    }
}
