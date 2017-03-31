<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<List<Game>>" %>
<%@ Import Namespace="CasinoEngine" %>

<script runat="server">
	private List<Game> GameList;

	private string ContribTo
	{
		get
		{
			return this.ViewData["ContribTo"] as string ?? "Bonus";
		}
	}

	private string GetFormattedRate(Game game)
	{
		decimal fpp = 0;
		switch (ContribTo)
		{
            case "RTP":
                fpp = game.TheoreticalPayOut;
                return string.Format("{0:f3} %", fpp * 100.00M);              
			case "FPP":
				fpp = game.FPP * 100.0M;
				break;
			case "Bonus":
				fpp = game.BonusContribution * 100.0M;
				break;
			default:
				return string.Empty;
		}

		if (Math.Floor(fpp) == fpp)
		{
			return string.Format("{0:F0} %", fpp);
		}
		else
		{
			return string.Format("{0:F1} %", fpp);
		}
	}
	
	protected override void OnInit(EventArgs e)
	{
		GameList = this.Model ?? GameMgr.GetAllGamesWithoutGroup();

		switch (ContribTo)
		{
            case "RTP":
                GameList = GameList.Where(g => g.TheoreticalPayOut > 0).OrderByDescending(g => g.TheoreticalPayOut).ToList();
                break;
			case "FPP":
				GameList = GameList.OrderByDescending(g => g.FPP).ToList();
				break;
			case "Bonus":
				GameList = GameList.OrderByDescending(g => g.BonusContribution).ToList();
				break;
		}
		
		base.OnInit(e);
	}

    protected string GetCountName()
    {
        switch (ContribTo)
        {
            case "RTP":
                return this.GetMetadata(".RTP_Percentage");
            default:
                return this.GetMetadata(".Rates");
        }
    }
</script>

<div class="SortButtons">
	<span class="Container PseudoA ContribSort"> 
        <span class="SortLink Count"><%= GetCountName().SafeHtmlEncode()%></span>  
        <span class="SortLink I">Page</span> 
        <span class="SortLink Name"><%= this.GetMetadata(".Names").SafeHtmlEncode()%></span> 
	</span>
</div>
<ol class="MenuList L" id="contribList">
	<%
		foreach (Game game in GameList)
		{              
	%>
		<li class="MenuItem X <%= game.VendorID.ToString().SafeHtmlEncode()%> ContribItem" data-vendor="<%= game.VendorID.ToString().SafeHtmlEncode()%>">
			<a class="MenuLink A Container" href="<%= Url.RouteUrl("CasinoGame", new { @gameID = game.ID }).SafeHtmlEncode()%>"> <span class="ActionArrow Y">&#9658;</span> <span class="Count"><%= GetFormattedRate(game).SafeHtmlEncode()%></span> <span class="Page I">Page</span> <span class="PageName N"><%= game.ShortName.SafeHtmlEncode()%></span> </a>
		</li>
	<%
		}
	%>	
</ol>