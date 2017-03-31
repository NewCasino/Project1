<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.db.cmSite>" %>

<script language="C#" runat="server" type="text/C#">
    private List<string> GetUpdatedList()
    {
        return this.ViewData["updatedList"] as List<string>;
    }
    
</script>

<% if (GetUpdatedList() == null)
   { %>

<div class="ui-widget" id="vendor-operation-netent">
	<div style="margin-top: 20px; padding: 0 .7em;" class="ui-state-highlight ui-corner-all"> 
		<p><span style="float: left; margin-right: .3em;" class="ui-icon ui-icon-info"></span>
		Click <strong><a id="lnkSyncCTXMGames" href="#">here</a></strong> to synchronize the lastest game list from CTXM Web Service.
	</div>
</div>

<script language="javascript" type="text/javascript">
    $('#lnkSyncCTXMGames').click(function (e) {
        e.preventDefault();
        if (self.startLoad) self.startLoad();

        var url = '<%= this.Url.RouteUrl("CasinoMgt", new { @action = "SyncCTXMGames", @distinctName = this.Model.DistinctName.DefaultEncrypt() }).SafeJavascriptStringEncode() %>';
        $('#vendor-operation-netent').parent().load(url, function () {
            if (self.stopLoad) self.stopLoad();
            self.CasinoMgt.tabGames.refresh();
        });
    });
</script>

<% }
   else
   { %>

<div class="ui-widget">
    <div style="margin-top: 20px; padding: 0 .7em;" class="ui-state-highlight ui-corner-all"> 
	    <p><span style="float: left; margin-right: .3em;" class="ui-icon ui-icon-info"></span>
	    <strong><%= GetUpdatedList().Count %></strong> new games have been found, please complete the game details below. 
        <ul>
            <% foreach( string gameId in GetUpdatedList())
               { %>

               <li><%= gameId.SafeHtmlEncode() %></li>
            <% } %>
        </ul>
    </div>
</div>



<% } %>