<%@ Page Title="View Editor" Language="C#" MasterPageFile="~/Views/System/Content.master" Inherits="CM.Web.ViewPageEx<CM.Content.ContentNode>"%>
<%@ Import Namespace="CM.Content" %>
<%@ Import Namespace="GamMatrix.CMS.Controllers.System" %>
<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
    <link rel="stylesheet" type="text/css" href="<%= Url.Content( "~/App_Themes/AdminConsole/PageEditor/Index.css") %>" />
    <link rel="stylesheet" type="text/css" href="<%= Url.Content( "~/App_Themes/AdminConsole/DirectoryMgt/Index.css") %>" />
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div style="padding:10px;">
    <div id="pageeditor-tabs">
	    <ul>
		    <li><a href="#tabs-1">Content in <em><%= this.Model.RelativePath.SafeHtmlEncode() %>/</em></a></li>
            <li><a href="#tabs-2">Properties</a></li>
            <li><a href="#tabs-3">Change history</a></li>
	    </ul>
        <div id="tabs-1">
            <% Html.RenderPartial("../DirectoryMgt/TabChildren"
                   , new DirectoryMgtParam() { DistinctName = this.Model.ContentTree.DistinctName, RelativePath = this.Model.RelativePath, AllowedNodeTypes = this.ViewData["NodeTypes"] as KeyValuePair<string, string>[] }
                   ); %>
        </div>
	    <div id="tabs-2">
            <% Html.RenderPartial("TabProperties", new PageNode(this.Model)); %>
        </div>
        <div id="tabs-3">
            <% Html.RenderPartial("../HistoryViewer/Index", this.Model, this.ViewData); %>
        </div>
        
    </div>
</div>

<ui:ExternalJavascriptControl runat="server" AutoDisableInPostbackRequest="true">
<script language="javascript" type="text/javascript">
function PageEditor() {

    this.onTabSelect = function (index) {
        switch (index) {
            case 2: this.tabHistory.load(); break;
        };
    };

    this.init = function () {
        $("#pageeditor-tabs").tabs();
        this.tabChildren = new TabChildren(this);
        this.tabProperties = new TabProperties(this);
        this.tabHistory = new TabHistory(this);

        $('#pageeditor-tabs').bind('tabsselect', this, function (event, ui) {
            event.data.onTabSelect(ui.index);
        });
    };

    this.init();
}

new PageEditor();
</script>
</ui:ExternalJavascriptControl>



</asp:Content>



