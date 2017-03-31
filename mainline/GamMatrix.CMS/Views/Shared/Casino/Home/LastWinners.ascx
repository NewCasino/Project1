<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<List<Casino.Winner>>" %>


<%@ Import Namespace="Casino" %>

<div id="casino-last-winners">

<div id="casino-last-winners-header"><%= this.GetMetadata(".TopHtml").HtmlEncodeSpecialCharactors() %></div>


<div id="casino-last-winners-entries">
<% 
    foreach (Winner winner in this.Model)
    {
        if( winner.GameID != null )
        {
            Game game = winner.GameID.GetGame();
            if (game == null)
                continue;
         %>

    <div class="entry country-flags">
        <div class="game-name">
            <a target="_blank" href="javascript:void(0)"><%= game.Title.SafeHtmlEncode()%></a>
        </div>
        <div class="display-name"><%= winner.DisplayName.SafeHtmlEncode()%></div>
        <div class="amount"><%= winner.Currency.SafeHtmlEncode()%> <%= winner.Amount.ToString("N2")%></div>
        <% if( winner.CountryInfo != null )
           { %>
        <div class="country-flag <%= winner.CountryInfo.GetCountryFlagName().SafeHtmlEncode() %>"></div>
        <% } %>
    </div>

<%      }
    } %>
</div>

<div id="casino-last-winners-footer"><%= this.GetMetadata(".BottomHtml").HtmlEncodeSpecialCharactors() %></div>

</div>
<script language="javascript" type="text/javascript">
    $(document).ready(function () {
        var $entries = $('#casino-last-winners-entries > div.entry');
        if ($entries.length < 3)
            return;

        var totalHeight = $entries.length * $($entries[0]).height();
        if ($('#casino-last-winners-entries > div.entry').height() >= totalHeight)
            return;

        function startAnimation() {
            var $entry = $('#casino-last-winners-entries > div.entry:first');
            $entry.css( 'marginTop' , '0px' );
            $entry.animate({ marginTop : -1 * $entry.height() }
                , {
                    duration: 500,
                    easing: 'linear',
                    complete: function () {
                        $(this).detach().appendTo('#casino-last-winners-entries').css('margin-top', '0px');
                        setTimeout(startAnimation, 2000);
                    }
                });
        }
        startAnimation();
    });
</script>