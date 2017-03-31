<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.db.cmSite>" %>

<%@ Import Namespace="System.Globalization" %>
<script language="C#" runat="server" type="text/C#">
private SelectList GetCultureList()
{
    var list = CultureInfo.GetCultures(CultureTypes.NeutralCultures | CultureTypes.SpecificCultures)
        .Where(r => Regex.IsMatch(r.Name, @"^([a-z]{2}(\-[a-z]{2})?)$", RegexOptions.IgnoreCase | RegexOptions.ECMAScript | RegexOptions.CultureInvariant))
        .OrderBy(r => r.DisplayName)
        .Select(r => new { @Text = string.Format("{0} - [{1}]", r.DisplayName, r.Name.ToLowerInvariant()), @Value = r.Name} )
        .ToList();
    list.Insert(0, new { @Text = "-- All Available Languages --", @Value = "" });
    return new SelectList(list,  "Value", "Text");
}
</script>

<div id="hostname-links" class="site-mgr-links">
<ul>
    <li><a href="javascript:void(0)" target="_self" class="refresh">Refresh</a></li>
    <li>|</li> 
    <li><a href="javascript:void(0)" target="_self" class="save">Save</a></li>
    <li>|</li>
    <li>
        <a href="<%= this.Url.RouteUrl( "HistoryViewer", new {  
                        @action = "Dialog",
                        @distinctName = this.Model.DistinctName.DefaultEncrypt(),
                        @relativePath = "/.config/site_hostname.setting".DefaultEncrypt(),
                        @searchPattner = "",
                        } ).SafeHtmlEncode()  %>" target="_blank" class="history">Change history...</a>
    </li>
</ul>
</div>

<hr class="seperator" />

<table id="table-hostname" class="table-list" cellpadding="0" cellspacing="0" rules="none" border="0" rules="rows">
    <thead>
        <tr>
            <th class="col-hostname">Hostname</th>
            <th class="col-language">Language</th>
            <th class="col-tools"><a href="javascript:void(0)">Add New</a></th>
        </tr>
    </thead>
    <tbody>       
    </tbody>
</table>

<script id="row-template" type="text/html">
<tr id="<#= arguments[0].guid#>">
    <td valign="middle" align="center" class="col-hostname">
        <input type="text" value="<#= arguments[0].HostName.htmlEncode() #>" />
    </td>
    <td valign="middle" align="center" class="col-language">
        <%: Html.DropDownList( "defaultCulture", GetCultureList()) %>
    </td>
    <td valign="middle" align="center" class="col-tools">
        <a href="javascript:void(0)" target="_self" onclick="self.tabHostname.onBtnRemoveClick('<#= arguments[0].guid#>')">Remove</a>
    </td>
</tr>
</script>

<% using (Html.BeginForm( "SaveHostNames"
       , null
       , new { @distinctName = this.Model.DistinctName.DefaultEncrypt() }
       , FormMethod.Post
       , new { @id = "formHostName"}
    ) ) { %>

<% } %>


<ui:ExternalJavascriptControl runat="server" AutoDisableInPostbackRequest="true">
<script language="javascript" type="text/javascript">
function TabHostname(viewEditor) {
    self.tabHostname = this;
    this.getHostnamesAction = '<%= Url.RouteUrl( "SiteManager", new { @action = "GetHostNames", @distinctName = this.Model.DistinctName.DefaultEncrypt() }).SafeJavascriptStringEncode() %>';

    this.S4 = function () {
        return (((1 + Math.random()) * 0x10000) | 0).toString(16).substring(1);
    }
    this.guid = function () {
        return (this.S4() + this.S4() + this.S4() + this.S4() + this.S4() + this.S4() + this.S4() + this.S4());
    }

    this.addNewRow = function (json) {
        if (json == null) json = {};
        json.guid = this.guid();
        var $row = $($('#row-template').parseTemplate(json)).appendTo($('#table-hostname tbody'));
        $('select', $row).val(json.DefaultCulture);
    };

    this.onBtnRemoveClick = function ($guid) {
        $('tr[id="' + $guid + '"]').remove();
    };

    this.refresh = function () {
        if (self.startLoad) self.startLoad();
        jQuery.getJSON(this.getHostnamesAction, null, function (json) {
            if (self.stopLoad) self.stopLoad();
            if (!json.success) { alert(json.error); return; }
            $('#table-hostname > tbody').html('');
            for (var i = 0; i < json.hosts.length; i++) {
                self.tabHostname.addNewRow(json.hosts[i]);
            }
        });
    };

    this.onLnkSaveClick = function () {
        $('#formHostName').html('');
        var rows = $('#table-hostname > tbody > tr');

        var total = 0;
        for (var i = 0; i < rows.length; i++) {
            var hostname = $('input', rows[i]).val();
            var langCode = $('select', rows[i]).val();
            if (hostname == '')
                continue;
            $('#formHostName').append('<input type="hidden" name="HostName_' + total + '" value="' + hostname.htmlEncode() + '" />');
            $('#formHostName').append('<input type="hidden" name="Language_' + total + '" value="' + langCode.htmlEncode() + '" />');
            total++;
        }
        $('#formHostName').append('<input type="hidden" name="total" value="' + total.toString(10) + '" />');

        if (self.startLoad) self.startLoad();
        var options = {
            type: 'POST',
            dataType: 'json',
            success: function (json) {
                if (self.stopLoad) self.stopLoad();
                if (!json.success) { alert(json.error); return; }
            }
        };
        $('#formHostName').ajaxForm(options);
        $('#formHostName').submit();
    };

    this.init = function () {
        this.refresh();
        $('#hostname-links a.refresh').bind('click', this, function (e) { e.preventDefault(); e.data.refresh(); });
        $('#hostname-links a.save').bind('click', this, function (e) { e.preventDefault(); e.data.onLnkSaveClick(); });
        $('#table-hostname .col-tools a').bind('click', this, function (e) { e.preventDefault(); e.data.addNewRow({ HostName: '', DefaultCulture: '' }); });

        $('#hostname-links a.history').click(function (e) {
            var wnd = window.open($(this).attr('href'), null, "width=1000,height=700,toolbar=no,location=no,directories=0,status=yes,menubar=no,copyhistory=no");
            if (wnd) e.preventDefault();
        });
    };

    this.init();
}
</script>
</ui:ExternalJavascriptControl>