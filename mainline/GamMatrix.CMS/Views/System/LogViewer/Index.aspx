<%@ Page Language="C#" MasterPageFile="~/Views/System/TopBar.master" Inherits="CM.Web.ViewPageEx<dynamic>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
    <script language="javascript" type="text/javascript" src="<%= Url.Content("~/js/jquery/jquery.ui/jquery-ui-timepicker-addon.min.js") %>" ></script>
    <link rel="stylesheet" type="text/css" href="<%= Url.Content("~/js/jquery/jquery.ui/redmond/jquery-ui-1.8.custom.css") %>" />
    <link rel="stylesheet" type="text/css" href="<%= Url.Content( "~/App_Themes/AdminConsole/LogViewer/Index.css") %>" />
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">


<div id="log-viewer-form-wrapper">

<% using (Html.BeginForm("SearchLog", null, null, FormMethod.Post, new { @id = "formLogView" }))
   { %>

<ui:InputField id="fldTimeRange" runat="server">
    <LabelPart>
    Time range:
    </LabelPart>
    <ControlPart>
    <table cellpadding="0" cellspacing="0" border="0" style="border-collapse:collapse">
        <tr>
            <td><input type="text" id="txtStartTime" name="startTime" readonly="readonly" value="<%= DateTime.Now.ToString("yyyy-MM-dd 00:00:01") %>"/></td>
            <td>&nbsp;-&nbsp;</td>
            <td><input type="text" id="txtEndTime" name="endTime" readonly="readonly" value="<%= DateTime.Now.ToString("yyyy-MM-dd 23:59:59") %>"/></td>
        </tr>
    </table>
    </ControlPart>
</ui:InputField>

<ui:InputField id="fldLogType" runat="server">
    <LabelPart>
    Type:
    </LabelPart>
    <ControlPart>
    <select name="logType">
        <option value="-1" selected="selected">All</option>
        <option value="<%= (int)CM.db.LogType.Information %>"><%= CM.db.LogType.Information.ToString() %></option>
        <option value="<%= (int)CM.db.LogType.Warning %>"><%= CM.db.LogType.Warning.ToString() %></option>
        <option value="<%= (int)CM.db.LogType.Error %>"><%= CM.db.LogType.Error.ToString() %></option>
        <option value="<%= (int)CM.db.LogType.Exception %>"><%= CM.db.LogType.Exception.ToString() %></option>
        <option value="<%= (int)CM.db.LogType.CodeProfiler %>"><%= CM.db.LogType.CodeProfiler.ToString() %></option>
    </select>
    </ControlPart>
</ui:InputField>

<ui:InputField id="fldPageSize" runat="server">
    <LabelPart>
    Page size:
    </LabelPart>
    <ControlPart>
    <select name="pageSize">
        <option value="100" selected="selected">Show top 100 entries</option>
        <option value="200" >Show top 200 entries</option>
        <option value="300" >Show top 300 entries</option>
        <option value="400" >Show top 400 entries</option>
        <option value="500" >Show top 500 entries</option>
    </select>
    </ControlPart>
</ui:InputField>

<ui:InputField id="fldUserID" runat="server">
    <LabelPart>
    UserID:
    </LabelPart>
    <ControlPart>
    <input name="userID" type="text" id="txtUserID" />
    </ControlPart>
</ui:InputField>

<ui:InputField id="fldSessionGuid" runat="server">
    <LabelPart>
    Session GUID:
    </LabelPart>
    <ControlPart>
    <input name="sessionGuid" type="text" id="txtSessionGuid" />
    </ControlPart>
</ui:InputField>


<ui:InputField id="fldIP" runat="server">
    <LabelPart>
    IP:
    </LabelPart>
    <ControlPart>
    <input name="ip" type="text" id="txtIP" />
    </ControlPart>
</ui:InputField>

<ui:InputField id="fldSource" runat="server">
    <LabelPart>
    Source:
    </LabelPart>
    <ControlPart>
    <input name="source" type="text" id="txtSource" />
    </ControlPart>
</ui:InputField>

<div class="buttons-wrap">
    <button id="btnSearch">Search</button>
</div>

<% } %>
</div>

