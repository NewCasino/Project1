<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
	<div class="UserBox TextBox CenterBox">
		<div class="BoxContent">
			<% Html.RenderPartial("/Components/StatusNotification", 
					new StatusNotificationViewModel(StatusType.Warning, string.Format(this.GetMetadata(".Warning_Message"), Profile.UserID)) 
						{ IsHtml = true }); %>
			<%= this.GetMetadata(".Instruction").HtmlEncodeSpecialCharactors()%>
		</div>
	</div>
	<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="true" AppendToPageEnd="true">
	<script type="text/javascript">
		$(CMS.mobile360.Generic.init);
	</script>
	</ui:MinifiedJavascriptControl>
</asp:Content>

