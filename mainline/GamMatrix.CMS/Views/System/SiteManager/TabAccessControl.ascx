<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.db.cmSite>" %>

<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Runtime.Serialization.Formatters.Binary" %>
<script type="text/C#" runat="server">
    private SelectList GetIPAddressList()
    {
        SiteAccessRule rule = SiteAccessRule.Get(this.Model, false);
        string[] ipAddresses = rule.IPAddresses.Keys.ToArray();
        return new SelectList(ipAddresses);
    }

    private bool IsSoftLaunchMode()
    {
        SiteAccessRule rule = SiteAccessRule.Get(this.Model, false);
        return rule.AccessMode == SiteAccessRule.AccessModeType.SoftLaunch;
    }

    private bool IsWhitelistMode()
    {
        SiteAccessRule rule = SiteAccessRule.Get(this.Model, false);
        if (rule.AccessMode == SiteAccessRule.AccessModeType.NotSet)
            return rule.IsWhitelistMode;
        else
            return rule.AccessMode == SiteAccessRule.AccessModeType.Whitelist;
    }

    private bool IsBlacklistMode()
    {
        SiteAccessRule rule = SiteAccessRule.Get(this.Model, false);
        if (rule.AccessMode == SiteAccessRule.AccessModeType.NotSet)
            return !rule.IsWhitelistMode;
        else
            return rule.AccessMode == SiteAccessRule.AccessModeType.Blacklist;
    }

    private string GetSoftLaunchNumber()
    {
        SiteAccessRule rule = SiteAccessRule.Get(this.Model, false);
        if (rule.AccessMode == SiteAccessRule.AccessModeType.NotSet)
            return "10";
        
        return rule.SoftLaunchNumber.ToString(CultureInfo.InvariantCulture);
    }

    private string GetBlockedMessage()
    {
        SiteAccessRule rule = SiteAccessRule.Get(this.Model, false);
        return rule.BlockedMessage.DefaultIfNullOrEmpty("Your IP address [$IP$] is blocked.");
    }

    private bool IsCMSSystemAdminUser
    {
        get
        {
            return Profile.IsInRole("CMS System Admin");
        }
    }
    public string GetSupportedCountryHtml()
    {
        StringBuilder html = new StringBuilder();
        html.Append("<a class=\"lnk-edit-supported-countries\" href=\"javascript:void(0)\" target=\"self\">");
        SiteAccessRule rule = SiteAccessRule.Get(this.Model, false);
        Finance.CountryList countryList = new Finance.CountryList();
        try
        {
            countryList.List = rule.CountriesList;
            countryList.Type = rule.CountriesFilterType == SiteAccessRule.FilterType.Include ? Finance.CountryList.FilterType.Include : Finance.CountryList.FilterType.Exclude;
        }
        catch
        {
            countryList = new Finance.CountryList();
            countryList.Type = Finance.CountryList.FilterType.Exclude;
        }
        html.Append(FormatCountryList(countryList).SafeHtmlEncode());
        html.Append("</a>");

        return html.ToString();
    }

    private string FormatCountryList(Finance.CountryList countryList)
    {
        List<CountryInfo> countries = CountryManager.GetAllCountries(this.Model.DistinctName);

        StringBuilder text = new StringBuilder();
        if (countryList.Type == Finance.CountryList.FilterType.Exclude)
        {
            if (countryList.List == null ||
                countryList.List.Count == 0)
            {
                text.Append("All");
            }
            else
            {
                text.Append("Exclude ");
            }
        }
        else
        {
            if (countryList.List == null ||
                countryList.List.Count == 0)
            {
                text.Append("None");
            }
        }

        if (countryList.List != null)
        {
            foreach (int countryID in countryList.List)
            {
                CountryInfo country = countries.FirstOrDefault(c => c.InternalID == countryID);
                if (country != null)
                    text.AppendFormat(CultureInfo.InvariantCulture, " {0} ,", country.EnglishName);
            }
            if (text.Length > 0)
                text.Remove(text.Length - 1, 1);
        }
        return text.ToString();
    }
</script>
<style>
    a.lnk-edit-supported-countries {
        width: 350px;
        display: block;
    }
</style>
<div id="access-control-links" class="site-mgr-links">
    <ul>
        <li>
            <a href="<%= this.Url.RouteUrl( "HistoryViewer", new {  
                        @action = "Dialog",
                        @distinctName = this.Model.DistinctName.DefaultEncrypt(),
                        @relativePath = "/.config/site_access_rule.setting".DefaultEncrypt(),
                        @searchPattner = "",
                        } ).SafeHtmlEncode()  %>"
                target="_blank" class="history">Change history...</a>
        </li>
    </ul>
