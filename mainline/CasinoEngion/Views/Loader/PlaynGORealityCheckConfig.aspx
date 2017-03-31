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
    <title>em playngo mobile </title>
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
            beforeShowMessageFunction: invokeRealityCheck,
            messageAcknowlegeFunction: continuePlaying,
            realitychecktimeout: <%=RealityCheckTimeout%>,
            historyLink: '',
            lobbyLink: ''
        };

        function initComponent() { 
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
            ExternalCommunicator.init();
        }

        ExternalCommunicator =
        {
            source: null,//Set at init message
            targetOrigin: null,//Set at init message
            init: function () {
                window.addEventListener("message", this.processReceivedMessage.bind(this), false);
                emrc.init(config); 
            },
            //Post message to parent host (PNGHostInterface component)
            request: function (req) {
                this.source.postMessage(req, this.targetOrigin);
            },
            //Events coming from parent host (PNGHostInterface component)
            processReceivedMessage: function (e) {
                console.log("RC Component received: ", e, e.data.type);
                switch (e.data.type) {
                    case "initialized":
                        //Setup communication with PNGHostInterface
                        this.targetOrigin = e.origin;
                        this.source = e.source;
                        break;
                    // Spin is running, RC message can't be shown
                    case "roundStarted":
                        emrc.changeGameStatus(true);     
                        break;
                    // Spin finished, RC message can be shown
                    case "idle":
                        emrc.changeGameStatus(false);
                        break;
                }
            }
        };

        function continuePlaying() {
            ExternalCommunicator.request({ req: "gameEnable" });
        }

        function stopPlaying() {
            ExternalCommunicator.request(
            { req: "gameEnd", data: { redirectUrl: lobbyUrl } }
            );
        }
        
        function invokeRealityCheck(){
            ExternalCommunicator.request({ req: "gameDisable" });
            emrc.show();
        }       
    </script>

</head>
<body onload="initComponent()">
</body>
</html>
