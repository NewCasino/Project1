<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrix.CMS.Models.MobileShared.Deposit.Prepare.PrepareTrustlyViewModel>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="CM.Web.UI" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<div class="UserBox DepositBox CenterBox">
	<div class="BoxContent">
		<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 4, CurrentStep = 2 }); %>
		<form action="<%= this.Url.RouteUrl("Deposit", new { @action = "PrepareTransaction", @paymentMethodName = this.Model.PaymentMethod.UniqueName }).SafeHtmlEncode() %>" method="post" id="formPrepareTrustly">
            
			<% Html.RenderPartial("/Components/MultiFormState", Model.StateVars); %>

            <input type="hidden" name="payCardID" value="<%= Model.PayCard.ID.ToString() %>" />

		    <% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel()); %>
		</form>
	</div>
</div>

<script type="text/javascript">
    $(CMS.mobile360.Generic.input);
</script>
</asp:Content>