</div>
<hr class="seperator" />
<% using (Html.BeginRouteForm("SiteManager"
       , new { @action = "SaveAccessControl", @distinctName = this.Model.DistinctName.DefaultEncrypt() }
       , FormMethod.Post
       , new { @id = "formSaveAccessControl" }))
   { %>

<ul style="list-style-type: none; margin: 0px; padding: 0px;">
    <li class="access-mode">
        <%: Html.RadioButton( "accessMode", SiteAccessRule.AccessModeType.SoftLaunch, IsSoftLaunchMode(), new { @id = "btnEnableSoftLaunchMode"})  %>
        <label for="btnEnableSoftLaunchMode">Soft-launch no: [<%: Html.TextBox("softLaunchNumber", GetSoftLaunchNumber(), new { @id = "txtSoftLaunchNumber", @class = "soft-launch-textbox", @maxlength = "3" })%>] (No. of Uniques IP permitted) </label>
        <span id="spnSoftLaunchMessage">Used 10; Remaining: 0</span>
    </li>
    <li class="access-mode">
        <%: Html.RadioButton( "accessMode", SiteAccessRule.AccessModeType.Whitelist, IsWhitelistMode(), new { @id = "btnEnableWhitelistMode"})  %>
        <label for="btnEnableWhitelistMode">Whitelist mode (restricted mode) -- only allow the following IP address(es) to access.</label>
    </li>
    <li class="access-mode">
        <%: Html.RadioButton("accessMode", SiteAccessRule.AccessModeType.Blacklist, IsBlacklistMode(), new { @id = "btnEnableBlacklistMode"})%>
        <label for="btnEnableBlacklistMode">Blacklist mode (live mode) -- only disallow the following IP address(es) to access.</label>
    </li>
</ul>
<br />
<ui:InputField ID="fldIPAddresses" runat="server">
    <labelpart>
    IP Address(es):
    </labelpart>
    <controlpart>
        
        <table>
            <tr>
                <td>
                    <%: Html.DropDownList("ddlIPAddress", GetIPAddressList(), new { @size = "20", @id = "ddlIPAddress" })%>
                </td>
                <td valign="top">
                <%if (IsCMSSystemAdminUser)
                  { %>
                    <img src="/images/icon/delete_gray.png" id="btnRemoveIPAddress" style="cursor: default;">
                <%} %>
                </td>
            </tr>
            <tr>
                <td>
                    <%: Html.TextBox("newIPAddress", "", new { @id = "txtNewIPAddress" })%>
                </td>
                <td valign="top">
                <%if (IsCMSSystemAdminUser)
                  { %>
                    <img style="cursor:pointer" src="/images/icon/add.png" id="btnAddIPAddress">
                <%} %>
                </td>
            </tr>
        </table>    
    </controlpart>
</ui:InputField>
<ui:InputField ID="fldCountries" runat="server">
    <labelpart>
    Supported Country(s)
    </labelpart>
    <controlpart> 
        <%=GetSupportedCountryHtml()%>
    </controlpart>
</ui:InputField>

<%--<li><strong>Supported Country(s)</strong> : <%=GetSupportedCountryHtml(path)%></li>--%>

<ui:InputField ID="fldBlockedMessage" runat="server">
    <labelpart>
    Blocked Message:
    </labelpart>
    <controlpart>
        <%: Html.TextBox("blockedMessage", GetBlockedMessage())%>        
    </controlpart>
</ui:InputField>


<div class="buttons-wrap">
    <%if (IsCMSSystemAdminUser)
      { %>
    <ui:Button runat="server" ID="btnSaveAccessControl" type="submit">Save</ui:Button>
    <%} %>
</div>

<% } %>

