<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.db.cmSite>" %>
<script type="text/C#" runat="server">

    private SiteRestrictDomainRule rule = new SiteRestrictDomainRule();

    protected override void OnPreRender(EventArgs e)
    {
        rule = GetCurrentRule();
        base.OnPreRender(e);
    }

    private bool IsDomainRestrictedMode()
    {


        return rule.IsDomainRestrictedMode;
    }
    private string GetCurrnetMainDomainName()
    {

        return rule.MainDomainName;
    }
    private SiteRestrictDomainRule GetCurrentRule()
    {
        return CM.Sites.SiteRestrictDomainRule.Get(this.Model.DistinctName, false);
    }
    private List<SelectListItem> GetEnabledDomainsList(bool isEnabled)
    {
        List<string> rules = isEnabled ? rule.EnabledDomainList : rule.DisabledDomainList;
        List<SelectListItem> ruleList = new List<SelectListItem>();
        if (rules == null)
        {
            return ruleList;
        }
        for (int i = 0; i < rules.Count; i++)
        {

            SelectListItem ruleItem = new SelectListItem();
            ruleItem.Text = rules[i];
            ruleItem.Value = rules[i];
            ruleList.Add(ruleItem);
        }
        return ruleList;
    }

    private bool IsCMSSystemAdminUser
    {
        get
        {
            return Profile.IsInRole("CMS System Admin");
        }
    }   
</script>
<style>
.DomainList table th {	text-align: left;}
#fldMainDomainName {	padding-top: 20px;	padding-bottom: 10px;}
.domainErrorMsg ~ .buttons-wrap {	padding-top: 20px;	text-align: left;	padding-left: 0;}
.DomainList table {	width: 100%;	max-width: 760px;}
.DomainList tbody td {	max-width: 400px;	text-align: center;}
.domainControlButtons button {	margin-bottom: 30px;}
.DomainList select { width: 100%;	max-width: 350px;	margin: 0 auto;	min-width: 300px;}
</style>
<div id="domain-access-control-links" class="site-mgr-links">
  <ul>
    <li><a href="javascript:void(0)" target="_self" class="refresh">Refresh</a></li>
    <li>|</li>
    <li> <a href="<%= this.Url.RouteUrl( "HistoryViewer", new {  
                        @action = "Dialog",
                        @distinctName = this.Model.DistinctName.DefaultEncrypt(),
                        @relativePath = "/.config/site_domain_access_rule.setting".DefaultEncrypt(),
                        @searchPattner = "",
                        } ).SafeHtmlEncode()  %>"
                target="_blank" class="history">Change history...</a> </li>
  </ul>
