

var realitycheckmessage1 = "You have requested a Reality Check after %1 minutes of play.\nYour gaming session has now reached %2 minutes.";
var timer;
var realityCheckVisible;
var duration = 0;
var timeIsElapsed = false;
var gameActive = false;

var sessionTag;
var messageTag;


var rcConfig = {
    beforeShowMessageFunction: null,
    messageAcknowlegeFunction: null,
    realitychecktimeout: 1800,
    historyLink: '',
    lobbyLink: ''
}

var emrc = {

    init: function (config) {

        rcConfig = config;

        createDialog();
        console.log("Reality check plugin loaded. timeout:" + rcConfig.realitychecktimeout);
        timer = setInterval(setPluginTime, 1000); // Display the updated time in game client once every second.
    },
    show: function () {
        console.log('show message');
        $('#rcModal').modal({ show: true });
        realityCheckVisible = true;
        timeIsElapsed = false;
    },

    changeGameStatus: function (status) {
        gameActive = status;
    }
}

function setPluginTime() {
    // In implementation code, set duration parameter with the actual duration from server. Here we will just emulate that time is passing.
    duration++;

    updatetimer();
}

// Update the timer on screen
function updatetimer() {

    if (duration > 0) { // need to show message now

        if (duration % rcConfig.realitychecktimeout == 0) {
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

    var messageToShow = realitycheckmessage1.replace("%1", Math.floor(rcConfig.realitychecktimeout / 60));
    messageToShow = messageToShow.replace("%2", Math.floor(duration / 60));
    $('#messageTag').text(messageToShow);

    if ((duration % rcConfig.realitychecktimeout == 0 || timeIsElapsed) && !realityCheckVisible) {

        timeIsElapsed = false;

        if (typeof rcConfig.beforeShowMessageFunction === 'function') {
            rcConfig.beforeShowMessageFunction.apply(null);
        }

    }
}

function initHandlers() {

    $('#rcModal').on('hidden.bs.modal', function () {
        continuePlay();
    });

    $('#historyButton').click(function () {
        goToHistory();
    });

    $('#lobbyButton').click(function () {
        goToLobby();
    });
}

// function that is called when user press continue button
function continuePlay() {
    console.log('continue play selected');
    realityCheckVisible = false;
    if (typeof rcConfig.messageAcknowlegeFunction === 'function') {
        rcConfig.messageAcknowlegeFunction.apply(null);
    }
}

// function that is called when user press goto lobby button
function goToLobby() {
    console.log('close game selected');

    try {
        if (self.parent !== null && self.parent != self) {
            self.parent.CloseLiveCasinoPopupFrame();
        }
    } catch (e) {
        self.parent.location.href = rcConfig.lobbyLink;
    }
    try {
        if (self.opener !== null) {
            this.window.close();
        } else {
            window.location.href = rcConfig.lobbyLink;
        }
    } catch (e) {
        window.location.href = rcConfig.lobbyLink;
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

    window.open(rcConfig.historyLink, "Account History",
    "status=no,height=" + height + ",width=" + width + ",resizable=yes,left="
    + leftPosition + ",top=" + topPosition + ",screenX=" + leftPosition + ",screenY="
    + topPosition + ",toolbar=no,menubar=no,scrollbars=no,location=no,directories=no");

}


function createDialog() {

    $('<link/>', {
        rel: 'stylesheet',
        type: 'text/css',
        href: 'https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css'
    }).appendTo('head');

    $('<link/>', {
        rel: 'stylesheet',
        type: 'text/css',
        href: 'https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap-theme.min.css'
    }).appendTo('head');

    $.getScript("https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/js/bootstrap.min.js", function (data, textStatus, jqxhr) {
        console.log("Load of bs.min was performed.");

        var dialogHtml = '<div id="rcModal" class="modal fade" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">' +
            '<div class="modal-dialog">' +
            '<div class="modal-content">' +
            '<div class="modal-header">' +
            '<h3 id="myModalLabel">Reality check</h3>' +
            '</div>' +
            '<div class="modal-body">' +
            '<p id="sessionTag">session info body</p>' +
            '<p id="messageTag">Reality check body...........</p>' +
            '</div>' +
            '<div class="modal-footer">' +
            '<a href="#" class="btn btn-primary" data-dismiss="modal">Continue</a>' +
            '<a href="#" class="btn btn-default" id="historyButton">History</a>' +
            '<a href="#" class="btn btn-default" id="lobbyButton">Lobby</a>' +
            '</div>' +
            '</div>' +
            '</div>' +
            '</div>';

        var container = $('body');
        container.append(dialogHtml);

        initHandlers();
    });

}