<%@ Page Language="C#" Inherits="System.Web.Mvc.ViewPage" %>
<%@ Import Namespace="CE.db" %>
<%@ Import Namespace="CE.db.Accessor" %>
<%@ Import Namespace="CE.DomainConfig" %>

<script language="C#" type="text/C#" runat="server">
    
    protected int PopupTimeout { get; set; }
    protected string StaticServer { get; set; }
    public ceDomainConfigEx Domain { get; internal set; }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        PopupTimeout = (int)ViewData["RealityCheckTimeout"];
        Domain = (ceDomainConfigEx)ViewData["Domain"];
        StaticServer = Domain.GetCfg(NetEnt.CasinoGameHostBaseURL);

    }

</script>
<!doctype html>
<html>
<head>

<script type="text/javascript" src="http://netent-static.casinomodule.com/gameinclusion/library/gameinclusion.js"></script>

<script type="text/javascript">

    // Version 1.1

    // This script assumes that a server session duration time has been retrieved, and is set in duration parameter.
    // The duration is displayed using setter "inGameMessage" to the player in-game.
    // When Reality check message kicks in, player can select to continue playing, or leave game.
    // If player selects to leave game, the player will be redirected to lobby with reason codes 10 and 11 in this example.
    // The reason code, once intercepted by the lobby, can be used to redirect player to game history page.

    // Time until reality check message, in seconds. In the example, it is every five minutes.
    var realitychecktimeout = <%=PopupTimeout%>;
    var realitycheckmessage1 = "You have requested a Reality Check after %1 minutes of play.\nYour gaming session has now reached %2 minutes."; //\nTo continue playing, select Continue Playing or to stop playing, click Close Game.";

    var realitycheckmessage2 = "Select Game History to show game history or press Lobby to leave game and go to lobby.";

    var timer;

    // Update the duration parameter with the amount of seconds in game session.
    var duration = 0;

    console.log("Reality check plugin loaded. timeout:" + realitychecktimeout);

    window.onload = function () {

        // Starts the updating of time in client
        timer = setInterval(setPluginTime, 1000); // Display the updated time in game client once every second.

        // Tell the game that the plugin has initialized. Plugin must call pluginReady within 30 seconds, or game will provide error message to player.
        netent.plugin.call("pluginReady", [], function () { });

        // Tell the game to show the clock in-game
        netent.plugin.call("showSystemClock", [], function (e) { }, function (e) { });

        // Catch the player dialogbox interaction and route it to our own handler.
        netent.plugin.addEventListener("dialogBoxClosed", dialogboxbuttonhandler);
    }

    function setPluginTime() {
        // In implementation code, set duration parameter with the actual duration from server. Here we will just emulate that time is passing.
        duration++;

        // Draw the timer on-screen
        updatetimer(duration);
    }

    function dialogboxbuttonhandler(box, buttonid) {
        if (box == "realitycheck") {
            if (buttonid == "continue") {
                // No code needed here, dialog box will close automatically (it is default behavior) and game play can continue.
            } else {
                // Player has decided to leave the game. Display the next two options to the player.
                clearInterval(timer);
                showseconddialogbox();
            }
        }
    }

    // Plugin will disable game if any error occurs within the plugin
    window.onerror = function () {
        haltgame();
    }

    function haltgame() {
        // Stop updating the plugin.
        clearInterval(timer);

        // Notify the game that the plugin has encountered an error condition.
        netent.plugin.call("pluginError", [], function () { })

        // Nothing more will happen from this point on.
    }

    // Update the timer on screen
    function updatetimer(duration) {
        var dt = new Date();
        var durationHours = String(Math.floor(duration / 3600));
        var durationMinutes = String(Math.floor((duration % 3600) / 60));
        var durationSeconds = String((duration % 3600) % 60);

        if (durationHours.length == 1) { durationHours = "0" + durationHours }
        if (durationMinutes.length == 1) { durationMinutes = "0" + durationMinutes }
        if (durationSeconds.length == 1) { durationSeconds = "0" + durationSeconds }
        var msgStr = "Current time: " + dt.toTimeString().split(" ")[0] + ", session duration: " + durationHours + ":" + durationMinutes + ":" + durationSeconds;

        var params = [{ "type": "text", "text": msgStr }];

        // Displays message to player on screen, in the game
        netent.plugin.set("inGameMessage", params, function () { /* Message was updated */ }, function (e) { /* Something went wrong */ })

        if (duration > 0 && duration % realitychecktimeout == 0) {
            // Stop any on-going autoplay.
            netent.plugin.call("stopAutoplay", [], function () { });

            buttons = [{ buttonid: "continue", buttontext: "Continue playing" }, { buttonid: "close", buttontext: "Leave game" }]

            var messageToShow = realitycheckmessage1.replace("%1", Math.floor(realitychecktimeout / 60));
            messageToShow = messageToShow.replace("%2", Math.floor(duration / 60));

            showDialogBox("Reality check", messageToShow, buttons);
        }
    }

    function showseconddialogbox() {

        var params = ["realitycheck"];
        netent.plugin.call("removeDialogbox", params, function (e) { console.log('Removed: success') }, function (e) { console.log('failed: remove dialogbox'); console.log(e) });

        // Reason code 10 can be used to send player to game history page and reason code 11 can be used to detect players coming back to lobby from this dialog interaction
        buttons = [{ buttonid: "history", action: "gotolobby", reason: 10, buttontext: "Game History" }, { buttonid: "lobby", action: "gotolobby", reason: 11, buttontext: "Lobby" }]

        var messageToShow = realitycheckmessage2;

        showDialogBox("Leave game", messageToShow, buttons);
    }

    var isFirstCall = true;
    function showDialogBox(header, text, buttons) {
        if (!isFirstCall) {
            // Avoid multiple dialogboxes, so remove the previous one (given that we have already displayed it previously).
            var params = ["realitycheck"];
            netent.plugin.call("removeDialogbox", params, function (e) { console.log('Removed: success') }, function (e) { console.log('failed: remove dialogbox'); console.log(e) });
        }
        isFirstCall = false;
        var params = ["realitycheck", header, text, buttons];
        netent.plugin.call("createDialogbox", params, function (e) { console.log('Created: success') }, function (e) { console.log('failed: create dialogbox'); console.log(e) });
    }

</script>
</head>
<body>
</body>
</html>


