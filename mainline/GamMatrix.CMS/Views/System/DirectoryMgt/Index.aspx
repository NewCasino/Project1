<%@ Page Title="View Editor" Language="C#" MasterPageFile="~/Views/System/Content.master" Inherits="CM.Web.ViewPageEx<GamMatrix.CMS.Controllers.System.DirectoryMgtParam>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
    <link rel="stylesheet" type="text/css" href="<%= Url.Content( "~/App_Themes/AdminConsole/DirectoryMgt/Index.css") %>" />
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div style="padding:10px;">
    <div id="directory-mgt-tabs">
	    <ul>
		    <li><a href="#tabs-1">Content in <em><%= (this.ViewData["Path"] as string).SafeHtmlEncode() %></em></a></li>
            <li><a href="#tabs-2">Change history</a></li>
	    </ul>
        <div id="tabs-1">
            <% Html.RenderPartial("TabChildren", this.Model); %>
        </div>       
        <div id="tabs-2">
            <% Html.RenderPartial("../HistoryViewer/Index", this.ViewData["ContentNode"], this.ViewData); %>
        </div>
    </div>
</div>

<ui:ExternalJavascriptControl runat="server" AutoDisableInPostbackRequest="true">
<script language="javascript" type="text/javascript">
function DirectoryMgt() {

    this.onTabSelect = function (index) {
        switch (index) {
            case 1: this.tabHistory.load(); break;
        };
    };

    this.init = function () {
        $("#directory-mgt-tabs").tabs();

        this.tabChildren = new TabChildren(this);
        this.tabHistory = new TabHistory(this);

        $('#directory-mgt-tabs').bind('tabsselect', this, function (event, ui) {
            event.data.onTabSelect(ui.index);
        });
    };

    this.init();
}

$(document).ready(function () { new DirectoryMgt(); });
</script>
</ui:ExternalJavascriptControl>



</asp:Content>

