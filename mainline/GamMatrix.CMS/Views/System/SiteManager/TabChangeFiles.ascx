<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.db.cmSite>" %>

<%@ Import Namespace="System.Globalization" %>
<script language="C#" runat="server" type="text/C#">
    
</script>

<%--<div id="change-files-form-wrapper">--%>

<% using (this.Html.BeginForm("SearchChangeFiles", null, new { @distinctName = this.Model.DistinctName.DefaultEncrypt() }, FormMethod.Post, new { @id = "formChangeFiles" }))
   { %>

<ui:InputField ID="fldRelationPath" runat="server">
    <labelpart>
        Relation Path:
    </labelpart>
    <controlpart>
        <input type="text" id="txtRelationPath" name="relationPath" value="" />
    </controlpart>
</ui:InputField>

<ui:InputField ID="fldTimeRange" runat="server">
    <labelpart>
    Time range:
    </labelpart>
    <controlpart>
    <table cellpadding="0" cellspacing="0" border="0" style="border-collapse:collapse">
        <tr>
            <td><input type="text" id="txtStartTime" name="startTime" readonly="readonly" value="<%= DateTime.Now.AddDays(-7).ToString("yyyy-MM-dd 00:00:01") %>"/></td>
            <td>&nbsp;-&nbsp;</td>
            <td><input type="text" id="txtEndTime" name="endTime" readonly="readonly" value="<%= DateTime.Now.ToString("yyyy-MM-dd 23:59:59") %>"/></td>
        </tr>
    </table>
    </controlpart>
</ui:InputField>

<ui:InputField ID="fldPageSize" runat="server">
    <labelpart>
    Page size:
    </labelpart>
    <controlpart>
    <select name="pageSize">
        <option value="100" selected="selected">Show top 100 entries</option>
        <option value="200" >Show top 200 entries</option>
        <option value="300" >Show top 300 entries</option>
        <option value="400" >Show top 400 entries</option>
        <option value="500" >Show top 500 entries</option>
    </select>
    </controlpart>
</ui:InputField>

<div class="buttons-wrap">
    <button id="btnSearch">Search</button>
</div>

<% } %>
<%--</div>--%>

<div id="change-files-loading"></div>

<table id="change-files-table" class="history-table" cellpadding="0" cellspacing="0" rules="none" border="0" rules="rows">
    <thead>
        <tr>
            <th>Path</th>
            <th>Last Modified</th>
            <th>&nbsp;</th>
        </tr>
    </thead>
    <tbody>
    </tbody>
</table>

<script id="change-files-row-template" type="text/html">
    <#
    var d=arguments[0];
    for(var i=0; i < d.length; i++)     
    {      
        var item = d[i]; 
#>

    <tr relativePath="<#= item.RelativePath.htmlEncode() #>" searchPattner="<#= item.SearchPattner.htmlEncode() #>">
        <td align="left" class="col-1"><#= item.Path #></td>
        <td align="center" class="col-2"><#= item.LastModifyTime #> - <#= item.LastModifyUsername #></td>
        <td align="center" class="col-3">
            <a href="javascript:void(0)" target="_self" class="icoView <#= item.ViewCss #>">View Changes</a>
        </td>
    </tr>
    <#   }  #>
</script>

<ui:ExternalJavascriptControl ID="ExternalJavascriptControl1" runat="server" AutoDisableInPostbackRequest="true">
    <script language="javascript" type="text/javascript">
        function TabChangeFiles(viewEditor) {

            self.tabChangeFiles = this;
            this.viewEditor = viewEditor;

            $('#txtStartTime').datetimepicker({
                ampm: false,
                dateFormat: 'yy-mm-dd',
                showAnim: '',
                showSecond: false,
                timeFormat: 'hh:mm:ss',
                hour: 0,
                minute: 0,
                second: 0
            });

            $('#txtEndTime').datetimepicker({
                ampm: false,
                dateFormat: 'yy-mm-dd',
                showAnim: '',
                showSecond: false,
                timeFormat: 'hh:mm:ss'
            });

            $('#btnSearch').button().bind('click', function (e) {
                $('#change-files-loading').html('<img src="/images/icon/loading.gif" border="0" />');
                $('#change-files-table').hide();
                $('#change-files-loading').show();
                var options = {
                    type: 'POST',
                    dataType: 'json',
                    success: function (json) {
                        $('#change-files-loading').hide();
                        if (!json.success) {
                            alert(json.error);
                            return;
                        }
                        $('#change-files-table').show();
                        $('#change-files-table tbody').html($('#change-files-row-template').parseTemplate(json.changeFiles));

                        $('#change-files-table tbody td.col-3 > a').bind('click', function (e) {
                            $tr = $(this).parent().parent();
                            var url = '<%= this.Url.RouteUrl( "HistoryViewer", new {  @action = "Dialog",@distinctName = this.Model.DistinctName.DefaultEncrypt(),@searchPattner = "",} ).SafeHtmlEncode()  %>';
                            if (url.indexOf("?") > 0)
                                url += '&';
                            else
                                url += '?';
                            url += 'relativePath=' + $tr.attr('relativePath');
                            url += '&searchPattner=' + $tr.attr('searchPattner');
                            var wnd = window.open(url, null, "width=1000,height=700,toolbar=no,location=no,directories=0,status=yes,menubar=no,copyhistory=no");
                            if (wnd) e.preventDefault();
                        });
                    }
                };
                $('#formChangeFiles').ajaxForm(options);
                $('#formChangeFiles').submit();
                e.preventDefault();
            });

            InputFields.initialize($("#formChangeFiles"));
        }
    </script>
</ui:ExternalJavascriptControl>
