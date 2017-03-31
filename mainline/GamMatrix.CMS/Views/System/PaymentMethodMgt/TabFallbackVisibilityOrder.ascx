<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="CM.db" %>

<% 
    cmSite domain = this.ViewData["cmSite"] as cmSite;
%>

<div id="fallback-visibility-order-links" class="payment-method-mgt-links">
<ul>
    <li><a href="javascript:void(0)" target="_self" class="refresh">Refresh</a></li>
    <li>|</li>
    <li><a href="javascript:void(0)" target="_self" class="save">Save</a></li>
    <li>|</li>
    <li>
        <a href="<%= this.Url.RouteUrl( "HistoryViewer", new {  
            @action = "Dialog",
            @distinctName = domain.DistinctName.DefaultEncrypt(),
            @relativePath = "/.config/PaymentMethods".DefaultEncrypt(),
            @searchPattner = ".%",
            } ).SafeHtmlEncode()  %>" target="_blank" class="history">Change history...</a>
    </li>
</ul>
</div>

<hr class="seperator" />

<div style="margin-top: 20px; padding: 0pt 0.7em;" class="ui-state-error ui-corner-all"> 
	<p><span style="float: left; margin-right: 0.3em;" class="ui-icon ui-icon-alert"></span>
    <p style="color:red;">
	<strong>WARNING</strong>
    <ul style="font-size:16px; color:red; font-family:Consolas">
        <% if (domain.DistinctName == "Shared") { %> 
            <li>Enabling fallback mode you <strong>ACTIVATE THE FALLBACK SCENARIO</strong> for whole operator or the batch of operators!</li>
            <li>Please make sure you understand what you do and understand the activation <strong>RISK</strong>!</li>
        <% } %>
        <li>Enabling payment method below only affects visibility in the frontend!</li>
        <li>It <strong>DOES NOT</strong> mean this payment method works!</li>
        <li>You <strong>MUST</strong> guarantee that the payment method is configured in backend with correct bank details before show it!</li>
        <li>If you have any query, please contact Account Manager.</li>
    </ul>
    </p>
</div>

<% 
    using (Html.BeginRouteForm("PaymentMethodMgt", new
    {
        @action = "SaveFallbackVisibilityAndOrder",
        @distinctName = domain.DistinctName.DefaultEncrypt()
    }, FormMethod.Post
    , new { @id = "formSaveFallbackVisibilityAndOrder" }
    ))
    {
        var categories = PaymentMethodManager.GetCategories(domain, "en");

        var paymentMethods = PaymentMethodManager.GetPaymentMethods(domain, false).ToArray();

if (domain.DistinctName == "Shared") { %>
<p>
    <%: Html.CheckBox("fallbackMode", PaymentMethodManager.GetFallbackMode(false), new { @onclick = "falbackModeConfirm()" }) %>
    <strong>ENABLE FALLBACK MODE</strong>
</p> 
<% } else { %>
<br/>
<% }
    foreach (PaymentMethodCategory category in categories)
    {  %>

<div class="pm-category">
    <%: Html.H5(category.GetDisplayName(domain, "en"))%>

    <% 
    foreach (PaymentMethod paymentMethod in paymentMethods.Where(p => p.Category == category).OrderBy(p => p.Ordinal))
    {
        if (!string.Equals(domain.DistinctName, "Shared", StringComparison.InvariantCultureIgnoreCase) ||
                !string.Equals(domain.DistinctName, "MobileShared", StringComparison.InvariantCultureIgnoreCase))
        {
            if (!GmCore.DomainConfigAgent.IsVendorEnabled(paymentMethod, domain))
                continue;
        }
            %>
            <div class="pm-item">
                <table cellpadding="5" cellspacing="0" border="0">
                    <tr>
                        <td valign="middle">
                            <%: Html.CheckBox(string.Format("enabled_{0}", paymentMethod.UniqueName.SafeHtmlEncode())
                            , paymentMethod.IsVisibleDuringFallback
                            )%>
                        </td>
                        <td valign="middle"><div class="icon" style="background-image:url('<%= paymentMethod.GetImageUrl(domain) %>')"></div></td>
                        <td valign="middle"><span class="<%= paymentMethod.IsDisabledDuringFallback ? "disabled" : "" %>"><%= paymentMethod.UniqueName.SafeHtmlEncode()%></span></td>
                    </tr>
                </table>
                <input type="hidden" name="ordinal_<%= paymentMethod.UniqueName.SafeHtmlEncode() %>" value="<%= paymentMethod.Ordinal %>" />
            </div>
            <%
    }
    %>

</div>


<%      }
    }%>

<div style="clear:both"></div>



<ui:ExternalJavascriptControl ID="ExternalJavascriptControl1" runat="server" Enabled="false">
<script type="text/javascript">
    function falbackModeConfirm() {
        if (!confirm("Are you sure you want to change fallback mode?")) {
            document.getElementById("fallbackMode").checked = !document.getElementById("fallbackMode").checked;
        }
        return true;
    }

    function TabFallbackVisibilityOrder(viewEditor) {
        self.tabFallbackVisibilityOrder = this;

        this.init = function () {
            $('#fallback-visibility-order-links a.refresh').bind('click', this, function (e) {
                e.preventDefault();
                e.data.refresh();
            });
            $('#fallback-visibility-order-links a.save').bind('click', this, function (e) {
                e.preventDefault();
                e.data.save();
            });
            $('#fallback-visibility-order-links a.history').click(function (e) {
                var wnd = window.open($(this).attr('href'), null, "width=1000,height=700,toolbar=no,location=no,directories=0,status=yes,menubar=no,copyhistory=no");
                if (wnd) e.preventDefault();
            });
        };

        this.refresh = function () {
            if (self.startLoad) self.startLoad();
            var url = '<%= this.Url.RouteUrl( "PaymentMethodMgt", new { @action = "TabFallbackVisibilityOrder", @distinctName = (this.ViewData["cmSite"] as cmSite).DistinctName.DefaultEncrypt() }).SafeJavascriptStringEncode() %>';
            $('#fallback-visibility-order-links').parent().load(url, function () {
                if (self.stopLoad) self.stopLoad();
                self.tabFallbackVisibilityOrder.init();
            });
        };

        this.save = function () {
            var options = {
                type: 'POST',
                dataType: 'json',
                success: function (json) {
                    if (!json.success) { alert(json.error); }
                    if (self.stopLoad) self.stopLoad();
                }
            };
            if (self.startLoad) self.startLoad();
            $('#formSaveFallbackVisibilityAndOrder').ajaxForm(options);
            $('#formSaveFallbackVisibilityAndOrder').submit();
        };

        this.init();
    }
</script>
</ui:ExternalJavascriptControl>