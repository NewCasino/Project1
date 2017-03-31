<%@ Control Language="C#" Inherits="System.Web.Mvc.ViewUserControl" %>
<%@ Import Namespace="CE.db" %>
<%@ Import Namespace="CE.db.Accessor" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">

    private List<ceCasinoGameBaseEx> Games { get; set; }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        
        var p = new Dictionary<string,object>()
        {
            { "VendorID" , new VendorID[] { VendorID.Microgaming } },
            { "GameCategories" , new string[] { "LIVEDEALER" } }
        };
        int total = 0;
        List<ceCasinoGameBaseEx> games = CasinoGameAccessor.SearchGames(1, 9999, Constant.SystemDomainID, p, out total, false, false);

        List<ceLiveCasinoTableBaseEx> tables 
            = LiveCasinoTableAccessor.GetDomainTables(DomainManager.CurrentDomainID, new VendorID[] { VendorID.Microgaming });

        this.Games = games.Where(g => !tables.Exists(t => t.CasinoGameBaseID == g.ID)).ToList(); 
    }

    
</script>


<style type="text/css">

</style>

<% if( this.Games.Count > 0 ) { %>

<p>There are <%= this.Games.Count %> live casino game(s) found without table.</p>
<ul>
<% foreach (ceCasinoGameBaseEx game in this.Games)
   {  %>
   <li>
        <button class="reg-table" data-gameid="<%= game.ID %>">Register table for game [<%= game.ID %>] </button> - <%= game.GameName.SafeHtmlEncode() %> 
   </li>
<% } %>

</ul>

<% } else { %>

<p>There is no new game found, all tables have been registered.</p>

<% } %>


<script type="text/javascript">

    $(function () {
        $('button.reg-table').button().click(function (e) {
            e.preventDefault();
            $(this).button("disable");

            var url = '<%= this.Url.ActionEx("RegisterTable").SafeJavascriptStringEncode() %>';
            $.getJSON(url, { gameID: $(this).data('gameid') }, function (json) {
                if (!json.success) {
                    alert(json.error);
                    return;
                }
            });
        });
    });

</script>