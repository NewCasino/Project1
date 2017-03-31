<%@ Page Language="C#" PageTemplate="/InfoMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<% Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Error, 
	   (this.ViewData["ErrorMessage"] as string).DefaultIfNullOrEmpty(
            this.Request["ErrorMessage"].DefaultIfNullOrEmpty(
				this.GetMetadata(".Message")))) { IsHtml = true }); %>
</asp:Content>

