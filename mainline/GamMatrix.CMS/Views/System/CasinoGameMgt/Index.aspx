<%@ Page Title="Casino Management" Language="C#" PageTemplate="/Content.master" Inherits="CM.Web.ViewPageEx<CM.db.cmSite>" %>

<%@ Import Namespace="System.Globalization" %>
<script language="C#" runat="server" type="text/C#">

</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
<link rel="stylesheet" type="text/css" href="<%= Url.Content( "~/App_Themes/AdminConsole/CasinoMgt/Index.css") %>" />
<script language="javascript" type="text/javascript" src="<%= Url.Content("~/js/swfobject.js") %>"></script>
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<div style="padding:10px;">
    <div id="casino-mgt">
	    <ul>
		    <li><a href="#tabs-1">Games</a></li>
            <li><a href="#tabs-2">Categories</a></li>
            <li><a href="#tabs-3">Live Casino Tables</a></li>
            <% if (!(string.Equals(this.Model.DistinctName, "shared", StringComparison.InvariantCultureIgnoreCase) || string.Equals(this.Model.DistinctName, "mobileshared", StringComparison.InvariantCultureIgnoreCase)))
           { %>
            <li><a href="#tabs-4">Casino Feeds Configuration</a></li>
            <% } %>
	    </ul>
	    <div id="tabs-1">
            <% Html.RenderPartial("TabGames", this.Model); %>
	    </div>
        <div id="tabs-2">
            <% Html.RenderPartial("TabCategories", this.Model); %>
	    </div>
        <div id="tabs-3">
            <% Html.RenderPartial("TabLiveCasinoTables", this.Model); %>
	    </div>
        <% if (!(string.Equals(this.Model.DistinctName, "shared", StringComparison.InvariantCultureIgnoreCase) || string.Equals(this.Model.DistinctName, "mobileshared", StringComparison.InvariantCultureIgnoreCase)))
           { %>
        <div id="tabs-4">
            <% Html.RenderPartial("TabConfiguration", this.Model); %>
	    </div>
        <% } %>
    </div>
</div>

<script language="javascript" type="text/javascript">
    function CasinoMgt() {
        self.CasinoMgt = this;

        // init
        this.init = function () {
            $("#casino-mgt").tabs();

            this.tabGames = new TabGames(this);
        };


        this.init();
    }

    $(document).ready(function () {
        new CasinoMgt();
    });    
</script>

</asp:Content>

