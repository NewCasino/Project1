<%@ Page Language="C#" PageTemplate="/InfoMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>

<script type="text/C#" runat="server">
	private string GetErrorMessage()
	{
		string message = this.GetMetadata(".Blocked_Message");
		
		return message.Replace("[IP]", Request.GetRealUserAddress()).Replace("[COUNT]", Settings.Registration.SameIPLimitPerDay.ToString());
	}
</script>

<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
	<% Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Error, GetErrorMessage())); %>
</asp:Content>

