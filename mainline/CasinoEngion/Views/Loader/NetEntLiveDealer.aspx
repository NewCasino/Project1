<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="CE.db" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script language="C#" type="text/C#" runat="server">
    private string StaticServer { get; set; }
    private string GameServer { get; set; }
    private string CasinoBrand { get; set; }
    private string SessionID { get; set; }
    protected int RealityCheckTimeout { get; set; }
    protected string ShowLiveLobby { get; set; }

    protected string LobbyUrl;

    private StringBuilder ConfigString { get; set; }

    private int InitialWidth { get; set; }
    private int InitialHeight { get; set; }

    public override string GetLanguage(string lang)
    {
        //ConvertToISO639
        if (string.IsNullOrWhiteSpace(lang))
            return "en";

        switch (lang.Truncate(2).ToLowerInvariant())
        {
            case "he": return "iw";
            case "ka": return "en";
            case "ko": return "en";
            case "ja": return "en";
            case "bg": return "en";
            case "zh": return "en";
            default:  return lang.ToLowerInvariant();
        }
    }

    public string CreateNetEntSessionID()
    {
        if (UseGmGaming)
        {
            var response = GetToken();
            RealityCheckTimeout = 60; // dummy value, just for testing.
            if ((response.AdditionalParameters != null) && response.AdditionalParameters.Exists(a => a.Name == "RealityCheckSec"))
            {
                RealityCheckTimeout = int.Parse(response.AdditionalParameters.First(a => a.Name == "RealityCheckSec").Value);
            }
            return response.TokenKey;
        }
        using (var client = new GamMatrixClient())
        {
            var request = new NetEntAPIRequest
            {
                LoginUserDetailedCache = true,
                UserID = UserSession.UserID
            };
            request = client.SingleRequest(UserSession.DomainID, request);
            LogGmClientRequest(request.SESSION_ID, request.LoginUserDetailedCacheResponse, "sID");
            return request.LoginUserDetailedCacheResponse;
        }
    }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        Process();
    }

    private void Process()
    {
        if ((UserSession == null) || FunMode)
        {
            throw new CeException("NetEnt Live Casino is only available in real money mode!");
        }

        //this.DisableAudio = string.Equals(Request.QueryString["disableAudio"], "true", StringComparison.OrdinalIgnoreCase);
        //HelpUrl = Url.RouteUrl("Loader", new { Action = "Help", domainID = Domain.DomainID, id = this.Model.Slug, language = this.Language });

        GameServer = Domain.GetCfg(NetEnt.LiveCasinoGameApiBaseURL);
        StaticServer = Domain.GetCfg(NetEnt.LiveCasinoGameHostBaseURL);
        CasinoBrand = Domain.GetCfg(NetEnt.LiveCasinoBrand);
        ShowLiveLobby = Domain.GetCfg(NetEnt.LiveCasinoShowMiniLobby);
        

        var tables = CacheManager.GetLiveCasinoTableDictionary(Domain.DomainID);
        ceLiveCasinoTableBaseEx table;
        if (!tables.TryGetValue(TableID, out table))
            throw new CeException("Invalid table id [{0}]", TableID);


        if ((UserSession != null) && !FunMode)
        {
            SessionID = CreateNetEntSessionID();
        }

        if (Model.Width > 0)
            InitialWidth = Model.Width;
        if (Model.Height > 0)
            InitialHeight = Model.Height;

        ConfigString = new StringBuilder();
        ConfigString.Append("{");

        if ((UserSession != null) && !FunMode && PlatformHandler.IsMobile) // solution for mobile reality check
        {
            var pluginConfigUrl = Url.RouteUrl("Loader", new
            {
                action = "RealityCheckConfig",
                domainID = Model.DomainID,
                id = ((int) VendorID.NetEnt).ToString(),
                realityCheckTimeout = RealityCheckTimeout
            });

            if (RealityCheckTimeout > 0)
            {
                pluginConfigUrl = string.Format("{0}://{1}{2}", "https", "casino.gm.dev.everymatrix.com", pluginConfigUrl);
                ConfigString.AppendLine(string.Format("'pluginUrl': '{0}', ", pluginConfigUrl.SafeJavascriptStringEncode()));
            }

            var liveCasinoHost = new Uri(Domain.GetCfg(NetEnt.LiveCasinoGameApiBaseURL));
            ConfigString.AppendLine(string.Format("'liveCasinoHost': '{0}', ", liveCasinoHost.Host.SafeJavascriptStringEncode()));

            GameServer = Domain.GetCfg(NetEnt.GameRulesBaseURL);
        }


        if (ShowLiveLobby != "true")
        {
            ConfigString.AppendLine(string.Format("'gameId': '{0}', ", table.GameID));
            ConfigString.AppendLine(string.Format("'tableId': '{0}', ", table.ExtraParameter1));
        }
        else
        {
            ConfigString.AppendLine(string.Format("'gameId': '{0}', ", "lobby"));
        }

        ConfigString.AppendLine(string.Format("'staticServer': '{0}', ", StaticServer.SafeJavascriptStringEncode()));
        ConfigString.AppendLine(string.Format("'gameServerURL': '{0}', ", GameServer.SafeJavascriptStringEncode()));
        ConfigString.AppendLine(string.Format("'sessionId': '{0}', ", SessionID.SafeJavascriptStringEncode()));
        ConfigString.AppendLine(string.Format("'language': '{0}', ", Language.SafeJavascriptStringEncode()));
        ConfigString.AppendLine(string.Format("'operatorId': '{0}', ", Domain.GetCfg(NetEnt.LiveCasinoID)));

        var lobbyUrlResolver = Url.RouteUrl("Loader", new
        {
            action = "LobbyResolver",
            domainID = Model.DomainID,
            id = ((int) VendorID.NetEnt).ToString()
        });
        lobbyUrlResolver = string.Format("{0}://{1}{2}", "https", Domain.GameLoaderDomain, lobbyUrlResolver);
        LobbyUrl = lobbyUrlResolver;

        //casinoBrand
        //if (!string.IsNullOrWhiteSpace(this.CasinoBrand))
        //    ConfigString.AppendLine(string.Format("'casinoBrand': '{0}', ", this.CasinoBrand.SafeJavascriptStringEncode()));

        ConfigString.AppendLine(string.Format("'lobbyUrl': '{0}' ", lobbyUrlResolver.SafeJavascriptStringEncode()));

        ConfigString.AppendLine("}");
    }