</div>
<hr class="seperator" />
<% using (Html.BeginRouteForm("SiteManager"
       , new { @action = "SaveDomainControl", @distinctName = this.Model.DistinctName.DefaultEncrypt() }
       , FormMethod.Post
       , new { @id = "formSaveDomainControl" }))
   { %>
<ul style="list-style-type: none; margin: 0px; padding: 0px;">
  <li>
    <%: Html.RadioButton( "isDomainRestrictedMode", true, IsDomainRestrictedMode(), new { @id = "btnEnableDomainRestrictedMode"})  %>
    <label for="btnEnableWhitelistMode">Enable Domain Restricted mode -- only allow the following domain name to access.</label>
  </li>
  <li>
    <%: Html.RadioButton("isDomainRestrictedMode", false, !IsDomainRestrictedMode(), new { @id = "btnDisableDomainRestrictedMode"})%>
    <label for="btnEnableBlacklistMode">Disable Domain Restricted mode -- All domain name can be access.</label>
  </li>
</ul>
<ui:InputField ID="fldMainDomainName" runat="server">
  <labelpart> Main Domain name: </labelpart>
  <controlpart> <%= Html.TextBox("MainDomainName",GetCurrnetMainDomainName(), new { @id = "txtMainDomainName" , @validator = ClientValidators.Create().Required("Please enter the Main domain name.") })%> </controlpart>
</ui:InputField>
<div class="DomainList">
  <table>
    <thead>
      <tr>
        <th>Enabled domains</th>
        <th></th>
        <th>Disabled domains</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td><%: Html.DropDownList("ddlEnabledDomains", GetEnabledDomainsList(true), new { @size = "20", @id = "ddlEnabledDomains" })%></td>
        <td><div class="domainControlButtons">
            <ui:Button runat="server" ID="btnEnable" type="button"> <<< </ui:Button>
            <br />
            <ui:Button runat="server" ID="btnDisable" type="button"> >>> </ui:Button>
          </div></td>
        <td><%: Html.DropDownList("ddlDisabledDomains", GetEnabledDomainsList(false), new { @size = "20", @id = "ddlDisabledDomains" })%></td>
      </tr>
    </tbody>
  </table>
</div>
<div class="domainErrorMsg"></div>
<div class="buttons-wrap">
  <%if (IsCMSSystemAdminUser)
      { %>
  <ui:Button runat="server" ID="btnSubmitDomainChanges" type="sumbit"> Save </ui:Button>
  <%} %>
</div>
<%} %>
<script type="text/javascript">
    var HostnamesActionUrl = '<%= Url.RouteUrl( "SiteManager", new { @action = "GetHostNames", @distinctName = this.Model.DistinctName.DefaultEncrypt() }).SafeJavascriptStringEncode() %>';
    Array.prototype.Contains = function (item) {
        for (i = 0; i < this.length; i++) { 
            if (this[i] == item || this[i].HostName.toLowerCase() == item.toLowerCase()) { return true; }
        }
        return false;
    };
    //Array.prototype.unique = function () {
    //    var res = [], hash = {};
    //    for (var i = 0, elem; (elem = this[i]) != null; i++) {
    //        if (!hash[elem]) {
    //            res.push(elem);
    //            hash[elem] = true;
    //        }
    //    }
    //    return res;
    //}
    $(function () {
        <%if (!IsCMSSystemAdminUser)
          {%>
        $("#btnEnableWhitelistMode").attr("disabled", "disabled");
        $("#btnEnableBlacklistMode").attr("disabled", "disabled");
        <%} %>
        function refreshDomainAccessList() {
            if (self.startLoad) self.startLoad();
            if ($('#ddlEnabledDomains option').length < 1 && $('#ddlDisabledDomains option').length < 1) {
                jQuery.getJSON(HostnamesActionUrl, null, function (json) {
                    if (self.stopLoad) self.stopLoad();
                    if (!json.success) { alert(json.error); return; }
                    if ($("#txtMainDomainName").val() == "") {
                        $("#txtMainDomainName").val(json.hosts[0].HostName);
                    }
                    for (var i = 0; i < json.hosts.length; i++) {
                        $("#ddlEnabledDomains").append("<option value='" + json.hosts[i].HostName + "'>" + json.hosts[i].HostName + "</option>");
                    }
                    if (self.stopLoad) self.stopLoad();
                });
            } else {
                jQuery.getJSON(HostnamesActionUrl, null, function (json) {
                    if (self.stopLoad) self.stopLoad();
                    if (!json.success) { alert(json.error); return; }
                    for (var i = 0; i < json.hosts.length; i++) {
                        var HostName = json.hosts[i].HostName;
                        if ($("#ddlEnabledDomains option[value='" + HostName + "']").length >= 1) {
                            $("#ddlEnabledDomains option[value='" + HostName + "']").remove();
                            $("#ddlEnabledDomains").append("<option value='" + HostName.toLowerCase() + "'>" + HostName.toLowerCase() + "</option>");
                        }
                        if ($("#ddlDisabledDomains option[value='" + HostName + "']").length >= 1) {
                            $("#ddlDisabledDomains option[value='" + HostName + "']").remove();
                            $("#ddlDisabledDomains").append("<option value='" + HostName.toLowerCase() + "'>" + HostName.toLowerCase() + "</option>");
                        }
                        if ($("#ddlEnabledDomains option[value='" + HostName.toLowerCase() + "']").length < 1 && $("#ddlDisabledDomains option[value='" + HostName.toLowerCase() + "']").length < 1) {
                            $("#ddlEnabledDomains").append("<option value='" + HostName.toLowerCase() + "'>" + HostName.toLowerCase() + "</option>");
                        }
                    }
                    for (var i = 0 ; i < $("#ddlEnabledDomains option").length; i++) {
                        var opt = $("#ddlEnabledDomains option[index=" + i + "]");
                        if (!json.hosts.Contains(opt.val().toLowerCase())) {
                            opt.remove();
                        }
                    }
                    for (var i = 0 ; i < $("#ddlDisabledDomains option").length; i++) {
                        var opt = $("#ddlDisabledDomains option[index=" + i + "]");
                        if (!json.hosts.Contains(opt.val().toLowerCase())) {
                            opt.remove();
                        }
                    }
                    if (self.stopLoad) self.stopLoad();
                });
            }
        }
        $('#domain-access-control-links a.refresh').bind('click', this, function (e) {
            e.preventDefault();
            refreshDomainAccessList();
        });
        InputFields.initialize($("#formSaveDomainControl"));
        $('#btnSubmitDomainChanges').click(function (e) {
            e.preventDefault();
            $(".domainErrorMsg").html("");
            $('#formSaveDomainControl input[name="EnabledDomains"]').remove();
            $('#formSaveDomainControl input[name="DisabledDomains"]').remove();
            var options = $('#ddlEnabledDomains option');
            for (var i = 0; i < options.length; i++) {
                $('<input type="hidden" name="EnabledDomains" />').val(options.eq(i).val().toLowerCase()).appendTo($('#formSaveDomainControl'));
            }
            var options = $('#ddlDisabledDomains option');
            for (var i = 0; i < options.length; i++) {
                $('<input type="hidden" name="DisabledDomains" />').val(options.eq(i).val().toLowerCase()).appendTo($('#formSaveDomainControl'));
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
            $('#formSaveDomainControl').ajaxForm(options);
            $('#formSaveDomainControl').submit();
        });
        $("#ddlEnabledDomains").dblclick(function () {
            $("#btnDisable").click();
        });
        $("#ddlDisabledDomains").dblclick(function () {
            $("#btnEnable").click();
        });
        $("#btnDisable").click(function () {
            if ($("#ddlEnabledDomains option").length == 1) {
                $(".domainErrorMsg").html("You have to keep 1 domain enabled at least .");
                return;
            }
            if ($("#ddlEnabledDomains").val().toLowerCase() == $("#txtMainDomainName").val().toLowerCase() ) {
                $(".domainErrorMsg").html("You have to keep the main domain enabled .");
                return;

            }
            if ($("#ddlEnabledDomains").val() != null) {
                $(".domainErrorMsg").html("");
                $("#ddlDisabledDomains option[value='" + $("#ddlEnabledDomains").val() + "']").remove();
                $("#ddlDisabledDomains").append("<option value='" + $("#ddlEnabledDomains").val() + "'>" + $("#ddlEnabledDomains").val() + "</option>");
                $("#ddlEnabledDomains option[value='" + $("#ddlEnabledDomains").val() + "']").remove();
            } else {
                $(".domainErrorMsg").html("Please chose an enabled domain first");
            }
        });
        $("#btnEnable").click(function () {
            if ($("#ddlDisabledDomains").val() != null) {
                $(".domainErrorMsg").html("");
                $("#ddlEnabledDomains option[value='" + $("#ddlDisabledDomains").val() + "']").remove();
                $("#ddlEnabledDomains").append("<option value='" + $("#ddlDisabledDomains").val() + "'>" + $("#ddlDisabledDomains").val() + "</option>");
                $("#ddlDisabledDomains option[value='" + $("#ddlDisabledDomains").val() + "']").remove();
            } else {
                $(".domainErrorMsg").html("Please chose a disabled domain first");

            }

        });

        refreshDomainAccessList();
    });
</script> 
