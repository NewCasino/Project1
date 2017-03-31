<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Components.InfoContentViewModel>" %>
<%@ Import Namespace="CasinoEngine" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script type="text/C#" runat="server">
    private List<Game> GetGames()
    {
        List<Game> games = GameMgr.GetAllGames().Select(g => g.Game).Where(g => g != null).ToList();
        List<KeyValuePair<string, List<LiveCasinoTable>>> tables = GameMgr.GetLiveCasinoTables(SiteManager.Current);
        foreach (var category in tables)
        {
            foreach (var table in category.Value)
            {
                games.Add(table);
            }
        }
        return games.OrderBy(g => g.Name).ToList();
    }

    private List<Game> GameList { get; set; }

    protected override void OnInit(EventArgs e)
    {
        this.ViewData["DataField"] = "RTP";

        base.OnInit(e);
        List<Game> allGames = GetGames();
        GameList = new List<Game>();
        for (int i = 0; i < allGames.Count; i++)
            GameList.Add(allGames[i]);
    }

    private string GetTitle()
    {
        return this.GetMetadata(string.Format(".Title_{0}", this.ViewData["DataField"]));
    }
</script>


<h2><%= this.GetTitle().SafeHtmlEncode()%></h2>

<div class="Box">
    <div class="BoxContent">
        <% Html.RenderPartial("/Casino/Components/GameContributionRates", this.GameList, this.ViewData.Merge(new { @ContribTo = "RTP" })); %>
    </div>
</div>
