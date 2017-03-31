<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.db.cmSite>" %>

<%@ Import Namespace="System.Globalization" %>
<script language="C#" runat="server" type="text/C#">
    private bool IsMobileSite
    {
        get
        {
            if (string.Equals(this.Model.TemplateDomainDistinctName, "MobileShared", StringComparison.InvariantCultureIgnoreCase))
                return true;

            if (string.Equals(this.Model.DistinctName, "MobileShared", StringComparison.InvariantCultureIgnoreCase))
                return true;

            return false;
        }
    }
</script>

<div id="host-mapping-links" class="site-mgr-links">
    <ul>
        <li><a href="javascript:void(0)" target="_self" class="refresh">Refresh</a></li>
        <li>|</li>
        <li><a href="javascript:void(0)" target="_self" class="save">Save</a></li>
        <li>|</li>
        <li>
            <a href="<%= this.Url.RouteUrl( "HistoryViewer", new {  
                        @action = "Dialog",
                        @distinctName = this.Model.DistinctName.DefaultEncrypt(),
                        @relativePath = "/.config/site_host_mapping.setting".DefaultEncrypt(),
                        @searchPattner = "",
                        } ).SafeHtmlEncode()  %>"
                target="_blank" class="history">Change history...</a>
        </li>
    </ul>
</div>

<hr class="seperator" />

<table id="table-host-mapping" class="table-list" cellpadding="0" cellspacing="0" rules="none" border="0" rules="rows">
    <thead>
        <tr>
            <th class="col-hostname-readonly">Hostname</th>
            <th class="col-mapping-hostname"><% if (IsMobileSite)
                                                { %>PC Site Host<% }
                                                else
                                                { %>Mobile Site Host <%} %></th>
        </tr>
    </thead>
    <tbody>
    </tbody>
</table>

<script id="host-mapping-row-template" type="text/html">
    <tr id="<#= arguments[0].guid#>">
        <td valign="middle" align="center" class="col-hostname-readonly">
            <span><#= arguments[0].HostName.htmlEncode() #></span>
            <input type="hidden" value="<#= arguments[0].HostName.htmlEncode() #>" />
        </td>
        <td valign="middle" align="center" class="col-mapping-hostname">
            <input type="text" value="<#= arguments[0].MappingHostName.htmlEncode() #>" />
        </td>
    </tr>
</script>

<% using (Html.BeginForm("SaveHostMapping"
       , null
       , new { @distinctName = this.Model.DistinctName.DefaultEncrypt() }
       , FormMethod.Post
       , new { @id = "formHostMapping" }
    ))
   { %>

<% } %>


<ui:ExternalJavascriptControl runat="server" AutoDisableInPostbackRequest="true">
<script language="javascript" type="text/javascript">
    function TabHostMapping(viewEditor) {
        self.tabHostMapping = this;
        this.getHostMappingAction = '<%= Url.RouteUrl( "SiteManager", new { @action = "GetHostMapping", @distinctName = this.Model.DistinctName.DefaultEncrypt() }).SafeJavascriptStringEncode() %>';

        this.S4 = function () {
            return (((1 + Math.random()) * 0x10000) | 0).toString(16).substring(1);
        }
        this.guid = function () {
            return (this.S4() + this.S4() + this.S4() + this.S4() + this.S4() + this.S4() + this.S4() + this.S4());
        }

        this.addNewRow = function (json) {
            if (json == null) json = {};
            json.guid = this.guid();
            var $row = $($('#host-mapping-row-template').parseTemplate(json)).appendTo($('#table-host-mapping tbody'));
            $('select', $row).val(json.DefaultCulture);
        };

        this.onBtnRemoveClick = function ($guid) {
            $('tr[id="' + $guid + '"]').remove();
        };

        this.refresh = function () {
            if (self.startLoad) self.startLoad();
            jQuery.getJSON(this.getHostMappingAction, null, function (json) {
                if (self.stopLoad) self.stopLoad();
                if (!json.success) { alert(json.error); return; }
                $('#table-host-mapping > tbody').html('');
                for (var i = 0; i < json.hostMapping.length; i++) {
                    self.tabHostMapping.addNewRow(json.hostMapping[i]);
                }
            });
        };

        this.onLnkSaveClick = function () {
            $('#formHostMapping').html('');
            var rows = $('#table-host-mapping > tbody > tr');

            var total = 0;
            for (var i = 0; i < rows.length; i++) {
                var hostname = $('input[type=hidden]', rows[i]).val();
                var mappingHostname = $('input[type=text]', rows[i]).val();
                if (hostname == '' || mappingHostname == '')
                    continue;
                $('#formHostMapping').append('<input type="hidden" name="HostName_' + total + '" value="' + hostname.htmlEncode() + '" />');
                $('#formHostMapping').append('<input type="hidden" name="MappingHostName_' + total + '" value="' + mappingHostname.htmlEncode() + '" />');
                total++;
            }
            $('#formHostMapping').append('<input type="hidden" name="total" value="' + total.toString(10) + '" />');

            if (self.startLoad) self.startLoad();
            var options = {
                type: 'POST',
                dataType: 'json',
                success: function (json) {
                    if (self.stopLoad) self.stopLoad();
                    if (!json.success) { alert(json.error); return; }
                }
            };
            $('#formHostMapping').ajaxForm(options);
            $('#formHostMapping').submit();
        };

        this.init = function () {
            this.refresh();
            $('#host-mapping-links a.refresh').bind('click', this, function (e) { e.preventDefault(); e.data.refresh(); });
            $('#host-mapping-links a.save').bind('click', this, function (e) { e.preventDefault(); e.data.onLnkSaveClick(); });
            $('#table-host-mapping .col-tools a').bind('click', this, function (e) { e.preventDefault(); e.data.addNewRow({ HostName: '', DefaultCulture: '' }); });

            $('#host-mapping-links a.history').click(function (e) {
                var wnd = window.open($(this).attr('href'), null, "width=1000,height=700,toolbar=no,location=no,directories=0,status=yes,menubar=no,copyhistory=no");
                if (wnd) e.preventDefault();
            });
        };

        this.init();
    }
</script>
</ui:ExternalJavascriptControl>
