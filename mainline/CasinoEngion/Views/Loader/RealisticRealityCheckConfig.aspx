<%@ Page Language="C#" Inherits="System.Web.Mvc.ViewPage" %>
<%@ Import Namespace="CE.db" %>
<%@ Import Namespace="CE.db.Accessor" %>
<%@ Import Namespace="CE.DomainConfig" %>

<script language="C#" type="text/C#" runat="server">
    
    //protected int RealityCheckTimeout { get; set; }
    //public ceDomainConfigEx Domain { get; internal set; }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        //RealityCheckTimeout = (int)ViewData["RealityCheckTimeout"];
        //Domain = (ceDomainConfigEx)ViewData["Domain"];
    }

</script>
<!doctype html>
<html>
<head>
    
    <script src="https://code.jquery.com/jquery-latest.min.js" type="text/javascript"></script>    
    <script type="text/javascript" src="<%= Url.Content("~/js/realityCheck.js") %>"></script>

<script type="text/javascript">

    var config = {
        beforeShowMessageFunction: beforeMessageShow,
        messageAcknowlegeFunction: afterMessageShow,
        realitychecktimeout: 1800,
        historyLink: '',
        lobbyLink: '',
    }

    if (typeof (Storage) !== "undefined") {

        config.realitychecktimeout = localStorage.getItem("RealityCheckTimeout");
        config.lobbyLink = localStorage.getItem("LobbyUrl");
        config.historyLink = localStorage.getItem("HistoryUrl");

        console.log("realitychecktimeout : " + config.realitychecktimeout);
        console.log("LobbyUrl : " + config.lobbyLink);
        console.log("HistoryUrl : " + config.historyLink);
    }
    else {
        console.log("Sorry, your browser does not support Web Storage...");
    }

    window.addEventListener('message', receiveMessage);

    window.onload = function () {
        emrc.init(config);
    }

    function receiveMessage(event) {
        console.log('Receive message: ' + event.data);
        var gameActive = event.data === 'GAME_ACTIVE'; //GAME_IDLE
        emrc.changeGameStatus(gameActive);
    }

    function beforeMessageShow() {
        window.parent.postMessage('REALITY_CHECK_SHOWN', "*");
        emrc.show();
    }

    function afterMessageShow() {
        window.parent.postMessage('REALITY_CHECK_ACKNOWLEDGED', "*");
    }

</script>
</head>
<body>
</body>
</html>


