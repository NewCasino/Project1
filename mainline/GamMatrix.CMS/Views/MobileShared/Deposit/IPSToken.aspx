<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<Finance.PaymentMethod>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GamMatrixAPI" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>

<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
	<div class="UserBox CenterBox">
		<div class="BoxContent">
			<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 4, CurrentStep = 1 }); %>
			<form action="<%= this.Url.RouteUrl("Deposit", new { action = "Prepare", paymentMethodName = Model.UniqueName }).SafeHtmlEncode() %>" method="post" id="formDepositAmount">
                
				<% Html.RenderPartial("/Components/GamingAccountSelector", new GamingAccountSelectorViewModel() 
					{
						ComponentId = "creditAccountID",
						SelectorLabel = this.GetMetadata(".GammingAccount_Label")
					}); %>
				
				<% Html.RenderPartial("/Components/BonusSelector", new BonusSelectorViewModel()); %>
				<% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel()); %>
			</form>
			<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="true" AppendToPageEnd="true">
				<script type="text/javascript">
				    $(function () {
				        var accountSelector = new GamingAccountSelector('#creditAccountIDSelector', true),
							bonusSelector = new BonusSelector();

				        accountSelector.evt.bind('bonus', function (data) {
				            bonusSelector.update(data);
				        });
					});

				    $(CMS.mobile360.Generic.input);
				</script>
			</ui:MinifiedJavascriptControl>
		</div>
	</div>
</asp:Content>
