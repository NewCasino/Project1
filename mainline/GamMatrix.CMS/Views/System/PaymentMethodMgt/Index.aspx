<%@ Page Title="Payment Methods Management" Language="C#" MasterPageFile="~/Views/System/Content.master" Inherits="CM.Web.ViewPageEx<CM.db.cmSite>"%>

<%@ Import Namespace="GamMatrix.CMS.Controllers.System" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
    <link rel="stylesheet" type="text/css" href="<%= Url.Content( "~/App_Themes/AdminConsole/PaymentMethodMgt/Index.css") %>" />
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<div style="padding:10px;">

<div id="payment-method-mgt-tabs">
	<ul>
		<li><a href="#tabs-1">Properties</a></li>
        <li><a href="#tabs-2">Visibility & Order</a></li>
        <li><a href="#tabs-3">Fallback Visibility</a></li>
        <li><a href="#tabs-4">Bank Withdrawal</a></li>
	</ul>
	<div id="tabs-1">
        <% Html.RenderPartial("TabProperties", this.ViewData.Merge(new { cmSite = this.Model })); %>
	</div>
    <div id="tabs-2">
        <% Html.RenderPartial("TabVisibilityOrder", this.ViewData.Merge(new { cmSite = this.Model })); %>
    </div>
    <div id="tabs-3">
        <% Html.RenderPartial("TabFallbackVisibilityOrder", this.ViewData.Merge(new { cmSite = this.Model })); %>
    </div>
    <div id="tabs-4">
        <% Html.RenderPartial("TabBankWithdrawal", this.ViewData.Merge(new { cmSite = this.Model })); %>
    </div>
</div>


<ui:ExternalJavascriptControl runat="server" AutoDisableInPostbackRequest="true">
<script type="text/javascript">
function PaymentMethodMgt() {
    self.PaymentMethodMgt = this;
    $('#payment-method-mgt-tabs').tabs();

    this.init = function () {
        this.tabProperties = new TabProperties(this);
        this.tabVisibilityOrder = new TabVisibilityOrder(this);
        this.tabFallbackVisibilityOrder = new TabFallbackVisibilityOrder(this);
    };

    this.init();
}
$(function () { new PaymentMethodMgt(); });
</script>
</ui:ExternalJavascriptControl>



</div>

</asp:Content>



