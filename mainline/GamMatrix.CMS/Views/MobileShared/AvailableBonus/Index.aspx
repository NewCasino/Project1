<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrix.CMS.Models.MobileShared.AvailableBonus.AvailableBonusViewModel>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
	<div class="Box BonusContainnerBox CasinoBonusContainnerBox">
		<h2 class="SubHeader"><a class="SHToggle ToggleButton" href="#"> <span class="ToggleArrow">&ndash;</span> <span class="SHText"><%= this.GetMetadata(".Casino_Bonus")%></span> </a></h2>
		<div class="BoxContent ToggleContent Container CasinoBonusContent">
			<% Html.RenderPartial("CasinoView", Model.Casino);%>
		</div>
	</div>

	<% if (Settings.IsOMSeamlessWalletEnabled)
	{ %>
	<div class="Box BonusContainnerBox SportsBonusContainnerBox">
		<h2 class="SubHeader"><a class="SHToggle ToggleButton" href="#"> <span class="ToggleArrow">&ndash;</span> <span class="SHText"><%= this.GetMetadata(".Sports_Bonus")%></span> </a></h2>
		<div class="BoxContent ToggleContent Container SportsBonusContent">
			<% Html.RenderPartial("SportsView", Model.Sports);%>
		</div>
	</div>
	<% } %>

    <% if (Settings.IsBetConstructWalletEnabled)
	{ %>
	<div class="Box BonusContainnerBox SportsBonusContainnerBox">
		<h2 class="SubHeader"><a class="SHToggle ToggleButton" href="#"> <span class="ToggleArrow">&ndash;</span> <span class="SHText"><%= this.GetMetadata(".Sports_Bonus")%></span> </a></h2>
		<div class="BoxContent ToggleContent Container SportsBonusContent">
			<% Html.RenderPartial("BetConstructView", Model.BetConstruct);%>
		</div>
	</div>
	<% } %>

	<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="true" AppendToPageEnd="true">
	<script>
		$(CMS.mobile360.Generic.input);
		CMS.mobile360.views.ToggleContent.createFor('.BonusContainnerBox');
	</script>
	</ui:MinifiedJavascriptControl>
</asp:Content>

