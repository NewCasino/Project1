<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.db.cmSite>" %>

<%@ Import Namespace="System.Globalization" %>
<script language="C#" runat="server" type="text/C#">
    
</script>

<%--<div id="changes-form-wrapper">--%>

<% using (this.Html.BeginForm("SearchChanges", null, new { @distinctName = this.Model.DistinctName.DefaultEncrypt() }, FormMethod.Post, new { @id = "formSearchChanges" }))
   { %>
<ui:InputField ID="fldTime" runat="server">
    <labelpart>
        Time: 
    </labelpart>
    <controlpart>
        <input type="text" id="txtTime" name="time" readonly="readonly" value="<%= DateTime.Now.AddDays(-1).ToString("yyyy-MM-dd 00:00:01") %>"/>
    </controlpart>
</ui:InputField>

<div class="buttons-wrap">
    <button id="btnViewChanges">View Changes</button>
</div>

<% } %>
<%--</div>--%>

<div id="changes-loading"></div>

<table id="changes-table" class="history-table" cellpadding="0" cellspacing="0" rules="none" border="0" rules="rows">
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

<script id="changes-row-template" type="text/html">
    <#
    var d=arguments[0];
    for(var i=0; i < d.length; i++)     
    {      
        var item = d[i]; 
#>

    <tr data-id="<#= item.ID #>">
        <td align="left" class="col-1"><#= item.Path #></td>
        <td align="center" class="col-2"><#= item.LastModifyTime #> - <#= item.LastModifyUsername #></td>
        <td align="center" class="col-3">
            <a href="javascript:void(0)" target="_self" class="icoView <#= item.ViewCss #>">View</a>
        </td>
    </tr>
    <#   }  #>
</script>

<% using (this.Html.BeginForm("Rollback", null, new { @distinctName = this.Model.DistinctName.DefaultEncrypt() }, FormMethod.Post, new { @id = "formRollback" }))
   { %>
<input type="hidden" name="time" />
<ul>
    <li>
        <input type="checkbox" name="confirmRollback" id="confirmRollback" />
        <label for="confirmRollback">I confirm that I want to rollback to this date.</label>
    </li>
    <li>
        <button id="btnRollback">Rollback</button>
    </li>
</ul>

<% } %>

<table id="rollback-result-table" class="history-table" cellpadding="0" cellspacing="0" rules="none" border="0" rules="rows">
    <thead>
        <tr>
            <th>Path</th>
            <th>Status</th>
            <th>Comment</th>
        </tr>
    </thead>
    <tbody>
    </tbody>
</table>

<script id="rollback-result-template" type="text/html">
    <#
    var d=arguments[0];
    for(var i=0; i < d.length; i++)     
    {      
        var item = d[i]; 
#>

    <tr>
        <td align="left" class="col-1"><#= item.RelativePath #></td>
        <td align="left" class="col-2"><#= item.RollbackTo #></td>
        <td align="left" class="col-3"><#= item.Error #></td>
    </tr>
    <#   }  #>
</script>

<div class="ui-widget" id="rollback-process" style="display: none;">
    <div style="margin-top: 20px; padding: 0pt 0.7em;" class="ui-state-highlight ui-corner-all">
        <p id="info-wrapper">
            <img src="/images/icon/loading.gif" align="absmiddle" />
            Rolling back. Please be patient and <strong>DO NOT</strong> refresh this page.
        </p>
    </div>
</div>

<ui:ExternalJavascriptControl ID="ExternalJavascriptControl1" runat="server" AutoDisableInPostbackRequest="true">
    <script language="javascript" type="text/javascript">
        function TabFullRollback(viewEditor) {

            self.tabFullRollback = this;
            this.viewEditor = viewEditor;

            self.loadResult = function () {
                var url = '<%= this.Url.RouteUrl( "SiteManager", new { @action = "GetRollbackResult", @distinctName = this.Model.DistinctName.DefaultEncrypt() }).SafeJavascriptStringEncode() %>';
                $.getJSON(url, function (json) {
                    if (!json.success) {
                        alert(json.error);
                        return;
                    }
                    $($('#rollback-result-template').parseTemplate(json.results)).appendTo($('#rollback-result-table tbody'));
                    if (json.results.length > 0)
                        $('#rollback-result-table').show();
                    window.scrollTo(0, document.body.scrollHeight);
                    if (!json.isCompleted)
                        self.loadResult();
                    else {
                        $('#info-wrapper').text('The rollback is completed!');
                    }
                });
            }

            $('#txtTime').datetimepicker({
                ampm: false,
                dateFormat: 'yy-mm-dd',
                showAnim: '',
                showSecond: false,
                timeFormat: 'hh:mm:ss'
            });

            $('#btnViewChanges').button().bind('click', function (e) {
                $('#changes-loading').html('<img src="/images/icon/loading.gif" border="0" />');
                $('#changes-table').hide();
                $('#changes-loading').show();
                $('#formRollback').hide();
                $('#rollback-result-table').hide();
                $('#rollback-process').hide();
                var options = {
                    type: 'POST',
                    dataType: 'json',
                    success: function (json) {
                        $('#changes-loading').hide();
                        if (!json.success) {
                            alert(json.error);
                            return;
                        }
                        $('#changes-table').show();
                        $('#changes-table tbody').html($('#changes-row-template').parseTemplate(json.changes));

                        $('#changes-table tbody td.col-3 > a').bind('click', function (e) {
                            var $tr = $(this).parent().parent();
                            var url = '<%= Url.RouteUrl( "HistoryViewer", new { @action="CodeView" }).SafeJavascriptStringEncode()%>?revisionID=' + $tr.data('id');
                            var wnd = window.open(url, null, "width=1000,height=700,toolbar=no,location=no,directories=0,status=yes,menubar=no,copyhistory=no");
                            if (wnd) e.preventDefault();
                        });

                        $('#formRollback').show();
                        $('#formRollback #confirmRollback').attr('checked', false);
                        $('#btnRollback').button('disable');
                    }
                };
                $('#formRollback input[name=time]').val($('#formSearchChanges input[name=time]').val());
                $('#formSearchChanges').ajaxForm(options);
                $('#formSearchChanges').submit();
                e.preventDefault();
            });

            $('#confirmRollback').click(function (e) {
                if ($(this).attr('checked'))
                    $('#btnRollback').button('enable');
                else
                    $('#btnRollback').button('disable');
            });

            $('#btnRollback').button().bind('click', function (e) {
                $('#changes-table').hide();
                $('#formRollback').hide();
                
                var options = {
                    type: 'POST',
                    dataType: 'json',
                    success: function (json) {
                        if (!json.success) {
                            alert(json.error);
                            return;
                        }

                        $('#rollback-result-table tbody').html('');
                        $('#rollback-result-table').hide();
                        $('#info-wrapper').html('<img src="/images/icon/loading.gif" align="absmiddle" />Rolling back. Please be patient and <strong>DO NOT</strong> refresh this page.');
                        $('#rollback-process').show();
                        setTimeout(function () {
                            self.loadResult();
                        }, 1000);
                    }
                };
                $('#formRollback').ajaxForm(options);
                $('#formRollback').submit();
                e.preventDefault();
            });

            InputFields.initialize($("#formSearchChanges"));
            InputFields.initialize($("#formRollback"));
        }
    </script>
</ui:ExternalJavascriptControl>
