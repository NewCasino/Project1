<%@ Page Language="C#" PageTemplate="/Casino/CasinoMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>

<%@ Import Namespace="CasinoEngine" %>

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

    private List<Game> GameList1 { get; set; }
    private List<Game> GameList2 { get; set; }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        List<Game> allGames = GetGames();
        GameList1 = new List<Game>();
        GameList2 = new List<Game>();
        for (int i = 0; i < allGames.Count; i++)
        {
            if (i % 2 == 0)
                GameList1.Add(allGames[i]);
            else
                GameList2.Add(allGames[i]);
        }
    }

    private string GetTitle()
    {
        return this.GetMetadata(string.Format(".Title_{0}", this.ViewData["DataField"]));
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">


<div class="Box GameList ResponsibleGamingContainer">
    <h1 class="PageTitle ">
            <%= GetTitle().SafeHtmlEncode()%>
    </h1>
    <% Html.RenderPartial("GameTable", this.GameList1, this.ViewData.Merge( new { @CssClass="table-1"})); %>
    <% Html.RenderPartial("GameTable", this.GameList2, this.ViewData.Merge( new { @CssClass="table-2"})); %>
</div>
<script type="text/javascript">
jQuery('body').addClass('CasinoHall InfoGames');
jQuery('#container').addClass('CasinoPage');
jQuery('.inner').removeClass('PageBox').addClass('CasinoContent');

$(".GameTable thead tr th").click(function() {
    var orderby = "asc";
    if ($(this).hasClass('asc')) {
        orderby = 'desc';
    }
    
    $(".GameTable thead tr th").removeClass('asc');
    $(".GameTable thead tr th").removeClass('desc');

    var sortName = $(this).attr('class');
    orderGameList(sortName, orderby);

});

function orderGameList(sortName,sortDesc) {
    var dataList = new Array();
    $(".GameTable tbody tr").each(function() {
        var name = $(this).find("." + sortName).attr('data');
        var content = $(this).detach();
        switch(sortName) {
            case "Percentage":
                dataList.push({Name:parseFloat(name),Content:content});
                break;
            default:
                dataList.push({Name:name,Content:content});
                break;
        }
    });

    dataList = dataList.sort(sortGame);

    if (sortDesc == 'desc') {
        dataList = dataList.reverse();
    }
    
    for (var i=0;i<dataList.length;i++) {
        if (i % 2 == 0) {
            $('.table-1 tbody').append(dataList[i].Content);
        } else {
            $('.table-2 tbody').append(dataList[i].Content);
        }
    }

    $(".GameTable thead tr th." + sortName).addClass(sortDesc);
}


function sortGame(x,y) {
    return (x.Name > y.Name) ? 1 : -1;
}

$(document).ready(function () {
    $(".GameTable thead tr th").removeClass('asc');
    $(".GameTable thead tr th").removeClass('desc');
    orderGameList("Percentage", "desc");
});
</script>
</asp:Content>

