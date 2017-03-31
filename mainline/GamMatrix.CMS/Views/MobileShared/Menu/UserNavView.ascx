<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Menu.UserNavViewModel>" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Menu" %>

<div class="MainMenuSecondary Container">
	<ol class="MenuList SecondaryMenuList SML1 L">
		<% 
			foreach (MenuItemData itemData in this.Model.MenuInfo.GetActiveColumnItems())
			{
		%>
		<li class="MenuItem <%= itemData.CssClass.SafeHtmlEncode()%> X">
			<a class="MenuLink A Container" href="<%= itemData.Route.SafeHtmlEncode() %>">
				<span class="ActionArrow Y">&#9658;</span>
				<span class="Page I"><%= this.GetMetadata(".Icon_Page").SafeHtmlEncode()%></span>
				<span class="PageName N"><%= itemData.Name.SafeHtmlEncode()%></span>
			</a>
		</li>
		<% 
			}
		%>
	</ol>
	<ol class="MenuList SecondaryMenuList SML2 L">
		<% 
			foreach (MenuItemData itemData in this.Model.MenuInfo.GetActiveColumnItems(1))
			{
		%>
		<li class="MenuItem <%= itemData.CssClass.SafeHtmlEncode()%> X">
			<a class="MenuLink A Container" href="<%= itemData.Route.SafeHtmlEncode() %>">
				<span class="ActionArrow Y">&#9658;</span>
				<span class="Page I"><%= this.GetMetadata(".Icon_Page").SafeHtmlEncode()%></span>
				<span class="PageName N"><%= itemData.Name.SafeHtmlEncode()%></span>
			</a>
		</li>
		<% 
			}
		%>
	</ol>
</div>