<%@ Page Title="Casino Management" Language="C#" MasterPageFile="~/Views/System/Content.master" Inherits="CM.Web.ViewPageEx<CM.db.cmSite>"%>

<%@ Import Namespace="System.Globalization" %>
<script language="C#" runat="server" type="text/C#">

</script>

<asp:Content ID="cphHead" ContentPlaceHolderID="cphHead" Runat="Server">
<link rel="stylesheet" type="text/css" href="<%= Url.Content( "~/App_Themes/AdminConsole/CasinoMgt/Index.css") %>" />
</asp:Content>


<asp:Content ID="cphMain" ContentPlaceHolderID="cphMain" Runat="Server">

<div style="padding:10px;">

    <div id="casino-mgt">
	    <ul>
		    <li><a href="#tabs-1">Games</a></li>
            <li><a href="#tabs-2">Categories</a></li>
            <%-- 
            <li><a href="#tabs-3">Jackpots</a></li>
            <li><a href="#tabs-4">Tournaments</a></li>
                --%>
	    </ul>
	    <div id="tabs-1">
            <% Html.RenderPartial("TabGames", this.Model); %>
	    </div>

        <div id="tabs-2" onselectstart="return false" ondragstart="return false" 
            style="user-select: none; -o-user-select:none; -moz-user-select: none; -khtml-user-select: none; -webkit-user-select: none; ">
            <% Html.RenderPartial("TabCategories", this.Model); %>
        </div>
        <%-- 
        <div id="tabs-3">
        </div>

        <div id="tabs-4">
        </div>
        --%>
    </div>
</div>

<script language="javascript" type="text/javascript">
    function CasinoMgt() {
        self.CasinoMgt = this;
        
        // init
        this.init = function () {
            $("#casino-mgt").tabs();

            this.tabGames = new TabGames(this);
            this.tabCategories = new TabCategories(this);

        };


        this.init();
    }

    $(document).ready(function () {
        new CasinoMgt();
    });    
</script>



</asp:Content>



