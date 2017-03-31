<%@ Page Title="Metadata Selector" Language="C#" MasterPageFile="~/Views/System/Content.master" Inherits="CM.Web.ViewPageEx<CM.Content.ContentNode>"%>
<%@ Import Namespace="CM.Content" %>
<%@ Import Namespace="GamMatrix.CMS.Controllers.System" %>
<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <script language="javascript" type="text/javascript" src="<%= Url.Content("~/js/jquery/jquery.tree/lib/jquery.cookie.js") %>"></script>
    <script language="javascript" type="text/javascript" src="<%= Url.Content("~/js/jquery/jquery.tree/jquery.tree.js") %>"></script>
    <script language="javascript" type="text/javascript" src="<%= Url.Content("~/js/jquery/jquery.tree/plugins/jquery.tree.cookie.js") %>"></script>
    <link rel="stylesheet" type="text/css" href="<%= Url.Content("~/js/jquery/jquery.tree/themes/default/style.css") %>" />
    <link rel="stylesheet" type="text/css" href="<%= Url.Content( "~/App_Themes/AdminConsole/MetadataEditor/MetadataSelector.css") %>" />
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<table id="table-metadata-selector" cellpadding="0" cellspacing="0" border="0">
    <tr>
        <td class="col-1" rowspan="3" align="right">
            <iframe frameborder="0" id="ifmTree" name="ifmTree" src="<%= Url.RouteUrl( "ContentMgt", new { @action = "TreeView", @distinctName=this.Model.ContentTree.DistinctName.DefaultEncrypt(), @privateMetadata=(this.ViewData["PrivateMetadata"] as string).DefaultEncrypt() }).SafeHtmlEncode() %>"></iframe>
        </td>
        <td class="col-2" valign="top">
            <div id="entry-wrapper">
                
            </div>
        </td>
    </tr>
    <tr>
        <td valign="top" align="right"><textarea readonly="readonly" id="txtDefaultValue"></textarea></td>
    </tr>
    <tr>
        <td>
        <div id="control-wrapper" valign="bottom">
        <span>Output type:</span>
        <input type="radio" value="value" name="output-type" id="btnTypeValue" /><label for="btnTypeValue">Raw value</label>
        <input type="radio" value="htmlencode" name="output-type" id="btnTypeHtmlEncode" /><label for="btnTypeHtmlEncode">HTML encoded</label>
        <input type="radio" value="scriptencode" name="output-type" id="btnTypeScriptEncode" /><label for="btnTypeScriptEncode">Script encoded</label>
        <hr />
        <span>Expression:</span>
        <span id="spExpression"></span>
        </div>

        </td>
    </tr>
</table>

<script id="metadata-item-template" type="text/html">
<#
var d=arguments[0];
if( d.length == 0 ){
#>
No entry found.
<#   }  #>
<#
    for(var i=0; i < d.length; i++)     
    {      
        var item = d[i]; 
#>
<a href="javascript:void(0)" target="_self">
    <div class="item" id="<#= item.Name.htmlEncode() #>" path="<#= item.Path.htmlEncode() #>" entryPath="<#= item.EntryPath.htmlEncode() #>" title="<#= item.EntryPath.htmlEncode() #>" defaultValue="<#= item.Default.htmlEncode() #>">
        <div><#= item.Name.htmlEncode() #></div>
    </div>
</a>
<#   }  #>
</script>

<ui:ExternalJavascriptControl runat="server" AutoDisableInPostbackRequest="true">
<script language="javascript" type="text/javascript">
    self.onNavTreeClicked = function (path) {
        self.MetadataSelector.loadEntries(path);
    };


function MetadataSelector() {
    self.MetadataSelector = this;

    this.getAllEntriesAction = '<%= Url.RouteUrl( "MetadataEditor", new { @action = "GetAllEntries", @distinctName = this.Model.ContentTree.DistinctName.DefaultEncrypt() }).SafeJavascriptStringEncode() %>?path=';

    this.currentSelection = null;
    this.onItemSelected = function (id, path, entryPath, defaultValue) {
        var previewHtmlAction = '<%= Url.RouteUrl( "MetadataEditor", new { @action = "PreviewHtml", @distinctName = this.Model.ContentTree.DistinctName.DefaultEncrypt()}).SafeJavascriptStringEncode() %>?id=' + id + '&path=' + path;
        $('#txtDefaultValue').val(defaultValue);

        <% if( !string.IsNullOrWhiteSpace(this.ViewData["PrivateMetadata"] as string) ) { %>
        var privateMetadataPath = '<%= (this.ViewData["PrivateMetadata"] as string).SafeJavascriptStringEncode() %>';
        if (entryPath.indexOf(privateMetadataPath) == 0)
            entryPath = entryPath.substr(privateMetadataPath.length);
        <% } %>
        this.friendlyPath = entryPath;
        this.updateExpression();
    };

    this.updateExpression = function () {
        if (this.friendlyPath) {
            var expression = '[Metadata:' + $(':checked[name="output-type"]').val() + '(' + this.friendlyPath + ')]';
            $('#spExpression').text(expression);

            if( parent  )
                parent.lastSelectedExpression = expression;
        }
    };

    this.loadEntries = function (path) {
        if (path) this.path = path;
        $('#entry-wrapper').html('<img src="/images/icon/loading.gif" />');
        jQuery.getJSON(this.getAllEntriesAction + this.path, null, function (data) {
            if (!data.success) { alert(data.error); return; }
            $('#entry-wrapper').html($('#metadata-item-template').parseTemplate(data.entries));
            $('#entry-wrapper div.item').bind('click', function (e) {
                $('#entry-wrapper div.selected').removeClass('selected');
                $(this).addClass('selected');
                self.MetadataSelector.onItemSelected($(this).attr('id'), $(this).attr('path'), $(this).attr('entryPath'), $(this).attr('defaultValue'));
            });
        });
    };

    var outputType = '<%= Request["output-type"].SafeJavascriptStringEncode() %>';
    if( outputType != '' ){
        $(':input[name="output-type"][value="' + outputType + '"]').attr( 'checked', 'checked');
    }
    else{
        $(':input[name="output-type"][value="value"]').attr( 'checked', 'checked');
    }
    $(':input[name="output-type"]').bind('click', this, function (e) {
        e.data.updateExpression();
    });
}

$(document).ready(function () { new MetadataSelector(); });
</script>
</ui:ExternalJavascriptControl>



</asp:Content>