<script id="entry-template" type="text/html">
<#
    var d=arguments[0];
    for(var i=0; i < d.length; i++)     
    {      
        var item = d[i]; 
#>
<div class="entry log-type-<#= item.LogType.toString().toLowerCase().htmlEncode() #>">
    <div class="head"> 
        <span class="id">[<#= item.ID #>]</span>
        <span class="message"><#= item.Message.htmlEncode() #></span>
    </div>
    <div class="details">
        <ul>
            <li><strong>Time</strong>=<#= item.Ins.htmlEncode() #>; </li>
            <li><strong>Source</strong>=<#= item.Source.htmlEncode() #>; </li>
            <li><strong>IP</strong>=<#= item.IP #>; </li>
            <li><strong>User ID</strong>=<#= item.UserID #>; </li>
            <li><strong>User Name</strong>=<#= item.UserName #>; </li>
            <li><strong>Session ID</strong>=<#= item.SessionSID #>; </li>
            <li><strong>Machine Name</strong>=<#= item.ServerName #>; </li>
            <li><strong>Url</strong>=<#= item.Url.htmlEncode() #>; </li>
        </ul>
        <div style="clear:both"></div>
    </div>

    <# if( item.LogType.toLowerCase() == 'exception' ) { #>

    <div class="links">
        <a href="javascript:void(0)" target="_self">&gt;&gt;&#160;Stack Trace</a>
        <div class="details-wrap" style="display:none" id="<#= item.ID #>">
        <textarea readonly="readonly">Loading...</textarea>
        </div>
    </div>

    <# } #>
</div>
<#   }  #>
</script>

<div id="log-viewer-result">




</div>


<script type="text/javascript">
function GetDetailsHandler(div) {
    this.div = div;
    this.onResponse = function (json) {
        if (!json.success) {
            alert(json.error);
            return;
        }
        this.div.find('textarea').val(json.data);
    };
};

function LogViewer() {
    self.LogViewer = this;


    $('#txtStartTime').datetimepicker({
        ampm : false,
        dateFormat : 'yy-mm-dd',
        showAnim:'',
        showSecond: false,
        timeFormat: 'hh:mm:ss',
        hour: 0,
        minute:0,
        second:0
    });
    $('#txtEndTime').datetimepicker({
        ampm: false,
        dateFormat: 'yy-mm-dd',
        showAnim: '',
        showSecond: false,
        timeFormat: 'hh:mm:ss'
    });
    $('#btnSearch').button().bind('click', function (e) {
        $('#log-viewer-result').html('<img src="/images/icon/loading.gif" border="0" />');
        var options = {
            type: 'POST',
            dataType: 'json',
            success: function (json) {
                if (!json.success) {
                    alert(json.error);
                    return;
                }
                $('#log-viewer-result').html($('#entry-template').parseTemplate(json.data));
                $('#log-viewer-result div.entry div.links > a').bind('click', function (e) {
                    var $div = $(this).parent('div.links').find('div.details-wrap');
                    if ($div.css('display') != 'none') {
                        $div.hide();
                        return;
                    }
                    $div.show();

                    var getDetailsAction = '<%= Url.RouteUrl( "LogViewer", new { @action="GetStackTrace" }).SafeJavascriptStringEncode()  %>?id=' + $div.attr('id');

                    jQuery.getJSON(getDetailsAction, null, (function (d) {
                        return function () {
                            (new GetDetailsHandler(d)).onResponse(arguments[0]);
                        };
                    })($div));
                });
            }
        };
        $('#formLogView').ajaxForm(options);
        $('#formLogView').submit();
        e.preventDefault();
    });

    InputFields.initialize($("#formLogView"));
};
$(document).ready( function () { new LogViewer(); } );

</script>
</asp:Content>

