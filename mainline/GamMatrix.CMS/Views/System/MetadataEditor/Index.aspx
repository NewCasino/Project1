<%@ Page Title="Metadata Editor" Language="C#" MasterPageFile="~/Views/System/Content.master" Inherits="CM.Web.ViewPageEx<CM.Content.ContentNode>"%>
<%@ Import Namespace="CM.Content" %>
<%@ Import Namespace="GamMatrix.CMS.Controllers.System" %>
<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
    <script language="javascript" type="text/javascript" src="<%= Url.Content("~/js/jquery/jquery.ui/jquery-ui-timepicker-addon.min.js") %>" ></script>
    <link rel="stylesheet" type="text/css" href="<%= Url.Content("~/js/jquery/jquery.ui/redmond/jquery-ui-1.8.custom.css") %>" />
    <link rel="stylesheet" type="text/css" href="<%= Url.Content( "~/App_Themes/AdminConsole/MetadataEditor/Index.css") %>" />
    <link rel="stylesheet" type="text/css" href="<%= Url.Content( "~/App_Themes/AdminConsole/DirectoryMgt/Index.css") %>" />
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div style="padding:10px;">
    <div id="metadataeditor-tabs">
	    <ul>
            <li><a href="#tabs-2">Metadata</a></li>
		    <li><a href="#tabs-1">Content in <em><%= this.Model.RelativePath.SafeHtmlEncode() %>/</em></a></li>
            <li><a href="#tabs-4">Properties</a></li>
            <li><a href="#tabs-3">Change history</a></li>
	    </ul>
        <div id="tabs-2">
            <% Html.RenderPartial("TabMetadata", this.Model, this.ViewData); %>
        </div>
        <div id="tabs-1">
            <% Html.RenderPartial("../DirectoryMgt/TabChildren"
                   , new DirectoryMgtParam() { DistinctName = this.Model.ContentTree.DistinctName, RelativePath = this.Model.RelativePath, AllowedNodeTypes = this.ViewData["NodeTypes"] as KeyValuePair<string, string>[] }
                   ); %>
        </div>	    
        <div id="tabs-3">
            <% Html.RenderPartial("../HistoryViewer/Index", this.Model, this.ViewData); %>
        </div>
        <div id="tabs-4">
            <% Html.RenderPartial("TabProperties", new MetadataNode(this.Model), this.ViewData); %>
        </div>
    </div>
</div>

<ui:ExternalJavascriptControl runat="server" AutoDisableInPostbackRequest="true">
<script language="javascript" type="text/javascript">
function MetadataEditor() {

    this.onTabSelect = function (index) {
        switch (index) {
            case 3: this.tabHistory.load(); break;
        };
    };

    this.init = function () {
        $("#metadataeditor-tabs").tabs();
        this.tabChildren = new TabChildren(this);
        this.tabMetadata = new TabMetadata(this);
        this.tabHistory = new TabHistory(this);
        this.tabProperties = new TabProperties(this);

        $('#metadataeditor-tabs').bind('tabsselect', this, function (event, ui) {
            event.data.onTabSelect(ui.index);
        });
    };

    this.init();
}

$(document).ready(function () { new MetadataEditor(); });
</script>
</ui:ExternalJavascriptControl>



</asp:Content>



