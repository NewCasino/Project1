namespace CE.DomainConfig
{
    public class XProGaming
    {
        [Config(Comments = "Mini Lobby Base URL", MaxLength = 512
            , ProductionDefaultValue = "http://livegames.xpgnet.net/lobby.aspx?operatorId={0}&token={1}&LanguageID={2}"
            , StagingDefaultValue = "http://livegames.xpgnet.net/lobby.aspx?operatorId={0}&token={1}&LanguageID={2}")]
        public const string MiniLobbyBaseURL = "XProGaming.MiniLobbyBaseURL";

        [Config(Comments = "Live Casino - Show Mini Lobby ( true or false )", MaxLength = 5
            , ProductionDefaultValue = "false"
            , StagingDefaultValue = "false")]
        public const string LiveCasinoShowMiniLobby = "XProGaming.LiveCasinoShowMiniLobby";
    }
}
