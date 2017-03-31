<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Withdraw.AccountViewModel>" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GamMatrixAPI" %>

<div class="UserBox CenterBox">
	<div class="BoxContent">
		<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 4, CurrentStep = 1 }); %>
		<form action="<%= this.Url.RouteUrl("Withdraw", new { action = "Prepare", paymentMethodName = Model.PaymentDetails.UniqueName }).SafeHtmlEncode() %>" method="post" id="formWithdrawAmount">
            
			<% Html.RenderPartial("/Components/GamingAccountSelector", new GamingAccountSelectorViewModel()
				{
					ComponentId = "gammingAccountID",
					SelectorLabel = this.GetMetadata(".GammingAccount_Label")
				}); %>

			<% Html.RenderPartial("/Components/AmountSelector", new AmountSelectorViewModel
				{
					TransferType = TransType.Withdraw,
					PaymentDetails = Model.PaymentDetails
				}); %>

			<% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel()); %>
		</form>
	</div>
<//div>

<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="true" AppendToPageEnd="true">
<script type="text/javascript">
	$(function () {
		var amountSelector = new AmountSelector();
		var accountSelector = new GamingAccountSelector('#gammingAccountIDSelector', true);
		
		accountSelector.evt.bind('change', function (data) {
			amountSelector.update(data);
		});

		<% if(Model.LockCurrency != null)
			{ 
		%>
		amountSelector.lock('<%= this.Model.LockCurrency.SafeJavascriptStringEncode()%>');
		<% 
			} 
		%>
		<% if (Model.PaymentDetails.UniqueName == "TLNakit") 
			{%>
		AmountSelector.customAmountValidator = function(debitAmount, creditAmount){
			if (creditAmount % 1 != 0)
				return '<%= this.GetMetadata(".TLNakit_InvalidAmount").SafeJavascriptStringEncode() %>';
			return true;
		}
		<% } %>
	});
</script>
</ui:MinifiedJavascriptControl>