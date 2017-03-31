<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Casino.Components" %>
<%@ Import Namespace="CasinoEngine" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
	<% if (Settings.Vendor_EnableCasino)
	{ %>
	<div class="Box PopularBox CasinoGames">
		<h2 class="SubHeader"><a class="SHToggle ToggleButton" href="#"> <span class="ToggleArrow">&ndash;</span> <span class="SHText"><%= this.GetMetadata(".PopularGames")%></span> </a></h2>
		<div class="BoxContent ToggleContent Container">
			<% Html.RenderPartial("/Casino/Components/PopularGames", new GameInfo(GameMgr.GetAllGamesWithoutGroup()));%>
		</div>
	</div>
	<% } %>

	<%--
	<% if (Settings.Vendor_EnableSports)
	{ %>
	<div class="Box PopularBox SportsMatches">
		<h2 class="SubHeader"><a class="SHToggle ToggleButton" href="#"> <span class="ToggleArrow">&ndash;</span> <span class="SHText"><%= this.GetMetadata(".PopularMatches")%></span> </a></h2>
		<div class="BoxContent ToggleContent Container">
			<% Html.RenderPartial("/Sports/Components/PopularMatches");%>
		</div>
	</div>
	<% } %>
	--%>

	<script type="text/javascript">
		$(function () {
			CMS.mobile360.Generic.input();
			CMS.mobile360.views.ToggleContent.createFor('.PopularBox');
		});
	</script>
</asp:Content>

