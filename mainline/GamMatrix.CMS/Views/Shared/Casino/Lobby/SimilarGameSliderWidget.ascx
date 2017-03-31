<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CasinoEngine.Game>" %>
<%@ Import Namespace="CasinoEngine" %>
<%@ Import Namespace="System.Globalization" %>
<script type="text/C#" runat="server">
    private List<Game> SimilarGameList
    {
        get
        {
            return this.ViewData["SimilarGameList"] as List<Game>;
        }
    }
    private string ClientID { get; set; }
    protected override void OnInit(EventArgs e)
    {
        this.ClientID = string.Format("_{0}", Guid.NewGuid().ToString("N").Truncate(8));
        base.OnInit(e);
    }
</script>

<div class="Box SimilarGames" id="<%=this.ClientID %>">
	<h2 class="BoxTitle SimilarGamesTitle">
		<span class="TitleIcon">&sect;</span>
		<strong class="TitleText"><%= this.GetMetadata(".Title").SafeHtmlEncode() %> <span><%= this.Model.ShortName %></span></strong>
	</h2>

    <ul class="SimilarGamesControl Controls">
		<li class="Prev">
			<a href="#" class="PreviousLink" title="<%= this.GetMetadata(".Previous_Game_Tip").SafeHtmlEncode()%>">&#9668;</a>
		</li>
		<li class="Next">
			<a href="#" class="NextLink" title="<%= this.GetMetadata(".Next_Game_Tip").SafeHtmlEncode()%>">&#9658;</a>
		</li>
	</ul>


    <div class="SimilarGamesCanvas">
		<ul class="SimilarGameList">

    <%  foreach (Game game in this.SimilarGameList)
        {
            
            %>

			<li class="SGItem" data-gameid="<%= game.ID.SafeHtmlEncode() %>" data-funmode="<%= game.IsFunModeEnabled ? "1" : "0" %>">
				<h3 class="SGTitle">
					<a href="/Casino/Game/Index/<%= game.Slug.DefaultIfNullOrEmpty(game.ID).SafeHtmlEncode() %>" class="SGLink" title="<%= game.Name.SafeHtmlEncode() %>">
						<img class="GameIcon" src="<%= game.LogoUrl.SafeHtmlEncode() %>" width="120" height="120" alt="<%= game.ShortName.SafeHtmlEncode() %>" />
						<strong class="SGGame"><%= game.ShortName.SafeHtmlEncode() %></strong>
					</a>
				</h3>
			</li>
    <% } %>

		</ul>
	</div>
</div>
<script type="text/javascript">
    $(function () {
        var $container = $('#<%=this.ClientID %>');
        $('ul.SimilarGamesControl a.PreviousLink', $container).click(function (e) {
            e.preventDefault();
        });

        $('ul.SimilarGamesControl a.NextLink', $container).click(function (e) {
            e.preventDefault();
        });

        var direction = 0;
        $('ul.SimilarGamesControl a.PreviousLink', $container).mouseover(function (e) {
            direction = -1;
            startAnimation();
        });

        $('ul.SimilarGamesControl a.NextLink', $container).mouseover(function (e) {
            direction = 1;
            startAnimation();
        });

        $('ul.SimilarGamesControl a.NextLink,ul.SimilarGamesControl a.PreviousLink', $container).mouseout(function (e) {
            direction = 0;
        });

        function startAnimation(){
            if( $('ul.SimilarGameList li:animated', $container).length > 0 )
                return;
                        
            if($("div.SimilarGamesCanvas").width() > $(".SimilarGameList .SGItem").length * $(".SimilarGameList .SGItem").outerWidth())
                return;
            
            if( direction == 0 ){
                return;
            }
            if( direction < 0 ){
                var $first = $('ul.SimilarGameList > li:first', $container);
                $first.clone(true).appendTo($('ul.SimilarGameList', $container));
                $first.animate({ 'marginLeft': -1 * $first.width() }
                , {
                    duration: 300,
                    easing: 'linear',
                    complete: function () { $(this).remove(); $('ul.SimilarGameList li:animated', $container).stop(); startAnimation(); }
                });
            }
            else {
                var $last = $('ul.SimilarGameList > li:last',$container);
                var $first = $last.clone(true).prependTo($('ul.SimilarGameList', $container));
                $first.css('marginLeft', -1 * $last.width());
                $first.animate({ 'marginLeft': 0 }
                , {
                    duration: 300,
                    easing: 'linear',
                    complete: function () { $('ul.SimilarGameList > li:last', $container).remove(); $('ul.SimilarGameList li:animated', $container).stop(); startAnimation(); }
                });
            }
        }




        // <%-- click event to play --%>
        $('ul.SimilarGameList li[data-gameID]', $container).click(function (e) {
            var isFunModeEnabled = $(this).data('funmode') == "1";
<% if( !Profile.IsAuthenticated )
   { %>            
            if( !isFunModeEnabled ){
                alert('<%= this.GetMetadata(".AnonymousMessage").SafeJavascriptStringEncode() %>');
                e.preventDefault();
                return;
            }
<% } %>

            var gameID = $(this).data('gameid');
            try {
                var playForFun = <%= (!Profile.IsAuthenticated).ToString().ToLowerInvariant() %>;
                __loadGame(gameID.toString(), playForFun);
                e.preventDefault();
            }
            catch (e) {
            }
        });
    });
</script>