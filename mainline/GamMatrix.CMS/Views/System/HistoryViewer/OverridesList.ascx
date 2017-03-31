<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.Content.ContentNode>" %>


<table id="overrides-table" class="console-content-table" cellpadding="0" cellspacing="0" rules="none" border="0" rules="rows">
    <thead>
        <tr>
            <th>Operator</th>
            <th colspan="2"><ui:Button runat="server" ID="btnCompareOverrides" type="button">Compare</ui:Button></th>
            <th>Operator Theme</th>
            <th>&nbsp;</th>
        </tr>
    </thead>
    <tbody>
    </tbody>
</table>



<script id="overrides-row-template" type="text/html">
<#
    var d=arguments[0];
    for(var i=0; i < d.length; i++)     
    {      
        var item = d[i]; 
#>

<tr operator="<#= item.OperatorThemeEnc #>">
    <td align="center" class="col-1"><#= item.Operator #></td>
    <td align="center" class="col-2"><input type="radio" name="compare_from" class="block" /></td>
    <td align="center" class="col-3"><input type="radio" name="compare_to" class="block" /></td>
    <td align="center" class="col-4"><#= item.OperatorTheme #></td>
    <td align="center" class="col-5">
        <a href="<#= self.tabOverrides.codeViewAction.replace('distinctName', item.OperatorThemeEnc) #>" target="_blank" class="icoView block">View</a>
        <br />
        <a href="javascript:void(0)" target="_self" class="icoCompare block">Compare with template</a>
    </td>
</tr>
<#   }  #>
</script>

<ui:ExternalJavascriptControl runat="server" AutoDisableInPostbackRequest="true">
<script language="javascript" type="text/javascript">
    function TabOverrides(viewEditor) {
        self.tabOverrides = this;
        this.viewEditor = viewEditor;
        this.relativePath = '<%= this.Model.RelativePath.DefaultEncrypt() %>';
        this.getOverridesAction = '<%= Url.RouteUrl( "HistoryViewer", new { @action="GetOverrides", @distinctName = this.Model.ContentTree.DistinctName.DefaultEncrypt(), @relativePath = this.Model.RelativePath.DefaultEncrypt() }).SafeJavascriptStringEncode() %>';
        this.codeViewAction = '<%= Url.RouteUrl( "ViewEditor", new { @action="Index", @distinctName = "distinctName", @path = this.Model.RelativePath.DefaultEncrypt() }).SafeJavascriptStringEncode()%>';
        this.compareRevisionsAction = '<%= Url.RouteUrl( "HistoryViewer", new { @action="CompareOverrides" }).SafeJavascriptStringEncode()%>';
        this.compareWithTemplateAction = '<%= Url.RouteUrl( "HistoryViewer", new { @action="CompareWithTemplate", @distinctName = "distinctName", @relativePath = this.Model.RelativePath.DefaultEncrypt() }).SafeJavascriptStringEncode() %>&revisionID=';


    this.onResponse = function (data) {
        if (self.stopLoad)
            self.stopLoad();

        if (!data.success) {
            alert(data.error);
            return;
        }

        $('#overrides-table > tbody').html($('#overrides-row-template').parseTemplate(data.overrides));

        $('#overrides-table > tbody a.icoCompare').bind('click', this, function (e) { self.tabOverrides.onLnkCompareWithTemplateClick($(this).parent('td').parent('tr').attr('operator')); });

        $('#overrides-table > thead #btnCompareOverrides').bind('click', this, function (e) { self.tabOverrides.onBtnCompareClick(); });

        return;
    };

    this.onLnkCompareWithTemplateClick = function (id) {
        window.open(this.compareWithTemplateAction.replace('distinctName', id)
        , '_blank'
        , 'fullscreen=yes,location=no,menubar=no,resizable=0,scrollbars=0,status=0,titlebar=1,toolbar=0'
        );
    };

    this.onBtnCompareClick = function () {
        var src = $('#overrides-table td.col-2 input:checked').parent('td').parent('tr');
        var dest = $('#overrides-table td.col-3 input:checked').parent('td').parent('tr');

        if (src.length == 0 || dest.length == 0) {
            alert("Please choose two versions to compare.");
            return;
        }

        var srcOperatorID = src.attr('operator');
        var destOperatorID = dest.attr('operator');

        window.open((this.compareRevisionsAction + "?srcDistinctName=" + srcOperatorID + "&destDistinctName=" + destOperatorID + "&relativePath=" + this.relativePath)
            , '_blank'
            , 'fullscreen=yes,location=no,menubar=no,resizable=1,scrollbars=1,status=0,titlebar=1,toolbar=0'
            );
    };


    this.load = function () {
        $('#overrides-table > tbody').html("");
        if (self.startLoad)
            self.startLoad();

        jQuery.getJSON(this.getOverridesAction, null, self.tabOverrides.onResponse);
    };
}
</script>
</ui:ExternalJavascriptControl>