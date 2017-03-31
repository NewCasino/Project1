<%@ Page Language="C#" PageTemplate="/StaticMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>

<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<div class="Box NoHeadBox LoginBox" id="loginBox">
	<div class="BoxContent">
	    <% Html.RenderPartial("/Components/LoginForm", new LoginFormViewModel { RedirectUrl = (string)this.ViewData["RedirectUrl"] }); %>
    </div>
</div>

<script type="text/javascript">
	$(function () {
		CMS.mobile360.Generic.input();
		setTimeout(function () { loginForm.focus() }, 100);
	});
</script>
</asp:Content>

