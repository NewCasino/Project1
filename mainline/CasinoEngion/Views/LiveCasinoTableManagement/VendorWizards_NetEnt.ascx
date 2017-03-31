<%@ Control Language="C#" Inherits="System.Web.Mvc.ViewUserControl" %>
<%@ Import Namespace="CE.db" %>
<%@ Import Namespace="CE.db.Accessor" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">

    private List< KeyValuePair<ceCasinoGameBaseEx, NetEntAPI.LiveCasinoTable> > Games { get; set; }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        this.Games = new List<KeyValuePair<ceCasinoGameBaseEx, NetEntAPI.LiveCasinoTable>>();
        
        var p = new Dictionary<string,object>()
        {
            { "VendorID" , new VendorID[] { VendorID.NetEnt } },
             { "GameCategories" , new string[] { "LIVEDEALER" } }
        };
        
        int total = 0;
        List<ceCasinoGameBaseEx> games = CasinoGameAccessor.SearchGames(1, 9999, Constant.SystemDomainID, p, out total, false, false);

        List<NetEntAPI.LiveCasinoTable> netentGames = NetEntAPI.LiveCasinoTable.GetAll(Constant.SystemDomainID).Values.ToList();
        
        List<ceLiveCasinoTableBaseEx> tables 
            = LiveCasinoTableAccessor.GetDomainTables(DomainManager.CurrentDomainID, new VendorID[] { VendorID.NetEnt });
        
        foreach (NetEntAPI.LiveCasinoTable netentGame in netentGames)
        {
            if (tables.Exists(t => t.GameID == netentGame.GameID && t.ExtraParameter1 == netentGame.TableID))
                continue;

            ceCasinoGameBaseEx game = games.FirstOrDefault( g => g.GameID == netentGame.GameID);
            if( game == null )
                continue;
            Games.Add(new KeyValuePair<ceCasinoGameBaseEx, NetEntAPI.LiveCasinoTable>( game, netentGame) );
        }
    }

    
</script>


<style type="text/css">
ul.table-list { list-style-type:none; margin:0px; padding:0px; }
</style>


<% if (this.Games.Count <= 0)
   {%>
   <p>There is no new game found, all tables have been registered.</p>
<% } else {%>

<ul class="table-list">
<% foreach (var item in this.Games)
   {
       ceCasinoGameBaseEx game = item.Key;
       NetEntAPI.LiveCasinoTable netentGame = item.Value;
       string key = string.Format("{0}|{1}", netentGame.GameID, netentGame.TableID);
       %>
   <li>
        <button class="reg-table" data-gameid="<%= game.ID %>" data-p1="<%= netentGame.TableID %>">Register table for game [<%= game.ID %>], table id [<%= netentGame.TableID%>] </button> - <%= game.GameName.SafeHtmlEncode() %> 
   </li>
<% } %>
</ul>




<script type="text/javascript">

    $(function () {
        $('button.reg-table').button().click(function (e) {
            e.preventDefault();
            $(this).button("disable");

            var data = {
                gameID: $(this).data('gameid'),
                extraParameter1: $(this).data('p1'),
            };

            $('#loading').show();
            var url = '<%= this.Url.ActionEx("RegisterTable").SafeJavascriptStringEncode() %>';

            $.getJSON(url, data, function (json) {
                $('#loading').hide();
                if (!json.success) {
                    alert(json.error);
                    return;
                }
            });
        });
    });

</script>
<% } %>