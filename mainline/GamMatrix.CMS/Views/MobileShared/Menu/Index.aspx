<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrix.CMS.Models.MobileShared.Menu.MenuBuilder>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>

<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
	<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Menu" %>

	<div class="Header" id="headerFixed">
		<div class="HeaderWrapper Container">
			<span class="hidden"><%= this.GetMetadata(".Welcome").SafeHtmlEncode()%></span>
			<a class="OperatorLogo" id="operatorLogo" href="<%= Url.RouteUrl("Home").SafeHtmlEncode()%>"><%= this.GetMetadata(".Icon_Logo").SafeHtmlEncode()%></a>
		</div>
	</div>

	<div class="MainMenu FallbackMenu" id="fallbackMenu">
		<%= Html.Partial("GeneralNav", Model)%>
		<% if (Profile.IsAuthenticated)
				Html.RenderPartial("UserNav", Model); %>
	</div>
	<script type="text/javascript">
		$(CMS.mobile360.Generic.init);
	</script>
</asp:Content>