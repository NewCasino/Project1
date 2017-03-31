<%@ Page Language="C#" PageTemplate="/StaticMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.Common.Components.ProfileInput" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>

<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
	<div class="Box CenterBox RegisterBox">
		<div class="BoxContent">
			<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { CurrentStep = 1 }); %>
			<form action="<%= this.Url.RouteUrl("Register", new { @action = "Step3" }).SafeHtmlEncode()%>"
				method="post" enctype="application/x-www-form-urlencoded" id="formRegisterStep2" class="GeneralForm FormRegister FormRegister-Step2" target="_self">
                
				<fieldset>
					<legend class="hidden">
						<%= this.GetMetadata(".Legend").SafeHtmlEncode() %>
					</legend>
					<% Html.RenderPartial("/Components/MultiFormState", ViewData["StateVars"]); %>
					<% Html.RenderPartial("/Components/ProfileAddressInput", new ProfileAddressInputViewModel(new ProfileInputRegisterSettings())); %>
					<% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel()); %>
				</fieldset>
			</form>
		</div>
	</div>

	<script type="text/javascript">
		$(CMS.mobile360.Generic.input);
	</script>
</asp:Content>

