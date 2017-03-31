<%@ Page Language="C#" Inherits="System.Web.Mvc.ViewPage" %>
<%@ Import Namespace="CE.db" %>
<%@ Import Namespace="CE.db.Accessor" %>
<%@ Import Namespace="CE.DomainConfig" %>

<script language="C#" type="text/C#" runat="server">
    
    protected int RealityCheckTimeout { get; set; }
    public ceDomainConfigEx Domain { get; internal set; }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        RealityCheckTimeout = (int)ViewData["RealityCheckTimeout"];
        Domain = (ceDomainConfigEx)ViewData["Domain"];

    }

</script>

<html xmlns="http://www.w3.org/1999/xhtml" lang="en">
<head>
    <title>em quickspin mobile </title>
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" />
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

  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  
    <script src="https://code.jquery.com/jquery-latest.min.js" type="text/javascript"></script>
    <script type="text/javascript" src="<%= Url.Content("~/js/realityCheck.js") %>"></script>
		
	<script type="text/javascript">

	    var config = {
	        beforeShowMessageFunction: beforeMessageShow,
	        messageAcknowlegeFunction: afterMessageShow,
	        realitychecktimeout: <%=RealityCheckTimeout%>,
            historyLink: '',
            lobbyLink: ''
        }
	    var GAME_URL = "https://d2drhksbtcqozo.cloudfront.net/mcasino/jetbull/html5Test/index.html";

	    if (typeof (Storage) !== "undefined") {

	        config.realitychecktimeout = localStorage.getItem("RealityCheckTimeout");
	        GAME_URL = localStorage.getItem("QuickSpinGameUrl");
	        config.lobbyLink = localStorage.getItem("LobbyUrl");
	        config.historyLink = localStorage.getItem("HistoryUrl");

	        console.log("realitychecktimeout : " + config.realitychecktimeout);
	        console.log("GAME_URL : " + GAME_URL);
	        console.log("LobbyUrl : " + config.lobbyLink);
	        console.log("HistoryUrl : " + config.historyLink);
	    }
	    else {
	        console.log("Sorry, your browser does not support Web Storage...");
	    }

	    window.addEventListener("message", function (event) {
	        var fn = window[event.data.method];
	        var parameters;

	        if (event.data["params"]) {
	            parameters = event.data.params;
	        }

	        if (isFunction(fn)) {
	            fn.apply(null, [parameters]);
	        }
	    }, false);

	    // this method will be called when the game has been loaded
	    function gameLoadedHandler() {
	        startHandshake();
	    }
	    function gameLoaded() {
	        startHandshake();
	    }

	    // starting the handshake process to make the game install the Reality check logic
	    function startHandshake() {
	        notifyGame('confirmHandshake', { success: 'handshakeSuccess', fail: 'handshakeFail' });
	    }
	    // Handshake has been confirmed, means that the entire flow has been set and you can pause and resume the game when you want
	    function handshakeSuccess() {
	        console.log('handshake success');
	        emrc.init(config);
	    }
	    // Handshake failed probably some issues during your setup (better to contact us to understand the reason)
	    function handshakeFail() {
	        console.log('handshake fail');
	    }

        function beforeMessageShow() {
	        console.log('requesting to pause the game, requesting the session_id return_data');
	        notifyGame('pauseGame', {callback:"gamePausedHandler", return_data:['session_id']});
	    }

	    // The game received the pause request, has been paused and is displaying your iFrame right now. Do what is necessary in your side.
	    function gamePausedHandler(params) {
	        console.log('game paused:', params);
	        console.log('game session_id:', params.session_id);
	        emrc.show();
	    }

	    function afterMessageShow() {
	        // Telling the game to close the iFrame and resume the paused game
	        notifyGame('resumeGame');
	    }

	    function notifyGame(method, params) {
	        //document.getElementById('ifmGame').contentWindow.postMessage({method: method, params:params}, GAME_URL);
	        window.parent.postMessage({ method: method, params: params }, GAME_URL);
	    }

	    function isFunction(func) {
	        return (typeof func === 'function');
	    }

	    window.onload = function () {
	        // Starts the updating of time in client
	        // letting the game know that you are ready
	        notifyGame("operatorLoaded");
	    }

	    function initialize() {

	        timer = setInterval(setPluginTime, 1000); // Display the updated time in game client once every second.
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

	   

</script>	
		
</head>

<body>
	 
</body>

</html>
