<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<script type="text/C#" runat="server">
    private string HiddenElementID
    {
        get
        {
            return this.ViewData["HiddenElementID"] as string;
        }
    }

    private string SimilarGamesWidgetPlaceHolderSelector
    {
        get
        {
            return (this.ViewData["SimilarGamesWidgetPlaceHolderSelector"] as string).DefaultIfNullOrEmpty("div.similar-games-widget-place-holder");
        }
    }
</script>

<div class="Expanded hidden" id="casino-game">
    <% Html.RenderPartial("GameAreaCore"); %>
</div>


<script type="text/javascript">
    function __loadGame(gameID, playForFun) {
        $('div.Expanded').removeClass('hidden');
        $('div.Expanded').slideDown(300);
        $('div.Expanded h2.GameTitle').empty();
        __loadCasinoGame(gameID, playForFun == true, 0);

        setTimeout(function () {
            var pos = $('div.Expanded').offset();
            window.scrollTo(pos.left, pos.top);
        }, 300);        

        var id = '<%= HiddenElementID.SafeJavascriptStringEncode() %>'
        if (id.length > 0) {
            $(document.getElementById(id)).hide();
        }

        var selector = '<%= SimilarGamesWidgetPlaceHolderSelector.SafeJavascriptStringEncode() %>';
        if (selector.length > 0) {
            var url = '<%= this.Url.RouteUrl( "CasinoLobby", new { @action = "SimilarGamesWidget" }).SafeJavascriptStringEncode() %>';
            $(selector).load(url, { gameID: gameID });
        }
    }

    $(function () {
        function closeExpandedGame() {
            __unloadCasinoGame();

            var selector = '<%= SimilarGamesWidgetPlaceHolderSelector.SafeJavascriptStringEncode() %>';
            if (selector.length > 0) {
                $(selector).empty();
            }

            $('div.Expanded').slideUp(300);
            var id = '<%= HiddenElementID.SafeJavascriptStringEncode() %>'
            if (id.length > 0) {
                $(document.getElementById(id)).slideDown();
            }
        }

        // <%-- Close button click event --%>
        $('a.ClosePopup').click(function (e) {
            e.preventDefault();
            closeExpandedGame();
        });

        // <%-- Back button click event --%>
        $('div.GameArea ul.ControllerButtons li.CBBack a.Button').click(function (e) {
            e.preventDefault();
            closeExpandedGame();
        });

        // <%-- Fullscreen button click event --%>
        $('div.GameArea ul.ControllerButtons li.CBFull a.Button').click(function (e) {
            e.preventDefault();
            closeExpandedGame();

            var features = "toolbar=no,menubar=no,scrollbars=no,resizable=yes,location=no,status=no,left=0,top=0,width=" + window.screen.availWidth + ",height=" + window.screen.availHeight;
            window.open($('#ifmCasinoGame').attr('src'), "_blank", features);
        });
    });

</script>