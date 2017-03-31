<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
	<div class="Box TextBox NoHeadBox">
		<div class="BoxContent">
			<% Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Warning, this.GetMetadata(".Message")) { IsHtml = true }); %>
		</div>
	</div>
</asp:Content>

