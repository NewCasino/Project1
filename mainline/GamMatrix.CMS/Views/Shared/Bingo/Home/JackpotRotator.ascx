<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<List<JackpotInfo>>" %>

<%@ Import Namespace="Bingo" %>

<div id="bingo-jackpots-rotator">

<div id="bingo-jackpots-rotator-header"><%= this.GetMetadata(".TopHtml").HtmlEncodeSpecialCharactors() %></div>


<div id="bingo-jackpots-rotator-entries">
<% 
    foreach (JackpotInfo jackpot in this.Model)
    {
         %>

    <div class="entry">
        <div class="jackpots-name"><%= jackpot.Name.SafeHtmlEncode()%></div>
        <div class="jackpots-amount"><%= jackpot.Currency.SafeHtmlEncode() %> <%= jackpot.Amount.ToString("N2") %></div>
    </div>

<%} %>
</div>

<div id="bingo-jackpots-rotator-footer"><%= this.GetMetadata(".BottomHtml").HtmlEncodeSpecialCharactors() %></div>

</div>

<script language="javascript" type="text/javascript">
    $(document).ready(function () {
        var $entries = $('#bingo-jackpots-rotator-entries > div.entry');
        if ($entries.length < 3)
            return;

        var totalHeight = $entries.length * $($entries[0]).height();
        if ($('#bingo-jackpots-rotator-entries > div.entry').height() >= totalHeight)
            return;

        function startAnimation() {
            var $entry = $('#bingo-jackpots-rotator-entries > div.entry:first');
            $entry.animate({ 'marginTop': -1 * $entry.height() }
                , {
                    duration: 500,
                    easing: 'linear',
                    complete: function () {
                        $(this).detach().appendTo('#bingo-jackpots-rotator-entries').css('margin-top', '0px');
                        setTimeout(startAnimation, 2000);
                    }
                });
        }
        startAnimation();
    });
</script>