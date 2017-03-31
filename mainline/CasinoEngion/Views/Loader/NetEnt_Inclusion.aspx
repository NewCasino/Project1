<%@ Page Language="C#" Debug="true" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>

<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script language="C#" type="text/C#" runat="server">
    private StringBuilder ConfigString { get; set; }

    private string GameServer { get; set; }
    private string StaticServer { get; set; }
    private string SessionID { get; set; }
    private string HelpUrl { get; set; }
    private bool DisableAudio { get; set; }
    private string CasinoBrand { get; set; }
    private int InitialWidth { get; set; }
    private int InitialHeight { get; set; }

    protected int RealityCheckTimeout;


    /// <summary>
    /// http://www.w3.org/WAI/ER/IG/ert/iso639.htm
    /// 
    /// </summary>
    /// <param name="lang"></param>
    /// <returns></returns>
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
            default: return lang.Truncate(2).ToLowerInvariant();
        }
    }

    private Dictionary<string, string> GetNetEntGameParameters(long domainID, string gameID, string language = null)
    {
        using (GamMatrixClient client = new GamMatrixClient())
        {
            NetEntAPIRequest request = new NetEntAPIRequest()
            {
                GetGameInfo = true,
                GetGameInfoGameID = gameID,
                GetGameInfoLanguage = this.Language,
            };
            request = client.SingleRequest<NetEntAPIRequest>(domainID, request);
            //LogGmClientRequest(request.SESSION_ID, request.GetGameInfoResponse.Count.ToString(), "GameInfo records");
            Dictionary<string, string> ret = new Dictionary<string, string>();

            for (int i = 0; i < request.GetGameInfoResponse.Count - 1; i += 2)
            {
                ret[request.GetGameInfoResponse[i]] = request.GetGameInfoResponse[i + 1];
            }
            return ret;
        }
    }
    
    public string CreateNetEntSessionID()
    {
        if (UseGmGaming)
        {
            var response = GetToken();

            //RealityCheckTimeout = 60; // dummy value, just for testing.
            if (response.AdditionalParameters != null && response.AdditionalParameters.Exists(a => a.Name == "RealityCheckSec"))
            {
                //RealityCheckTimeout = int.Parse(response.AdditionalParameters.First(a => a.Name == "RealityCheckSec").Value);
            }
            return response.TokenKey;
        }

        using (GamMatrixClient client = new GamMatrixClient())
        {
            NetEntAPIRequest request;
            string sessionID;

            if (CE.Utils.PlatformHandler.IsMobile)
            {
                string cacheKey = string.Format("_casino_netent_mobile_session_id_{0}", UserSession.Guid);

                // use the cached session if still valid
                sessionID = HttpRuntime.Cache[cacheKey] as string;
                if (!string.IsNullOrWhiteSpace(sessionID))
                {
                    request = new NetEntAPIRequest()
                    {
                        IsUserSessionAlive = true,
                        IsUserSessionAliveSessionID = sessionID,
                        Channel = "mobg",
                    };
                    request = client.SingleRequest<NetEntAPIRequest>(UserSession.DomainID, request);
                    LogGmClientRequest(request.SESSION_ID, request.IsUserSessionAliveResponse.ToString(), "IsUserSessionAlive");
                    if (request.IsUserSessionAliveResponse)
                        return sessionID;
                }

                // generate a new session id
                request = new NetEntAPIRequest()
                {
                    UserID = UserSession.UserID,
                    Channel = "mobg",
                    LoginUserDetailedByChannel = true,
                };
                request = client.SingleRequest<NetEntAPIRequest>(UserSession.DomainID, request);
                LogGmClientRequest(request.SESSION_ID, request.LoginUserDetailedResponse, "sID");
                sessionID = request.LoginUserDetailedResponse;

                HttpRuntime.Cache[cacheKey] = sessionID;
            }
            else
            {
                request = new NetEntAPIRequest()
                {
                    LoginUserDetailedCache = true,
                    UserID = UserSession.UserID
                };
                request = client.SingleRequest<NetEntAPIRequest>(UserSession.DomainID, request);
                LogGmClientRequest(request.SESSION_ID, request.LoginUserDetailedCacheResponse, "sID");
                sessionID = request.LoginUserDetailedCacheResponse;
            }

            return sessionID;
        }
    }

    public string CreateDemoSessionID()
    {
        string currency = string.IsNullOrEmpty(Domain.DomainDefaultCurrencyCode) ? "EUR" : Domain.DomainDefaultCurrencyCode;
        return string.Format("DEMO{0}-{1}", DateTime.Now.Ticks, currency);
    }

    private void Process()
    {
        if (UserSession == null)
            this.FunMode = true;

        this.DisableAudio = string.Equals(Request.QueryString["disableAudio"], "true", StringComparison.OrdinalIgnoreCase);

        HelpUrl = Url.RouteUrl("Loader", new { Action = "Help", domainID = Domain.DomainID, id = this.Model.Slug, language = this.Language });

        this.GameServer = Domain.GetCfg(NetEnt.CasinoGameApiBaseURL);
        this.StaticServer = Domain.GetCfg(NetEnt.CasinoGameHostBaseURL);
        this.CasinoBrand = Domain.GetCfg(NetEnt.CasinoBrand);

        if (UserSession != null && !FunMode)
        {
            this.SessionID = CreateNetEntSessionID();
        }
        else
        {
            this.SessionID = CreateDemoSessionID();//"DEMO-1234";
        }

        //Dictionary<string, string> parameters
        //= GetNetEntGameParameters(Domain.DomainID, this.Model.GameID, this.Language);

        //if (parameters.Keys.Contains("client") && parameters["client"].Equals("flash", StringComparison.InvariantCultureIgnoreCase))
        //{
        //    int width, height;
        //    if (int.TryParse(parameters["width"], out width))
        //        this.InitialWidth = width;
        //    if (int.TryParse(parameters["height"], out height))
        //        this.InitialHeight = height;
        //}
        //else
        //{
        if (this.Model.Width > 0)
            InitialWidth = this.Model.Width;
        if (this.Model.Height > 0)
            InitialHeight = this.Model.Height;
        //}

        string returnUrl = string.Format("{0}/Loader/Return/{1}/NetEnt/"
        , ConfigurationManager.AppSettings["ApiUrl"].TrimEnd('/')
        , Domain.LobbyUrl
        );

        ConfigString = new StringBuilder();
        ConfigString.Append("{");

        if (this.Model.GameID.EndsWith("_mobile_html_sw", StringComparison.InvariantCultureIgnoreCase))
        {
            //ConfigString.AppendLine(string.Format("'gameId': '{0}', ", Regex.Replace(this.Model.GameID, @"(_sw)$", string.Empty, RegexOptions.IgnoreCase)));
            ConfigString.AppendLine(string.Format("'gameId': '{0}', ", this.Model.GameID));
        }
        else
        {
            ConfigString.AppendLine(string.Format("'gameId': '{0}', ", this.Model.GameID));
        }

        ConfigString.AppendLine(string.Format("'staticServer': '{0}', ", this.StaticServer.SafeJavascriptStringEncode()));
        ConfigString.AppendLine(string.Format("'gameServer': '{0}', ", this.GameServer.SafeJavascriptStringEncode()));
        ConfigString.AppendLine(string.Format("'sessionId': '{0}', ", this.SessionID.SafeJavascriptStringEncode()));
        ConfigString.AppendLine(string.Format("'language': '{0}', ", this.Language.SafeJavascriptStringEncode()));

        if (UserSession != null && !FunMode && CE.Utils.PlatformHandler.IsMobile) // solution for mobile reality check
        {
            var pluginConfigUrl = this.Url.RouteUrl("Loader", new
            {
                @action = "RealityCheckConfig",
                @domainID = this.Model.DomainID,
                @id = ((int)VendorID.NetEnt).ToString(),
                @realityCheckTimeout = RealityCheckTimeout
            });

            if (RealityCheckTimeout > 0)
            {
                pluginConfigUrl = String.Format("{0}://{1}{2}", "https", "casino.gm.stage.everymatrix.com", pluginConfigUrl);
                ConfigString.AppendLine(string.Format("'pluginUrl': '{0}', ", pluginConfigUrl.SafeJavascriptStringEncode()));
            }
        }

        var lobbyUrlResolver = this.Url.RouteUrl("Loader", new
        {
            @action = "LobbyResolver",
            @domainID = this.Model.DomainID,
            @id = ((int)VendorID.NetEnt).ToString()
        });
        
        

        //casinoBrand
        if (!string.IsNullOrWhiteSpace(this.CasinoBrand))
            ConfigString.AppendLine(string.Format("'casinoBrand': '{0}', ", this.CasinoBrand.SafeJavascriptStringEncode()));

        ConfigString.AppendLine("'mobileParams': {");
        {
            ConfigString.AppendLine(string.Format("'lobbyUrl': '{0}' ", lobbyUrlResolver.SafeJavascriptStringEncode()));
            ConfigString.AppendLine("}");
        }
        ConfigString.AppendLine("}");
    }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        Process();
    }
