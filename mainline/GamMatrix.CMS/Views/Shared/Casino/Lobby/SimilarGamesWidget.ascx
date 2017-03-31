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

    private int MaxCount
    {
        get
        {
            int maxCount = 0;
            if( !int.TryParse(this.ViewData["MaxCount"] as string, NumberStyles.Integer, CultureInfo.InvariantCulture, out maxCount) )
                maxCount = 15;
            return maxCount;
        }
    }
</script>

<div class="Box GameList">
	<h2 class="BoxTitle GameListTitle">
		<span class="TitleIcon CatIcon">&sect;</span>
		<strong class="TitleText"><%= this.GetMetadata(".Title").SafeHtmlEncode() %> <span><%= this.Model.ShortName %></span></strong>
	</h2>
	<ol class="GameListing Container">

        <%
            int index = 0;
        foreach( Game game in SimilarGameList)
        {
            if (++index > this.MaxCount)
                break;
            string url = string.Format("/Casino/Game/Index/{0}?realMoney={1}"
                , game.Slug.DefaultIfNullOrEmpty(game.ID)
                , Profile.IsAuthenticated
                );
         %>

		<li class="GLLItem">
			<a data-gameid="<%= game.ID.SafeHtmlEncode() %>" href="<%= url.SafeHtmlEncode() %>" class="GLa" title="<%= game.Name.SafeHtmlEncode() %>">
				<span class="IconRightArrow">&#9658;</span>
				<span class="GName"><%= game.ShortName.SafeHtmlEncode() %></span>
			</a>
		</li>

        <% } %>

	</ol>
</div>
<script type="text/javascript">
    $(function () {
        $('div.GameList > ol.GameListing a[data-gameid]').click(function (e) {
            var gameID = $(this).data('gameid') || $(this).attr('data-gameid');
            try {
                __loadGame(gameID, <%= (!Profile.IsAuthenticated).ToString().ToLowerInvariant() %>);
                e.preventDefault();
            }
            catch(e) {
            }
        });
    });
</script>