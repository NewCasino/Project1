<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="CasinoEngine" %>

<script type="text/C#" runat="server">
	private object listStyle
	{
		get
		{
			return new {
				@ListStyle = "MenuList ToggleContent",
				@ItemStyle = "PseudoA"
			};
		}
	}
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
	<% if (Settings.Vendor_EnableCasino)
	{ %>
	<div class="Box WinnerBox">
		<div class="BoxContent">
			<h2 class="SubHeader"><a class="SHToggle ToggleButton" href="#"> <span class="ToggleArrow">&ndash;</span> <span class="SHText"><%= this.GetMetadata(".CasinoWinners").SafeHtmlEncode()%></span> </a></h2>
			<% Html.RenderPartial("CasinoWinners", ViewData.Merge(listStyle)); %>
		</div>
	</div>
	<% } %>

	<%-- 
	<% if (Settings.Vendor_EnableSports)
	{ %>
	<div class="Box WinnerBox">
		<div class="BoxContent">
			<h2 class="SubHeader"><a class="SHToggle ToggleButton" href="#"> <span class="ToggleArrow">&ndash;</span> <span class="SHText"><%= this.GetMetadata(".SportsWinners").SafeHtmlEncode()%></span> </a></h2>
			<% Html.RenderPartial("SportsWinners", ViewData.Merge(listStyle)); %>
		</div>
	</div>
	<% } %>
	--%>

	<script type="text/javascript">
		$(function () {
			CMS.mobile360.Generic.input();
			CMS.mobile360.views.ToggleContent.createFor('.WinnerBox');
		});
	</script>
</asp:Content>

