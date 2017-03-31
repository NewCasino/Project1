<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Casino.Components" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Promotions.Home" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="CasinoEngine" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>

<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
	<% 
    Html.RenderPartial("/Promotions/Home/PresentationList", new PresentationListViewModel("/Metadata/Promotions"));
    if (!Settings.Vendor_EnableSports)
	{ 
		Html.RenderPartial("/Components/AddApplication", new AddApplicationViewModel());
	} %>
    <%if(Settings.GRE_Enabled) { %>
   <link rel="stylesheet" href="//cdn.everymatrix.com/Generic/mobile2016/mobile-games-recomm.css" />
    <% Html.RenderPartial("/Components/PopularGamesSlider", this.ViewData.Merge(new { @ContainerClass = "BannerBelow",@Debug = true })); %>
	<%} %>
    <div class="Box">
		<div class="BoxContent">
			<% Html.RenderPartial("GameDisplay", new GameInfo(GameMgr.GetAllGamesWithoutGroup()));%>
		</div>
	</div>
	
	<script type="text/javascript">
		$(CMS.mobile360.Generic.init);
	</script>
</asp:Content>

