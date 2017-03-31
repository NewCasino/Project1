<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" 
    Inherits="CM.Web.ViewPageEx<GamMatrix.CMS.Models.MobileShared.Deposit.Prepare.PrepareMoneyMatrixTrustlyViewModel>" 
    Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" 
    MetaDescription="<%$ Metadata:value(.Description)%>"%>

<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GamMatrix.CMS.Models.Common.Components" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>

<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<div class="UserBox DepositBox CenterBox">
	<div class="BoxContent">
		<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 4, CurrentStep = 2 }); %>
		<form action="<%= this.Url.RouteUrl("Deposit", new { @action = "PrepareTransaction", @paymentMethodName = this.Model.PaymentMethod.UniqueName }).SafeHtmlEncode() %>" method="post" id="formPrepareTrustly">
            
			<% Html.RenderPartial("/Components/MultiFormState", Model.StateVars); %>
            
            <% Html.RenderPartial(
                 "/Components/MoneyMatrix_PaymentSolutionPayCard",
                 new MoneyMatrixPaymentSolutionPrepareViewModel(
                     TransactionType.Deposit,
                     "Trustly")
                 {
                     UseDummyPayCard = true
                 }); %>

		    <% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel()); %>
		</form>
	</div>
</div>

<script type="text/javascript">
    $(CMS.mobile360.Generic.input);
</script>
</asp:Content>