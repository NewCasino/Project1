<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CasinoEngine.Game>" %>

<script type="text/C#" runat="server">
    private bool IsRealMoney
    {
        get
        {
            return (bool)this.ViewData["realMoney"];
        }
    }
</script>

<div class="InlineGame" id="casino-game">
    <% Html.RenderPartial("/Casino/Lobby/GameAreaCore"); %>
</div>
<script type="text/javascript">

    $(function () {
        // <%-- Back button click event --%>
        $('div.GameArea ul.ControllerButtons li.CBBack a.Button').click(function (e) {
            e.preventDefault();

            self.location = '<%= this.Url.RouteUrl("CasinoLobby", new { @action="Index"}).SafeHtmlEncode() %>';
        });

        // <%-- Fullscreen button click event --%>
        $('div.GameArea ul.ControllerButtons li.CBFull a.Button').click(function (e) {
            e.preventDefault();

            var features = "toolbar=no,menubar=no,scrollbars=no,resizable=yes,location=no,status=no,left=0,top=0,width=" + window.screen.availWidth + ",height=" + window.screen.availHeight;
            window.open($('#ifmCasinoGame').attr('src'), "_blank", features);
        });


        // <%-- load the game --%>
        __loadCasinoGame('<%= string.IsNullOrWhiteSpace(this.Model.Slug) ? this.Model.ID.SafeJavascriptStringEncode() : this.Model.Slug.SafeJavascriptStringEncode() %>', <%= (!this.IsRealMoney).ToString().ToLowerInvariant() %>, 0);
    });    

</script>

