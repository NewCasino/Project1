<%@ Page Language="C#" PageTemplate="/StaticMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.Common.Components.ProfileInput" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>

<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
	<div class="Box CenterBox RegisterBox">
		<div class="BoxContent">
			<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel()); %>
			<form action="<%= this.Url.RouteUrl("Register", new { @action = "Step2" }).SafeHtmlEncode() %>" 
				method="post" enctype="application/x-www-form-urlencoded" id="formRegisterStep1" class="GeneralForm FormRegister FormRegister-Step1" target="_self">
                
				<fieldset>
					<legend class="hidden">
						<%= this.GetMetadata(".Legend").SafeHtmlEncode()%>
					</legend>

					<% Html.RenderPartial("/Components/ProfilePersonalInput", new ProfilePersonalInputViewModel(new ProfileInputRegisterSettings())); %>
					<% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel { BackButtonEnabled = false }); %>
				</fieldset>
			</form>
		</div>
	</div>

	<script type="text/javascript">
		$(CMS.mobile360.Generic.input);
	</script>
</asp:Content>

