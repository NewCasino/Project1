<%@ Page Language="C#" Inherits="System.Web.Mvc.ViewPage" %>

<script language="C#" type="text/C#" runat="server">
    
    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
    }

</script>
<!doctype html>
<html>
<head>
    
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

    <script type="text/javascript">

        var realitychecktimeout = 30;
        var realitycheckmessage1 = "You have requested a Reality Check after %1 minutes of play.\nYour gaming session has now reached %2 minutes."; //\nTo continue playing, select Continue Playing or to stop playing, click Close Game.";
        var timer;
        var gameActive;
        var realityCheckVisible;
        var mgScriptUrl;
        var duration = 0;

        if (typeof (Storage) !== "undefined") {

            var mgScriptUrl = localStorage.getItem("MicroGammingRCUrl");
            realitychecktimeout = localStorage.getItem("RealityCheckTimeout");
            console.log("interfaceApiScript src : " + localStorage.getItem("MicroGammingRCUrl"));
            console.log("realitychecktimeout : " + localStorage.getItem("RealityCheckTimeout"));
        }
        else {
            console.log("Sorry, your browser does not support Web Storage...");
        }

        window.onload = function () {

            if (mgScriptUrl != null) {

                var head = document.getElementsByTagName("head")[0];
                var script = document.createElement("script");

                script.setAttribute("type", "text/javascript");
                script.setAttribute("src", mgScriptUrl);

                head.addEventListener("load", function (event) {
                    if (event.target.nodeName === "SCRIPT") {
                        console.log("Script loaded: " + event.target.getAttribute("src"));
                        initialize();
                    }
                }, true);
                head.appendChild(script);

                timer = setInterval(setPluginTime, 1000); // Display the updated time in game client once every second.
            } else {
                console.log("MicroGammingRCUrl was not found.");
            }
        }

        // This script assumes that a server session duration time has been retrieved, and is set in duration parameter.
        // The duration is displayed using setter "inGameMessage" to the player in-game.
        // Time until reality check message, in seconds. In the example, it is every five minutes.
        // Update the duration parameter with the amount of seconds in game session.

        function initialize() {

            console.log("Reality check plugin loaded. timeout:" + realitychecktimeout);

            $('#rcModal').on('hidden.bs.modal', function () {
                continuePlay();
            });

            $('#historyButton').click(function () {
                goToHistory();
            });

            $('#lobbyButton').click(function () {
                goToLobby();
            });

            mgs.inGameInterface.init(function () {

                console.log("mgs.inGameInterface inited");
                mgs.inGameInterface.setMode(mgs.inGameInterface.modes.hidden);
                mgs.inGameInterface.setOpacity(0.8);

            });
        }

        function setPluginTime() {
            // In implementation code, set duration parameter with the actual duration from server. Here we will just emulate that time is passing.
            duration++;
            updatetimer(duration);
        }

        // Update the timer on screen
        function updatetimer(duration) {

            if (duration > 0 && duration % realitychecktimeout == 0) { // need to show message now

                mgs.inGameInterface.preventGameplay();
                mgs.inGameInterface.setMode(mgs.inGameInterface.modes.fullscreen);
                showRealityCheckMessage();

            }
        }

        // function to prepare dialog with messages
        function showRealityCheckMessage() {

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

            showMessage();
        }

        function showMessage() {
            $('#rcModal').modal({ show: true });
        }

        // function that is called when user press continue button
        function continuePlay() {

            mgs.inGameInterface.setMode(mgs.inGameInterface.modes.hidden);
            mgs.inGameInterface.allowGameplay();
        }

        // function that is called when user press goto lobby button
        function goToLobby() {
            mgs.inGameInterface.tolobby();
        }

        function goToHistory() {
            mgs.inGameInterface.toBanking();
        }


    </script>
</head>
<body>

    <div id="rcModal" class="modal fade" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
        <div class="modal-header">
            <h3 id="myModalLabel">Reality check</h3>
        </div>
        <div class="modal-body">
            <p id="sessionTag">session info body</p>
            <p id="messageTag">Reality check body...........</p>
        </div>
        <div class="modal-footer">
            <a href="#" class="btn" data-dismiss="modal">Continue</a>
            <a href="#" class="btn" id='historyButton'>History</a>
            <a href="#" class="btn" id='lobbyButton'>Lobby</a>
        </div>
    </div>


</body>
</html>


