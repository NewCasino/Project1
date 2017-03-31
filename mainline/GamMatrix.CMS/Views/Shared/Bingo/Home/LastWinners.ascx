<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<List<Winner>>" %>

<%@ Import Namespace="Bingo" %>

<div id="bingo-last-winners">

<div id="bingo-last-winners-header"><%= this.GetMetadata(".TopHtml").HtmlEncodeSpecialCharactors() %></div>


<div id="bingo-last-winners-entries">
<% 
    foreach (Winner winner in this.Model)
    {
         %>
    <div class="entry">
        <div class="winners-name"><a href="#"><%= winner.NickName.SafeHtmlEncode()%></a></div>        
        <div class="winners-amount"><%= winner.Currency.SafeHtmlEncode()%> <%= winner.Amount.ToString("N2")%></div>
        <div class="winners-avatar"><img alt="<%= winner.NickName.SafeHtmlEncode()%>" src="<%= winner.AvatarUrl.SafeHtmlEncode()%>" /></div>    
    </div>

<% } %>
</div>

<div id="bingo-last-winners-footer"><%= this.GetMetadata(".BottomHtml").HtmlEncodeSpecialCharactors() %></div>

</div>
<script language="javascript" type="text/javascript">
    $(document).ready(function () {
        var $entries = $('#bingo-last-winners-entries > div.entry');
        if ($entries.length < 3)
            return;

        var totalHeight = $entries.length * $($entries[0]).height();
        if ($('#bingo-last-winners-entries > div.entry').height() >= totalHeight)
            return;

        function startAnimation() {
            var $entry = $('#bingo-last-winners-entries > div.entry:first');
            $entry.animate({ 'marginTop': -1 * $entry.height() }
                , {
                    duration: 500,
                    easing: 'linear',
                    complete: function () {
                        $(this).detach().appendTo('#bingo-last-winners-entries').css('margin-top', '0px');
                        setTimeout(startAnimation, 2000);
                    }
                });
        }
        startAnimation();
    });
</script>