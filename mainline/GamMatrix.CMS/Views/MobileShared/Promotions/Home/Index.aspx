<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Promotions.Home" %>

<script runat="server">
	private string MetaPath = "/Metadata/Promotions";
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div class="Box PromotionsBox">
    <div class="BoxContent">
		<% if (Settings.Vendor_EnableCasino && Settings.Vendor_EnableSports)
				Html.RenderPartial("/Components/MenuList", new MenuListViewModel(MetaPath, this.Url.RouteUrl("Promotions_Home")));
			else
			{
				if (Settings.Vendor_EnableCasino)
					Html.RenderPartial("ContentsList", new ContentListViewModel(string.Format("{0}/Casino", MetaPath)));
				if (Settings.Vendor_EnableSports)
					Html.RenderPartial("ContentsList", new ContentListViewModel(string.Format("{0}/Sports", MetaPath)));
			}%>
    </div>
</div>

<script type="text/javascript">
    $(CMS.mobile360.Generic.init);
</script>

</asp:Content>

