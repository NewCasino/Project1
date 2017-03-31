<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div class="Box">
<div class="BoxContent">
<% Html.RenderPartial("/Components/MenuList", new MenuListViewModel(this.GetMetadata(".HTML"))); %>
</div>
<ol class="MenuList L">
<li class="MenuItem X Help_PlayPoints">
<a class="MenuLink A Container" href="<%= Url.RouteUrl("CasinoInfo").SafeHtmlEncode()%>"> <span class="ActionArrow Y">&#9658;</span> <span class="Page I"></span> <span class="PageName N"><%= this.GetMetadata(".PlayPoints").SafeHtmlEncode()%></span> </a>
</li>
</ol>
</div>
</asp:Content>