</script>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="<%= Language %>">
<head>
    <title><%= Model.GameName.SafeHtmlEncode() %></title>
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1"/>
    <meta name="keywords" content="<%= Model.Tags.SafeHtmlEncode() %>"/>
    <meta name="description" content="<%= Model.Description.SafeHtmlEncode() %>"/>
    <meta http-equiv="pragma" content="no-cache"/>
    <meta http-equiv="content-language" content="<%= Language %>"/>
    <meta http-equiv="cache-control" content="no-store, must-revalidate"/>
    <meta http-equiv="expires" content="Wed, 26 Feb 1997 08:21:57 GMT"/>
    <meta http-equiv="X-UA-Compatible" content="requiresActiveX=true"/>

    <style type="text/css">
        html, body {
            background: black;
            height: 100%;
            margin: 0px;
            overflow: hidden;
            padding: 0px;
            width: 100%;
        }

        #game-wrapper {
            margin: 0 auto;
            position: relative;
        }

        #info {
            color: #FFFFFF;
            font-size: 36px;
            font-weight: bold;
            position: absolute;
            text-transform: uppercase;
        }
    </style>

    <script language="javascript" type="text/javascript" src="/js/jquery-1.7.2.min.js"></script>
    <script language="javascript" type="text/javascript" src="/js/swfobject.js"></script>

    <script type="text/javascript" src="<%= StaticServer.Trim() %>/gameinclusion/library/gameinclusion.js"></script>
