<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrix.CMS.Models.MobileShared.Deposit.Prepare.PrepareMoneyMatrixTLNakitViewModel>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>

<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GamMatrix.CMS.Models.Common.Components" %>

<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>

<asp:content contentplaceholderid="cphMain" runat="Server">
<div class="UserBox DepositBox CenterBox">
	<div class="BoxContent">
		<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 4, CurrentStep = 2 }); %>
		<form action="<%= this.Url.RouteUrl("Deposit", new { action = "PrepareTransaction", paymentMethodName = this.Model.PaymentMethod.UniqueName }).SafeHtmlEncode() %>" method="post" id="formPrepareTLNakit">
            
			<% Html.RenderPartial("/Components/MultiFormState", Model.StateVars); %>

            <% Html.RenderPartial(
                  "/Components/MoneyMatrix_PaymentSolutionPayCard",
                  new MoneyMatrixPaymentSolutionPrepareViewModel(
                      TransactionType.Deposit,
                      "TlNakit",
                      inputFields: new List<MmInputField>
                      {
                        new MmInputField("TlNakitCardNumber", this.GetMetadata(".TlNakitCardNumber_Label")) { IsRequired = true }
                      })
                  {
                      UseDummyPayCard = true,
                      SupportedCurrency = "TRY"
                  }); %>

            <% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel()); %>
		</form>
	</div>
</div>

<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="true" AppendToPageEnd="true">
<script type="text/javascript">
    function TlNakitCardNumberValidator() {
        return !this.match(/^[a-zA-Z0-9]{19}$/) 
            ? '<%= this.GetMetadata(".TlNakitCardNumber_ValidationMessage").SafeJavascriptStringEncode() %>'
            : true;
    }
    $(CMS.mobile360.Generic.input);
</script>
</ui:MinifiedJavascriptControl>

</asp:content>