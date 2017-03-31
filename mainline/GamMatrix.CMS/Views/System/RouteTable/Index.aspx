<%@ Page Title="Route Table" Language="C#" MasterPageFile="~/Views/System/Content.master" Inherits="CM.Web.ViewPageEx<CM.db.cmSite>"%>

<%@ Import Namespace="GamMatrix.CMS.Controllers.System" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
    <link rel="stylesheet" type="text/css" href="<%= Url.Content( "~/App_Themes/AdminConsole/RouteTable/Index.css") %>" />
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<div style="padding:10px;">

<div id="route-table-tabs">
	<ul>
		<li><a href="#tabs-1">Route Table</a></li>
        <li><a href="#tabs-2">HTTP 301 Redirection</a></li>
        <li><a href="#tabs-3">Url Rewritting</a></li>
	</ul>
	<div id="tabs-1">
        <% 
            Html.RenderPartial("TabRouteTable", this.ViewData); 
            %>
	</div>
    <div id="tabs-2">
        <% 
            Html.RenderPartial("TabHttpRedirection", this.ViewData); 
            %>
	</div>
    <div id="tabs-3">
        <% 
            Html.RenderPartial("TabUrlRewritting", this.Model, this.ViewData); 
            %>
    </div>
</div>


<ui:ExternalJavascriptControl runat="server" AutoDisableInPostbackRequest="true">
<script language="javascript" type="text/javascript">
function RouteTable() {
    self.RouteTable = this;

    this.init = function () {
        $('#route-table-tabs').tabs();

        this.tabUrlRewritting = new TabUrlRewritting(this);
        this.tabHttpRedirection = new TabHttpRedirection(this);
    };

    this.init();
}
$(document).ready(function () { new RouteTable(); });
</script>
</ui:ExternalJavascriptControl>



</div>

</asp:Content>