</head>

<body scrolling="no" style="margin: 0pt; overflow: hidden; padding: 0pt;">

<div class="netentgameholder" id="neGameClient"></div>

<script type="text/javascript">

    var config = <%= ConfigString %>;
    config.width = '100%';
    config.height = '100%';
    config.enforceRatio = false;

    success = function(game) {
        var gameDiv = document.getElementById("neGameClient");
        gameDiv.style.paddingTop = "";
        console.log("Game:" + game + ' loaded successfully.');
    };

    error = function(error) {
        console.log(error);
    };

    netent.launch(config, success, error);

    var realitychecktimeout = <%= RealityCheckTimeout %>;
    var realitycheckmessage1 =
        "You have requested a Reality Check after %1 minutes of play.\nYour gaming session has now reached %2 minutes.";
    //\nTo continue playing, select Continue Playing or to stop playing, click Close Game.";
    var realitycheckmessage2 = "Select Game History to show game history or press Lobby to leave game and go to lobby.";
    var timer; // Update the duration parameter with the amount of seconds in game session.
    var duration = 0;
    var gameObj; // Will contain reference to game object.

    function gameEventHandler(eventObj) {
        console.log("game event:" + eventObj);
        if (eventObj[0] == "gameReady") {
            gameObj = document.getElementById("neGameClientChild"); // support game inclusion < 1.3.0
            if (!gameObj) {
                gameObj = document.getElementById("neGameClient");
            }
            setInterval(setPluginTime, 1000); // Get new session duration time from server once every second
        }
    }

    function setPluginTime() {
// In implementation code, set duration parameter with the actual duration from server. Here we will just emulate that time is passing.
        duration++; // Draw the timer on-screen
        updatetimer(duration);
    }

    // Update the timer on screen
    function updatetimer(duration) {
        var dt = new Date();
        var durationHours = String(Math.floor(duration / 3600));
        var durationMinutes = String(Math.floor((duration % 3600) / 60));
        var durationSeconds = String((duration % 3600) % 60);
        if (durationHours.length == 1) {
            durationHours = "0" + durationHours;
        }
        if (durationMinutes.length == 1) {
            durationMinutes = "0" + durationMinutes;
        }
        if (durationSeconds.length == 1) {
            durationSeconds = "0" + durationSeconds;
        }
        var msgStr = "Current time: " +
            dt.toTimeString().split(" ")[0] +
            ", session duration: " +
            durationHours +
            ":" +
            durationMinutes +
            ":" +
            durationSeconds;
        var params = [{ "type": "text", "text": msgStr }]; // Displays message to player on screen, in the game
        gameObj.inGameMessage(JSON.stringify(params));
        if (duration > 0 && duration % realitychecktimeout == 0) {
            var messageToShow = realitycheckmessage1.replace("%1", Math.floor(realitychecktimeout / 60));
            messageToShow = messageToShow.replace("%2", Math.floor(duration / 60));
            var params = [
                "realitycheck", "Reality Check", messageToShow, [
                    { "buttonid": "continue", "buttontext": "Continue playing" },
                    {
                        "buttonid": "history",
                        "buttontext": "Game History",
                        "action": "openlinkpopup",
                        "url": '<%= LobbyUrl + "#10" %>',
                        "reason": 10
                    },
                    { "buttonid": "close", "buttontext": "Leave game", "action": "gotolobby", "reason": 11 }
                ]
            ];
            gameObj.createDialogbox(JSON.stringify(params));
        }
    }

</script>

        <% Html.RenderPartial("GoogleAnalytics", Domain, new ViewDataDictionary
           {
               {"Language", Language},
               {"IsLoggedIn", ViewData["UserSession"] != null}
           }
               ); %>
        <%= InjectScriptCode(NetEnt.CELaunchInjectScriptUrl) %>
</body>
</html>