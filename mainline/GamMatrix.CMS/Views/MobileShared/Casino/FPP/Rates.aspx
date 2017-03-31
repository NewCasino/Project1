<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
	<div class="Box">
		<div class="BoxContent">
			<% Html.RenderPartial("/Casino/Components/GameContributionRates", this.ViewData.Merge(new { @ContribTo = "FPP" })); %>
		</div>
	</div>
</asp:Content>

