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
		Categories.Add(new GameCategoryData { Id = "All", Name = this.GetMetadata(".Category_All_Games").SafeHtmlEncode(), Games = Model.TakeByPopularity(allGames, Settings.PopularLimit_Global) });

		List<GameCategoryData> popular = Model.SelectByCategory(allGames);
		foreach (var category in popular)
			category.Games = Model.TakeByPopularity(category.Games, Settings.PopularLimit_PerCategory);
		Categories.AddRange(popular);
		
		base.OnInit(e);
	}
</script>

<%	Html.RenderPartial("/Casino/Components/CategoryList", Categories);%>