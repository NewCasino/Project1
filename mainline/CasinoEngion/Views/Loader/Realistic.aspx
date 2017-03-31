<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>

<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>
<%@ Import Namespace="CasinoEngine.Controllers" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="GmGamingAPI" %>

<script language="C#" type="text/C#" runat="server">

    protected int RealityCheckTimeout { get; set; }
    protected bool IsMobile { get; set; }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        IsMobile = CE.Utils.PlatformHandler.IsMobile;

        StringBuilder url = new StringBuilder();
        url.Append(Domain.GetCfg(Realistic.GameBaseURL));
        url.AppendFormat("?externalGameId={0}&languageCode={1}&operatorId={2}&freePlay={3}&mobile={4}",
            this.Model.GameID,
            this.Language,
            this.Model.DomainID,
            FunMode ? "true" : "false",
            IsMobile ? "true" : "false");

        string startUrl = url.ToString();
        
        if (!FunMode)
        {
            TokenResponse response = GetToken();

            string currency = UserSession.Currency;
            if (response.AdditionalParameters.Exists(a => a.Name == "UserCasinoCurrency"))
            {
                currency = response.AdditionalParameters.First(a => a.Name == "UserCasinoCurrency").Value;
            }
            else
            {
                var responseJson = new JavaScriptSerializer().Serialize(response);
                throw new ApplicationException(String.Format("UserCasinoCurrency was expected but not found in GIC response : {0}", responseJson));
            }

            if (response.AdditionalParameters.Exists(a => a.Name == "RealityCheckSec"))
            {
                RealityCheckTimeout = Int32.Parse(response.AdditionalParameters.First(a => a.Name == "RealityCheckSec").Value);
            }
            
            startUrl += String.Format("&sessionToken={0}&currencyCode={1}", response.TokenKey, currency);
        }

        this.LaunchUrl = startUrl;

        if (IsMobile)
        {
            this.LaunchUrl = string.Format(CultureInfo.InvariantCulture, "{0}&lobbyurl={1}"
                , startUrl
                , HttpUtility.UrlEncode(Domain.MobileLobbyUrl)
                );
            
            //redirection to vendor url will be done via javascript.
        }

    }

</script>

<html xmlns="http://www.w3.org/1999/xhtml" lang="<%= this.Language %>">
<head>
    <title><%= this.Model.GameName.SafeHtmlEncode()%></title>
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" />
    <meta name="keywords" content="<%= this.Model.Tags.SafeHtmlEncode() %>" />
    <meta name="description" content="<%= this.Model.Description.SafeHtmlEncode() %>" />
    <meta http-equiv="pragma" content="no-cache" />
    <meta http-equiv="content-language" content="<%= this.Language %>" />
    <meta http-equiv="cache-control" content="no-store, must-revalidate" />
    <meta http-equiv="expires" content="Wed, 26 Feb 1997 08:21:57 GMT" />
    <style type="text/css">
        html, body {
            width: 100%;
            height: 100%;
            padding: 0px;
            margin: 0px;
            background: #E9E9E9;
            overflow: hidden;
        }

        #ifmGame {
            width: 100%;
            height: 100%;
            border: 0px;
        }
    </style>

    <% if (RealityCheckTimeout > 0)
       { %>

    <script src="https://code.jquery.com/jquery-latest.min.js" type="text/javascript"></script>
    <!-- Latest compiled and minified CSS -->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css"
        integrity="sha384-1q8mTJOASx8j1Au+a5WDVnPi2lkFfwwEAa8hDDdjZlpLegxhjVME1fgjWPGmkzs7" crossorigin="anonymous">
    <!-- Optional theme -->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap-theme.min.css"
        integrity="sha384-fLW2N01lMqjakBkx3l/M9EahuwpSfeNvV63J5ezn3uZzapT0u7EYsXMjQV+0En5r" crossorigin="anonymous">
    <!-- Latest compiled and minified JavaScript -->
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/js/bootstrap.min.js"
        integrity="sha384-0mSbJDEHialfmuBBQP6A4Qrprq5OVfW37PRR3j5ELqxss1yVqOtnepnHVP9aJ7xS" crossorigin="anonymous"></script>
    
    <script src="https://assets.realisticgames.co.uk/html/plugins/realitycheckflashplugin/1.0/desktop/en/js/realitycheckflashplugin-1.0.min.js"></script>

    <% } %>

