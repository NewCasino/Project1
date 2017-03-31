<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<div id="live-casino-last-winners" class="Box Winners WinnersNow">
	<h2 class="BoxTitle WinnersTitle">
		<span class="TitleIcon">§</span>
		<strong class="TitleText"><%= this.GetMetadata(".TitleText").HtmlEncodeSpecialCharactors() %></strong>
	</h2>
	<div id="live-casino-last-winners-entries" class="WinnersContainer Canvas">

	</div>
    <div id="live-casino-last-winners-footer"><%= this.GetMetadata(".BottomHtml").HtmlEncodeSpecialCharactors() %></div>
    <%= this.ClientTemplate("ItemsTemplate", "live-casino-last-winners-template") %>
</div>

<script type="text/javascript">
    $(document).ready(function () {
        var loadDataInterval = null;
        var isDataLoading = false;
        var startAnimationInterval = null;

        function startAnimation() {
            var $entries = $('#live-casino-last-winners-entries > div.entry');
            if ($entries.length < 3) {
                clearInterval(startAnimationInterval);
                return;
            }

            var totalHeight = $entries.length * $($entries[0]).height();
            if ($entries.height() >= totalHeight) {
                clearInterval(startAnimationInterval);
                return;
            }

            var $entry = $($entries[0]);
            $entry.animate({ 'marginTop': -1 * $entry.height() }
                , {
                    duration: 500,
                    easing: 'linear',
                    complete: function () {
                        $(this).detach().appendTo('#live-casino-last-winners-entries').css('margin-top', '0px');
                    }
                });
        }
        
        loadData();
        loadDataInterval = setInterval(loadData, 100000);

        function loadData() {
            if (isDataLoading) {
                return;
            }

            var url = '<%= this.Url.RouteUrl( "LiveCasinoLobby", new { @action = "GetRecentWinners" }).SafeJavascriptStringEncode() %>';

            isDataLoading = true;

            $.getJSON(url, function (json) {
                if (json && json.success) {
                    var html = $('#live-casino-last-winners-template').parseTemplate(json.data);

                    $('#live-casino-last-winners-entries').html(html);

                    clearInterval(startAnimationInterval);
                    startAnimationInterval = setInterval(startAnimation, 2000);
                }
            }).always(function () {
                isDataLoading = false;
            });
        }
    });
</script>