<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<Finance.PaymentMethod>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GamMatrixAPI" %>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<div class="Box UserBox CenterBox WithdrawBox">
	<div class="BoxContent WithdrawContent">
	    <% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 4, CurrentStep = 1 }); %>
        <form action="<%= this.Url.RouteUrl("Withdraw", new { @action = "MobilePrepareTransaction", @paymentMethodName = this.Model.UniqueName }).SafeHtmlEncode() %>" method="post" id="formPrepareWithdraw" class="GeneralForm DepositForm PrepareWithdrawForm">
			<% Html.RenderPartial("/Components/MultiFormState", ViewData["StateVars"]); %>
            <% Html.RenderPartial(this.ViewData["PayCardView"] as string, this.Model);  %>
            <% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel()); %>
		</form>
    </div>
</div>

<script type="text/javascript">
    $(CMS.mobile360.Generic.input);
</script>
</asp:Content>