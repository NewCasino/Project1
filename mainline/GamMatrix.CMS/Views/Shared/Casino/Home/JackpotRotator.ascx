<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<List<Casino.JackpotInfo>>" %>

<%@ Import Namespace="Casino" %>

<div id="casino-jackpots-rotator">

<div id="casino-jackpots-rotator-header"><%= this.GetMetadata(".TopHtml").HtmlEncodeSpecialCharactors() %></div>


<div id="casino-jackpots-rotator-entries">
<% 
    foreach (JackpotInfo jackpot in this.Model)
    {
        foreach (GameID gameID in jackpot.Games)
        {
            Game game = gameID.GetGame();
            if( game == null )
                continue;
         %>

    <div class="entry entry-<%=jackpot.ID %>">
        <div class="game-name" title="<%= game.Title.SafeHtmlEncode()%>"><%= game.Title.SafeHtmlEncode()%></div>
        <div class="amount"><%= jackpot.Currency.SafeHtmlEncode() %> <%= jackpot.Amount.ToString("N0") %></div>
        <div class="play-now"><%: Html.LinkButton( this.GetMetadata(".PlayNow")
                                                      , new { @target="_blank", @href = this.Url.RouteUrl("CasinoLoader", new { @action = "NetEntGame", @gameID = game.ID }) })%></div>
    </div>

<%      }
    } %>
</div>

<div id="casino-jackpots-rotator-footer"><%= this.GetMetadata(".BottomHtml").HtmlEncodeSpecialCharactors() %></div>

</div>
<script language="javascript" type="text/javascript">
    $(document).ready(function () {
        var $entries = $('#casino-jackpots-rotator-entries > div.entry');
        if ($entries.length < 3)
            return;

        var totalHeight = $entries.length * $($entries[0]).height();
        if ($('#casino-jackpots-rotator-entries > div.entry').height() >= totalHeight)
            return;

        function startAnimation() {
            var $entry = $('#casino-jackpots-rotator-entries > div.entry:first');
            $entry.animate({ 'marginTop': -1 * $entry.height() }
                , {
                    duration: 500,
                    easing: 'linear',
                    complete: function () {
                        $(this).detach().appendTo('#casino-jackpots-rotator-entries').css('margin-top', '0px');
                        setTimeout(startAnimation, 2000);
                    }
                });
        }
        startAnimation();
    });
</script>