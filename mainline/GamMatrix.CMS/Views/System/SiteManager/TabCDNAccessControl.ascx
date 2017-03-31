<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.db.cmSite>" %>

<script type="text/C#" runat="server">
    private SelectList GetIPAddressList()
    {
        SiteCDNAccessRule rule = SiteCDNAccessRule.Get(this.Model, false);
        string[] ipCDNAddresses = rule.IPAddresses.Keys.ToArray();
        return new SelectList(ipCDNAddresses);
    }

    private bool IsCMSSystemAdminUser
    {
        get {
            return Profile.IsInRole("CMS System Admin");
        }
    }    
</script>

<div id="cdn-access-control-links" class="site-mgr-links">
    <ul>
        <li>
            <a href="<%= this.Url.RouteUrl( "HistoryViewer", new {  
                        @action = "Dialog",
                        @distinctName = this.Model.DistinctName.DefaultEncrypt(),
                        @relativePath = "/.config/site_cdn_access_rule.setting".DefaultEncrypt(),
                        @searchPattner = "",
                        } ).SafeHtmlEncode()  %>"
                target="_blank" class="history">Change history...</a>
        </li>
    </ul>
</div>
<hr class="seperator" />
<% using (Html.BeginRouteForm("SiteManager"
       , new { @action = "SaveCDNAccessControl", @distinctName = this.Model.DistinctName.DefaultEncrypt() }
       , FormMethod.Post
       , new { @id = "formSaveCDNAccessControl" }))
   { %>

<ul style="list-style-type:none; margin:0px; padding:0px;">
    <li>
        <label>The following IP address(es) will skip the CDN configuration.</label>
    </li>
</ul>
<br />
<ui:InputField id="fldipCDNAddresses" runat="server">
    <LabelPart>
    IP Address(es):
    </LabelPart>
    <ControlPart>
        
        <table>
            <tr>
                <td>
                    <%: Html.DropDownList("ddlCDNIPAddress", GetIPAddressList(), new { @size = "20", @id = "ddlCDNIPAddress" })%>
                </td>
                <td valign="top">
                <%if (IsCMSSystemAdminUser) { %>
                    <img src="/images/icon/delete_gray.png" id="btnRemoveCDNIPAddress" style="cursor: default;">
                <%} %>
                </td>
            </tr>
            <tr>
                <td>
                    <%: Html.TextBox("newCDNIPAddress", "", new { @id = "txtNewCDNIPAddress" })%>
                </td>
                <td valign="top">
                <%if (IsCMSSystemAdminUser) { %>
                    <img style="cursor:pointer" src="/images/icon/add.png" id="btnAddCDNIPAddress">
                <%} %>
                </td>
            </tr>
        </table>    
    </ControlPart>
</ui:InputField>


<div class="buttons-wrap">
<%if (IsCMSSystemAdminUser) { %>
    <ui:Button runat="server" ID="btnSaveCDNAccessControl" type="submit">Save</ui:Button>
<%} %>
</div>

<% } %>

<script type="text/javascript">
    $(function () {
        InputFields.initialize($("#formSaveCDNAccessControl"));

        $('#ddlCDNIPAddress').change(function () {
            var selected = $("#ddlCDNIPAddress > option:selected").length == 1;
            $('#btnRemoveCDNIPAddress').attr('src', selected ? "/images/icon/delete.png" : "/images/icon/delete_gray.png")
            .css('cursor', selected ? 'pointer' : 'default');
        });

        $('#btnRemoveCDNIPAddress').click(function (e) {
            $("#ddlCDNIPAddress > option:selected").remove();
            $('#btnRemoveCDNIPAddress').attr('src', "/images/icon/delete_gray.png")
            .css('cursor', 'default');
        });

        $('#btnAddCDNIPAddress').click(function (e) {
            var ip = $('#txtNewCDNIPAddress').val();
            if (ip.length > 0) {
                $('<option></option>').text(ip).val(ip).appendTo($('#ddlCDNIPAddress'));
            }
            $('#txtNewCDNIPAddress').val('');
        });

        $('#btnSaveCDNAccessControl').click(function (e) {
            e.preventDefault();

            $('#formSaveCDNAccessControl input[name="ipCDNAddresses"]').remove();
            var options = $('#ddlCDNIPAddress option');
            for (var i = 0; i < options.length; i++) {
                $('<input type="hidden" name="ipAddresses" />').val(options.eq(i).val()).appendTo($('#formSaveCDNAccessControl'));
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
            $('#formSaveCDNAccessControl').ajaxForm(options);
            $('#formSaveCDNAccessControl').submit();
        });

        $('#cdn-access-control-links a.history').click(function (e) {
            var wnd = window.open($(this).attr('href'), null, "width=1000,height=700,toolbar=no,location=no,directories=0,status=yes,menubar=no,copyhistory=no");
            if (wnd) e.preventDefault();
        });
    });
</script>