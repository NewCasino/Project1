<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Casino.Components.GameInfo>" %>
<%@ Import Namespace="CasinoEngine" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Casino.Components" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script runat="server">
	public List<GameCategoryData> Categories { get; private set; }

	protected override void OnInit(EventArgs e)
	{
		List<Game> allGames = Model.Games;

		Categories = new List<GameCategoryData>();

		List<Game> popularGames = Model.TakeByPopularity(allGames, Settings.PopularLimit_Global);
		Categories.Add(new GameCategoryData { Id = "Pop", Name = this.GetMetadata(".Category_Popular_Games"), Games = popularGames });

		Categories.AddRange(Model.SelectByCategory(allGames));
		
		Categories.Add(new GameCategoryData { Id = "All", Name = this.GetMetadata(".Category_All_Games"), Games = allGames }); 
		
		base.OnInit(e);
	}
</script>

<%	Html.RenderPartial("/Casino/Components/CategoryList", Categories);%>