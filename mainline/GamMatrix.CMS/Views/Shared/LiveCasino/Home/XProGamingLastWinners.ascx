<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<List<LiveCasino.Winner>>" %>

<%@ Import Namespace="LiveCasino" %>

<div id="live-casino-last-winners">

<div id="live-casino-last-winners-header"><%= this.GetMetadata(".TopHtml").HtmlEncodeSpecialCharactors() %></div>


<div id="live-casino-last-winners-entries">
<% 
    foreach( Winner winner in this.Model)
    { %>

    <div class="entry country-flags">
        <div class="display-name"><%= winner.DisplayName.SafeHtmlEncode() %></div>
        <div class="amount"><%= winner.Price.ToString("N2") %></div>

        <% if( winner.CountryInfo != null )
           { %>
        <div class="country-flag <%= winner.CountryInfo.GetCountryFlagName().SafeHtmlEncode() %>"></div>
        <% } %>
    </div>

<%  } %>
</div>

<div id="live-casino-last-winners-footer"><%= this.GetMetadata(".BottomHtml").HtmlEncodeSpecialCharactors() %></div>

</div>
<script language="javascript" type="text/javascript">
    $(document).ready(function () {
        var $entries = $('#live-casino-last-winners-entries > div.entry');
        if ($entries.length < 3)
            return;

        var totalHeight = $entries.length * $($entries[0]).height();
        if ($('#live-casino-last-winners-entries > div.entry').height() >= totalHeight)
            return;

        function startAnimation() {
            var $entry = $('#live-casino-last-winners-entries > div.entry:first');
            $entry.animate({ 'marginTop': -1 * $entry.height() }
                , {
                    duration: 500,
                    easing: 'linear',
                    complete: function () {
                        $(this).detach().appendTo('#live-casino-last-winners-entries').css('margin-top', '0px');
                        setTimeout(startAnimation, 2000);
                    }
                });
        }
        startAnimation();
    });
</script>