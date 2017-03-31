<%@ Page Language="C#" PageTemplate="/StaticMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.Common.Components.ProfileInput" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>

<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div class="Box CenterBox">
<div class="BoxContent">
<form action="<%= this.Url.RouteUrl("QuickRegister", new { @action = "Register" }).SafeHtmlEncode()%>"
method="post" enctype="application/x-www-form-urlencoded" id="formQuickRegister" target="_self">
                
<fieldset>
<legend class="hidden">
<%= this.GetMetadata(".Legend").SafeHtmlEncode() %>
</legend>

<% Html.RenderPartial("/Components/ProfilePersonalInput", new ProfilePersonalInputViewModel(new ProfileInputQuickRegisterSettings())); %>
<% Html.RenderPartial("/Components/ProfileAccountInput", new ProfileAccountInputViewModel(new ProfileInputQuickRegisterSettings())); %>
<% Html.RenderPartial("/Components/ProfileAddressInput", new ProfileAddressInputViewModel(new ProfileInputQuickRegisterSettings())); %>

<% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel()); %>
</fieldset>
<script src="https://zz.connextra.com/dcs/tagController/tag/7d61b44fefd2/regstart?" async defer></script>
</form>
</div>
</div>

<script type="text/javascript">
$(CMS.mobile360.Generic.input);
</script>
</asp:Content>