</script>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title><%= this.Model.GameName.SafeHtmlEncode()%></title>
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" />
    <meta name="keywords" content="<%= this.Model.Tags.SafeHtmlEncode() %>" />
    <meta name="description" content="<%= this.Model.Description.SafeHtmlEncode() %>" />
    <meta http-equiv="pragma" content="no-cache" />
    <meta http-equiv="content-language" content="<%= this.Language %>" />
    <meta http-equiv="cache-control" content="no-store, must-revalidate" />
    <meta http-equiv="expires" content="Wed, 26 Feb 1997 08:21:57 GMT" />
    <meta http-equiv="X-UA-Compatible" content="requiresActiveX=true" />
    <style type="text/css">
        html, body {
            width: 100%;
            height: 100%;
            padding: 0px;
            margin: 0px;
            background: black;
            overflow: hidden;
        }

        #game-wrapper {
            margin: 0 auto;
            position: relative;
        }

        #info {
            position: absolute;
            color: #FFFFFF;
            font-size: 36px;
            text-transform: uppercase;
            font-weight: bold;
        }
    </style>

    <style type="text/css">
        .overlaycover {
            position: absolute;
            background: rgba(0,0,0,0.4);
            display: block;
            opacity: 0;
        }

        .messageholder {
            position: absolute;
            background: #4f81bd;
            border: 2px solid #385d8a;
            display: block;
            opacity: 0;
        }

        .messagecontent {
            position: absolute;
            display: block;
            color: #ffffff;
            font-family: Arial;
            font-size: 12px;
            padding: 10px;
        }

        .buttonspanel {
            position: absolute;
            left: 5px;
            bottom: 5px;
        }

        .custombutton {
            display: inline-block;
            margin: 5px;
        }

        .netentgameholder {
            position: absolute;
        }
    </style>

    <script language="javascript" type="text/javascript" src="/js/jquery-1.7.2.min.js"></script>
    <script type="text/javascript" src="<%=this.StaticServer.Trim() %>/gameinclusion/library/gameinclusion.js"></script>
    <%= InjectScriptCode(NetEnt.CELaunchInjectScriptUrl) %>
