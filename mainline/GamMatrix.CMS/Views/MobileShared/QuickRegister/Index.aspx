<%@ Page Language="C#" PageTemplate="/StaticMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>

<%@ Import Namespace="GamMatrix.CMS.Models.Common.Components.ProfileInput" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>

<asp:content contentplaceholderid="cphMain" runat="Server">
	<div class="Box CenterBox">
		<div class="BoxContent">
			<form action="<%= this.Url.RouteUrl("QuickRegister", new { @action = "Register" }).SafeHtmlEncode()%>"
				method="post" enctype="application/x-www-form-urlencoded" id="formQuickRegister" target="_self">
                <%------------------------------------------
    IovationBlackbox
 -------------------------------------------%>
  <%if (Settings.IovationDeviceTrack_Enabled)
      { %>
        <% Html.RenderPartial("/Components/IovationTrack", this.ViewData);  %>
 <%} %>
      
				<fieldset>
					<legend class="hidden">
						<%= this.GetMetadata(".Legend").SafeHtmlEncode() %>
					</legend>
					
					<% Html.RenderPartial("/Components/ProfilePersonalInput", new ProfilePersonalInputViewModel(new ProfileInputQuickRegisterSettings())); %>
					<% Html.RenderPartial("/Components/ProfileAccountInput", new ProfileAccountInputViewModel(new ProfileInputQuickRegisterSettings())); %>
					<% Html.RenderPartial("/Components/ProfileAddressInput", new ProfileAddressInputViewModel(new ProfileInputQuickRegisterSettings())); %>
                    <%if (Settings.QuickRegistration.IsCaptchaRequired)
                        { %>
                        <% Html.RenderPartial("/Components/RegisterCaptcha", this.ViewData);  %>
                    <%} %>
					<% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel()); %>
				</fieldset>
			</form>
		</div>
	</div>

	<script type="text/javascript">
        $(CMS.mobile360.Generic.input);
	</script>
</asp:content>

