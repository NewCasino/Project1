<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
	<div class="Box UserBox CenterBox">
		<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { CurrentStep = 3 }); %>

		<div class="BoxContent TextBox FinalStep">
			<%= this.GetMetadata(".Html") %>
			<div class="AccountButtonContainer">
				<a href="<%= Url.RouteUrl("Deposit", new{ @action = "Index" }) %>" class="Button AccountButton"> <strong class="ButtonText"><%= this.GetMetadata(".Deposit").SafeHtmlEncode()%></strong> </a>
			</div>
		</div>
	</div>

	<script type="text/javascript">
		$('#loginLink').remove();

		$(CMS.mobile360.Generic.init);
	</script>
</asp:Content>

