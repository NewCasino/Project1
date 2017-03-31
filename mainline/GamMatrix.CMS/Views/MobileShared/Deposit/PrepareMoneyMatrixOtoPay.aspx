<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrix.CMS.Models.MobileShared.Deposit.Prepare.PrepareOtoPayViewModel>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>

<%@ Import Namespace="GamMatrix.CMS.Models.Common.Components" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>

<asp:content contentplaceholderid="cphMain" runat="Server">
<div class="UserBox DepositBox CenterBox">
	<div class="BoxContent">
		<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 4, CurrentStep = 2 }); %>
		<form action="<%= this.Url.RouteUrl("Deposit", new { action = "PrepareTransaction", paymentMethodName = this.Model.PaymentMethod.UniqueName }).SafeHtmlEncode() %>" method="post" id="formPreparePayKasa">
            
			<% Html.RenderPartial("/Components/MultiFormState", Model.StateVars); %>

            <% Html.RenderPartial(
                 "/Components/MoneyMatrix_PaymentSolutionPayCard",
                 new MoneyMatrixPaymentSolutionPrepareViewModel(
                     TransactionType.Deposit,
                     "OtoPay",
                     inputFields: new List<MmInputField>
                     {
                        new MmInputField("VoucherCode", this.GetMetadata(".VoucherCardNumber_Label")) { IsRequired = true },
                        new MmInputField("SecurityKey", this.GetMetadata(".ValidationCode_Label")) { IsRequired = true }
                     })
                 {
                     UseDummyPayCard = true,
                     SupportedAmounts = new [] { "10", "15" , "20", "25", "30", "50", "60", "70", "80", "100", "150", "200", "250", "500", "1000" },
                     SupportedCurrency = "EUR"
                 }); %>

            <% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel()); %>
		</form>
	</div>
</div>

<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="true" AppendToPageEnd="true">
    <script type="text/javascript">
        $(CMS.mobile360.Generic.input);
</script>
</ui:MinifiedJavascriptControl>

</asp:content>