</head>
<body>

    <%if (!IsMobile) // reality check solution for desctop games.
      { %>

    <iframe id="ifmGame" allowtransparency="true" frameborder="0" scrolling="no" src="<%= this.LaunchUrl.SafeHtmlEncode() %>"></iframe>
    
    <div id="rcModal" class="modal fade" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
		<div class="modal-dialog">
			<div class="modal-content">
				<div class="modal-header">
					<h3 id="myModalLabel">Reality check</h3>
				</div>
				<div class="modal-body">
					<p id="sessionTag">session info body</p>
					<p id="messageTag">Reality check body...........</p>
				</div>
				<div class="modal-footer">
					<a href="#" class="btn btn-primary" data-dismiss="modal">Continue</a>
					<a href="#" class="btn btn-default" id='historyButton'>History</a>
					<a href="#" class="btn btn-default" id='lobbyButton'>Lobby</a>
				</div>
			</div><!-- /.modal-content -->
		</div><!-- /.modal-dialog -->
    </div>

    <% if (RealityCheckTimeout > 0)
       { %>

    <script type="text/javascript">
            
        // This script assumes that a server session duration time has been retrieved, and is set in duration parameter.
        // The duration is displayed using setter "inGameMessage" to the player in-game.
        // Time until reality check message, in seconds. In the example, it is every five minutes.
        var realitychecktimeout = <%=RealityCheckTimeout%>;
        var realitycheckmessage1 = "You have requested a Reality Check after %1 minutes of play.\nYour gaming session has now reached %2 minutes."; //\nTo continue playing, select Continue Playing or to stop playing, click Close Game.";
        var timer;
        var gameActive;
        var realityCheckVisible;
        var duration = 0;
        var timeIsElapsed = false;

        //window.addEventListener('message', receiveMessage);

        $(document).ready(function() {
            regal.messages.addListenerOnce(regal.game.messages.GAME_READY, window, gameReadyCallback);
            regal.messages.addListener(regal.game.messages.GAME_ACTIVE, window, gameActiveCallback);
            regal.messages.addListener(regal.game.messages.GAME_IDLE, window, gameIdleCallback);
            gameReadyCallback();
        });
        
        function gameReadyCallback() {
            timer = setInterval(setPluginTime, 1000); // Display the updated time in game client once every second.
            initialize();
        }

        function gameActiveCallback() {
            console.log('Receive message:  gameActive');
            gameActive = true;
        }

        function gameIdleCallback() {
            console.log('Receive message:  gameIddle');
            gameActive = false;
        }
        
        function initialize() {
            console.log("Reality check plugin loaded. timeout:" + realitychecktimeout);

            $('#rcModal').on('hidden.bs.modal', function () {
                realityCheckVisible = false;
                continuePlay();
            });

            $('#historyButton').click(function () {
                goToHistory();
            });

            $('#lobbyButton').click(function () {
                goToLobby();
            });
        }

        function receiveMessage(event) {
            console.log('Receive message: ' + event.data);
            gameActive = event.data === 'GAME_ACTIVE'; //GAME_IDLE
        }

        function setPluginTime() {
            // In implementation code, set duration parameter with the actual duration from server. Here we will just emulate that time is passing.
            duration++;

            updatetimer(duration);
        }

        // Update the timer on screen
        function updatetimer(duration) {
        
            if (duration > 0) { // need to show message now
         
                if (duration % realitychecktimeout == 0) {
                    timeIsElapsed = true;
                }
                
                if (!gameActive) {
            
                    prepareMessage();
                }
            }
        }

        // function to prepare dialog with messages
        function prepareMessage() {

            var dt = new Date();
            var durationHours = String(Math.floor(duration / 3600));
            var durationMinutes = String(Math.floor((duration % 3600) / 60));
            var durationSeconds = String((duration % 3600) % 60);

            if (durationHours.length == 1) { durationHours = "0" + durationHours; }
            if (durationMinutes.length == 1) { durationMinutes = "0" + durationMinutes; }
            if (durationSeconds.length == 1) { durationSeconds = "0" + durationSeconds; }
            var msgStr = "Current time: " + dt.toTimeString().split(" ")[0] + ", session duration: " + durationHours + ":" + durationMinutes + ":" + durationSeconds;
            $('#sessionTag').text(msgStr);

            var messageToShow = realitycheckmessage1.replace("%1", Math.floor(realitychecktimeout / 60));
            messageToShow = messageToShow.replace("%2", Math.floor(duration / 60));
            $('#messageTag').text(messageToShow);

            var timeToShow = (duration % realitychecktimeout == 0);
            
            if ((timeToShow || timeIsElapsed) && !realityCheckVisible) {

                //window.parent.postMessage('REALITY_CHECK_SHOWN', "*");
                //document.getElementById('ifmGame').contentWindow.postMessage ('REALITY_CHECK_SHOWN' , '*');
                regal.realityCheck.realityCheckShown();
                timeIsElapsed = false;
                showMessage();

            }
        }

        function showMessage() {
            console.log('show message');
            $('#rcModal').modal({ show: true });
            realityCheckVisible = true;
        }
    
        // function that is called when user press continue button
        function continuePlay() {
            console.log('continue play selected');
            //document.getElementById('ifmGame').contentWindow.postMessage('REALITY_CHECK_ACKNOWLEDGED', "*");
            regal.realityCheck.realityCheckAcknowledged();
        }

        // function that is called when user press goto lobby button
        function goToLobby() {
            console.log('close game selected');
            if (window.parent) {
                window.parent.location = '<%=Domain.LobbyUrl%>';
            } else {
                window.location = '<%=Domain.LobbyUrl%>';
            }
            
        }

        function goToHistory() {
            console.log('show history selected');

            showHistoryWindow();
        }

        function showHistoryWindow() {

            var height = 768;
            var width = 1024;

            var leftPosition, topPosition;
            //Allow for borders.
            leftPosition = (window.screen.width / 2) - ((width / 2) + 10);
            //Allow for title and status bars.
            topPosition = (window.screen.height / 2) - ((height / 2) + 50);
            
            window.open('<%=Domain.AccountHistoryUrl%>', "Account History",
            "status=no,height=" + height + ",width=" + width + ",resizable=yes,left="
            + leftPosition + ",top=" + topPosition + ",screenX=" + leftPosition + ",screenY="
            + topPosition + ",toolbar=no,menubar=no,scrollbars=no,location=no,directories=no");

        }



    </script>

    <% } %>

    <% Html.RenderPartial("GoogleAnalytics", this.Domain, new ViewDataDictionary()
           {
               { "Language", this.Language},
               { "IsLoggedIn", this.ViewData["UserSession"] != null },
           }
           ); %>
    <%=InjectScriptCode(Microgaming.CELaunchInjectScriptUrl) %>

    <%}
      else // reality check solution for mobile games
      {%>

    <script type="text/javascript">
        
        <%if (RealityCheckTimeout > 0)
          { %>

        if (typeof (Storage) !== "undefined") {

            // Store 
            localStorage.setItem("RealityCheckTimeout", <%=RealityCheckTimeout%> );
            localStorage.setItem("UserId", <%=UserSession.UserID%> );
            localStorage.setItem("DomainId", <%=Domain.DomainID%> );
            
            localStorage.setItem("LobbyUrl", '<%=Domain.MobileLobbyUrl.SafeJavascriptStringEncode()%>' );
            localStorage.setItem("HistoryUrl", '<%=Domain.MobileAccountHistoryUrl.SafeJavascriptStringEncode()%>' );

        }
        else
        {
            console.log('error - localstorage is not supported...');
        }
        
        <% } %>

        function __redirect() {
            try {
                self.location.replace('<%= this.LaunchUrl.SafeJavascriptStringEncode() %>');
            }
            catch (e) {
                self.location = '<%= this.LaunchUrl.SafeJavascriptStringEncode() %>';

            }
        }
        setTimeout(2000, __redirect());
    </script>
    <%}%>
</body>
</html>
