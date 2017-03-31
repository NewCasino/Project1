<%@ Page Language="C#" PageTemplate="/StaticMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>

<%@ Import Namespace="GamMatrix.CMS.Models.Common.Components.ProfileInput" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>

<asp:content contentplaceholderid="cphMain" runat="Server">
<div class="Box CenterBox RegisterBox">
<div class="BoxContent">
<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { CurrentStep = 2 }); %>
<form action="<%= this.Url.RouteUrl("Register", new { @action = "Register" }).SafeHtmlEncode()%>"
method="post" enctype="application/x-www-form-urlencoded" id="formRegisterStep3" class="GeneralForm FormRegister FormRegister-Step3" target="_self">
             
<fieldset>
<legend class="hidden">
<%= this.GetMetadata(".Legend").SafeHtmlEncode() %>
</legend>

<% Html.RenderPartial("/Components/MultiFormState", ViewData["StateVars"]); %>
<% Html.RenderPartial("/Components/ProfileAccountInput", new ProfileAccountInputViewModel(new ProfileInputRegisterSettings())); %>
<%if (Settings.Registration.IsCaptchaRequired)
{ %>
    <% Html.RenderPartial("/Components/RegisterCaptcha", this.ViewData);  %>
<%} %>
<% Html.RenderPartial("/Components/ProfileAdditionalInput", new ProfileAdditionalInputViewModel(new ProfileInputRegisterSettings())); %>
<% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel()); %>
</fieldset>
</form>
</div>
</div>

<script type="text/javascript">
    $(CMS.mobile360.Generic.input);
</script>
</asp:content>

