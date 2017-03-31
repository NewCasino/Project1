<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<List<Game>>" %>
<%@ Import Namespace="CasinoEngine" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script type="text/C#" runat="server">
	private List<Game> GameList { get; set; }

	protected override void OnInit(EventArgs e)
	{
		GameList = this.Model.GroupBy(g => g.ID).Select(g => g.First()).ToList();
		base.OnInit(e);
	}

	private string GetIconUrl(Game game, int size = 44)
	{
		if (!string.IsNullOrEmpty(game.IconUrlFormat))
			return string.Format(game.IconUrlFormat, size);
		return string.Empty;
	}
</script>

<ol class="GameList IconList Cols-2 Cols-X-2 L Container">
<% 
	foreach (Game game in GameList)
    { 
%>
<li class="GameItem Col X" data-vendor="<%= game.VendorID.ToString().SafeHtmlEncode()%>">
	<a class="GameLink B Container" href="<%= Url.RouteUrl("CasinoGame", new { @gameID = game.ID }).SafeHtmlEncode()%>"> 
		<span class="Icon">
			<span class="IconWrapper"> 
				<span class="Game I" style="background-image:url('<%= GetIconUrl(game, 114).SafeHtmlEncode() %>');"></span>
				<% 
                    if (game.IsNewGame) 
					{
				%> 
				<span class="LiveUpdate Updates"><%= this.GetMetadata(".New").SafeHtmlEncode() %></span> 
				<% 
					}
				%>  
			</span> 
		</span> 
		<span class="GameName N"><%= game.ShortName.SafeHtmlEncode()%></span> 
	</a>
</li>
<%
	} 
%>
</ol>