<script type="text/javascript">
    function TabAccessControl() {
        self.tabAccessControl = this;

        this.updateSoftLaunch = function () {
            var total = parseInt($('#txtSoftLaunchNumber').val());
            if (isNaN(total)) {
                $('#spnSoftLaunchMessage').hide();
                return;
            }

            var used = $('#ddlIPAddress option').length;
            var remain = total - used;
            if (remain < 0)
                remain = 0;
            var message = 'Used ' + used + '; Remaining: ' + remain;
            $('#spnSoftLaunchMessage').html(message);
            $('#spnSoftLaunchMessage').show();
        };

        this.refresh = function () {
            if (self.startLoad) self.startLoad();
            self._scrollTop = $(self).scrollTop();
            var url = '<%= this.Url.RouteUrl( "SiteManager", new { @action = "TabAccessControl", @distinctName = this.Model.DistinctName.DefaultEncrypt() }).SafeJavascriptStringEncode() %>';
            $('#access-control-links').parent().load(url, function () {
                if (self.stopLoad) self.stopLoad();
                $(self).scrollTop(self._scrollTop);
            });
        };

        this.init = function () {
            <%if (!IsCMSSystemAdminUser)
            {%>
            $("#btnEnableSoftLaunchMode").attr("disabled", "disabled");
            $("#btnEnableWhitelistMode").attr("disabled", "disabled");
            $("#btnEnableBlacklistMode").attr("disabled", "disabled");
            $("#txtSoftLaunchNumber").attr("disabled", "disabled");
            <%} %>
            InputFields.initialize($("#formSaveAccessControl"));

            $('#ddlIPAddress').change(function () {
                var selected = $("#ddlIPAddress > option:selected").length == 1;
                $('#btnRemoveIPAddress').attr('src', selected ? "/images/icon/delete.png" : "/images/icon/delete_gray.png")
                .css('cursor', selected ? 'pointer' : 'default');
            });

            $('#btnRemoveIPAddress').click(function (e) {
                $("#ddlIPAddress > option:selected").remove();
                $('#btnRemoveIPAddress').attr('src', "/images/icon/delete_gray.png")
                .css('cursor', 'default');
                self.tabAccessControl.updateSoftLaunch();
            });

            $('#btnAddIPAddress').click(function (e) {
                var ip = $('#txtNewIPAddress').val();
                if (ip.length > 0) {
                    $('<option></option>').text(ip).val(ip).appendTo($('#ddlIPAddress'));
                }
                $('#txtNewIPAddress').val('');
                self.tabAccessControl.updateSoftLaunch();
            });

            $('#btnSaveAccessControl').click(function (e) {
                e.preventDefault();

                $('#formSaveAccessControl input[name="ipAddresses"]').remove();
                var options = $('#ddlIPAddress option');
                for (var i = 0; i < options.length; i++) {
                    $('<input type="hidden" name="ipAddresses" />').val(options.eq(i).val()).appendTo($('#formSaveAccessControl'));
                }

                if (self.startLoad) self.startLoad();
                var options = {
                    type: 'POST',
                    dataType: 'json',
                    success: function (json) {
                        if (self.stopLoad) self.stopLoad();
                        if (!json.success) { alert(json.error); return; }
                    }
                };
                $('#formSaveAccessControl').ajaxForm(options);
                $('#formSaveAccessControl').submit();
            });

            $('#access-control-links a.history').click(function (e) {
                var wnd = window.open($(this).attr('href'), null, "width=1000,height=700,toolbar=no,location=no,directories=0,status=yes,menubar=no,copyhistory=no");
                if (wnd) e.preventDefault();
            });

            $('a.lnk-edit-supported-countries').click(function (e) {
                e.preventDefault();
                var url = '<%= this.Url.RouteUrl( "SiteManager", new { @action = "SupportedCountry", @distinctName = this.Model.DistinctName.DefaultEncrypt() }).SafeJavascriptStringEncode()%>';
                $('<div class="popup-dialog"><img src="/images/icon/loading.gif" /></div>').appendTo(document.body).load(url).dialog({
                    autoOpen: true,
                    height: 'auto',
                    minHeight: 50,
                    position: [100, 50],
                    width: 700,
                    modal: true,
                    resizable: false,
                    close: function (ev, ui) { $("div.popup-dialog").dialog('destroy'); $("div.popup-dialog").remove(); }
                });
            });

            $('#txtSoftLaunchNumber').allowNumberOnly();

            $('#txtSoftLaunchNumber').focus(function (e) {
                e.preventDefault();

                $('#btnEnableSoftLaunchMode').click();
            });

            $('#txtSoftLaunchNumber').keyup(function (e) {
                e.preventDefault();
                self.tabAccessControl.updateSoftLaunch();
            });

            self.tabAccessControl.updateSoftLaunch();
        };

        this.init();
    }

    $(function () {
        var tab = new TabAccessControl();
    });
</script>