</head>
<body>

    <div id="game-wrapper">
        <div class="netentgameholder" id="neGameClient"></div>
        <div class="overlaycover" id="overlay"></div>
        <div class="messageholder" id="messageholder"></div>
    </div>

    <%--<div class="netentgameholder" id="netentgame"></div>--%>

    <br>

    <script type="text/javascript">
        
        var nexSupported = false;
        var canShowRealityCheck = true;
        var netEntExtendRef;
        var intentionToShowTimer;
        var timer;
 
        // Set duration (in seconds) in duration parameter
        var duration = 0;
        // Set interval (in seconds) in realityCheckIntervalSeconds parameter
        var realityCheckIntervalSeconds = <%=RealityCheckTimeout%>;
        var realitycheckmessage = "You have requested a Reality Check every %1 minutes of game play.<br>Your gaming session has now reached %2 minutes.<br>To continue playing, select 'Continue playing' below or stop playing click 'Close Game'.<br>You may also view your account history to review you playing history by clicking 'View account history'";
        
        
        var startGame = function (__customizedLoadGameCallback) {
            
            clearInterval(intentionToShowTimer);
            hideOverlay();

            var config = <%= this.ConfigString %>;
            config.width = '100%';
            config.height = '100%';
            config.enforceRatio = false;       
            
            
            var success = function (netEntExtend) {

                console.log("Game launch success");
                //Game launch successful
                if($('iframe#neGameClient').length>0)
                    $('iframe#neGameClient').attr('scrolling','no');

                if (__customizedLoadGameCallback!= null && typeof(__customizedLoadGameCallback) === 'function') {
                    __customizedLoadGameCallback(netEntExtend);
                }                

                <% if (!FunMode)
                   {%>
                
                netEntExtend.addEventListener("balanceChanged", function(){queryBalanceChange(); try{ console.log('balanceChanged, called queryBalanceChange'); }catch(ex){}}, function(){ try{console.log('error - on balanceChanged');}catch(ex){} });


                <% if (RealityCheckTimeout > 0)
                   {%>

                // gameReady Listener.
                netEntExtend.addEventListener("gameReady", function () {
                    nexSupported = true;
                    // In games which supports netent extend, set up the timer on gameready.
                    timer = setInterval(checkCurrentTime, 1000);
                }, function() {console.log("NO Nex support!");
 
                    // No NetEnt Extend support, set up the timer after 20 seconds (Flash 8 game loading time).
 
                    setTimeout(function() { timer = setInterval(checkCurrentTime, 1000); }, 20000);
                });
 
                netEntExtend.addEventListener("gameRoundStarted", function () {
                    canShowRealityCheck = false;
                    console.log("Switched canShowRealityCheck to " + canShowRealityCheck);
                });

                netEntExtend.addEventListener("gameRoundEnded", function () {
                    canShowRealityCheck = true;
                    console.log("Switched canShowRealityCheck to " + canShowRealityCheck);
                });
                
                netEntExtendRef = netEntExtend;
                
                <% } %>
 
                

                <% }%>

            };
            var error = function (e) { try{ console.log("Something went wrong \n Reason: " + e.message); }catch(ex){ alert("Something went wrong \n Reason: " + e.message); } };
            
            netent.launch(config, success, error);            

        };
        
        //----reality check functionns

        function checkCurrentTime()
        {
            duration++;
 
            if(duration > 0 && duration % realityCheckIntervalSeconds == 0)            {
                displayrealitycheck();
            }
        }

        function displayrealitycheck()
        {
            // Time to display the reality check message if the game is not in a gameround
            // From now, the intention is to display the realitycheck message.
            if(intentionToShowTimer != undefined)
            {
                clearInterval(intentionToShowTimer);
                intentionToShowTimer = undefined;
            }
            intentionToShowTimer = setInterval(function() { displayOverlay() }, 100);
 
            netEntExtendRef.call("stopAutoplay", [], function() { }, function(e) { });
        }
 
        function displayOverlay()
        {
            console.log("Intend to show realitycheck if possible!");
            if(canShowRealityCheck)
            {
                clearInterval(intentionToShowTimer);
                intentionToShowTimer = undefined;
 
                var netentgame = document.getElementById("game-wrapper");
 
                var gamepos = getPos(netentgame);
 
                console.log(gamepos);
 
                var overlay = document.getElementById("overlay");
 
                overlay.style.opacity = 1;
                overlay.style.display = "block";
 
                var overlayWidth = parseInt(netentgame.style.width);
                var overlayHeight = parseInt(netentgame.style.height);
 
                overlay.style.width = netentgame.style.width;
                overlay.style.height = netentgame.style.height;
                overlay.style.left = gamepos.x + "px";
                overlay.style.top = gamepos.y + "px";
 
                var messagepos = getPos(netentgame);
 
                var messageholder = document.getElementById("messageholder");
 
                messageholder.style.opacity = 1;
                messageholder.style.display = "block";
 
                var text = realitycheckmessage;
 
                text = text.replace("%1", Math.floor(realityCheckIntervalSeconds / 60));
                text = text.replace("%2", Math.floor(duration / 60));
 
                var html = "<div class='messagecontent'>" + text + "</div>";
 
                var buttons = [];
                buttons.push({"text":"Continue playing", "action":"continue", "url":""});
                buttons.push({"text":"View account history", "action":"history", "url":"<%=Domain.CashierUrl%>"});
                buttons.push({"text":"Close Game", "action":"close", "url":"<%=Domain.LobbyUrl%>"});

                html += "<div class='buttonspanel'>";
                for(var j=0;j<buttons.length;j++)
                {
                    html += "<button class='custombutton' onclick='handler(\"" + buttons[j].action + "\",\"" + buttons[j].url + "\")'>" + buttons[j].text + "</button>"
                }
                html += "</div>";
 
                messageholder.innerHTML = html;
 
                messageholder.style.left = (gamepos.x + 20) + "px";
                messageholder.style.top = gamepos.y + (overlayHeight - 125 - 28) + "px";
                messageholder.style.width = (overlayWidth-40) + "px";
                messageholder.style.height = 125 + "px";
            }
        }
 
        function handler(action, url)
        {
            switch(action)
            {
                case "continue":
                    {
                        // Hide overlay
                        hideOverlay();
 
                        break;
                    }
                case "history":
                    {
                        // Navigate to history page
                        showHistoryWindow();
                        break;
                    }
                case "close":
                    {
                        // Navigate to close the game (lobby or similar).
                        window.location = url;
                        break;
                    }
            }
            console.log(action);
            console.log(url);
        }

        function showHistoryWindow() {

            var height = 768;
            var width = 1024;

            var leftPosition, topPosition;
            //Allow for borders.
            leftPosition = (window.screen.width / 2) - ((width / 2) + 10);
            //Allow for title and status bars.
            topPosition = (window.screen.height / 2) - ((height / 2) + 50);

            window.open(rcConfig.historyLink, "Account History",
            "status=no,height=" + height + ",width=" + width + ",resizable=yes,left="
            + leftPosition + ",top=" + topPosition + ",screenX=" + leftPosition + ",screenY="
            + topPosition + ",toolbar=no,menubar=no,scrollbars=no,location=no,directories=no");

        }


 
        function hideOverlay()
        {
            var overlay = document.getElementById("overlay");
            overlay.style.display = "none";
 
            var messageholder = document.getElementById("messageholder");
            messageholder.style.display = "none";
        }
 
        function getPos(el) {
            for (var lx=0, ly=0; el != null; lx += el.offsetLeft, ly += el.offsetTop, el = el.offsetParent);
            return {x: lx,y: ly};
        }



        //--------------------------------

        resizeGame();

        //window.onload = startGame;

        if( typeof(__customizedLoadGame) === 'function' )
            __customizedLoadGame();
        else
            startGame();

        $(function () {
            if( typeof(__customizedLoadGame) === 'function' )
                __customizedLoadGame();
            else
                startGame();
        });

        function resizeGame() {
            var initialWidth = <%= InitialWidth %> * 1.00;
            var initialHeight = <%= InitialHeight %> * 1.00;

            var height = $(document.body).height() * 1.00;
            var width = $(document.body).width() * 1.00;

            var newWidth = width;
            var newHeight = newWidth * initialHeight / initialWidth;
            if( newHeight > height ){
                newHeight = height;
                newWidth = newHeight * initialWidth / initialHeight;
            } 
            $('#game-wrapper').width(newWidth).height(newHeight);
        }

        <% if (!FunMode)
           {%>
        function queryBalanceChange() {
            return;
        };

        function reloadBalance() {
            try {
                document.getElementById('neGameClient').reloadbalance();
            }
            catch (err) {}
        };

        if (window.addEventListener) {
            // For standards-compliant web browsers
            window.addEventListener("message", reloadBalance, false);
        }
        else {
            window.attachEvent("onmessage", reloadBalance);
        }
        <% } %>

        $(function(){            
            $(window).bind( 'resize', resizeGame); 
        });  
    </script>


    <% Html.RenderPartial("GoogleAnalytics", this.Domain, new ViewDataDictionary()
           {
               { "Language", this.Language},
               { "IsLoggedIn", this.ViewData["UserSession"] != null },
           }
           ); %>
</body>
</html>
