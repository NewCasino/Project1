<%@ Page Language="C#" PageTemplate="/InfoMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<% Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Error, 
	(this.ViewData["ErrorMessage"] as string).DefaultIfNullOrEmpty(
		this.Request["ErrorMessage"].DefaultIfNullOrEmpty(
			this.GetMetadata(".Message")))) 
	{ IsHtml = true }); %>
    <script type="text/javascript">
        try {
            if (self.parent !== null && self.parent != self) {
                var errorMessage = '<%=(this.ViewData["ErrorMessage"] as string).DefaultIfNullOrEmpty(this.Request["ErrorMessage"].DefaultIfNullOrEmpty(this.GetMetadata(".Message"))) %>';
                var targetOrigin = '<%=this.GetMetadata("/Deposit/_Error_aspx.TargetOriginForPostMessage").SafeJavascriptStringEncode().DefaultIfNullOrWhiteSpace("") %>';
                if (targetOrigin.trim() == '') {
                    targetOrigin = top.window.location.href;
                }
                window.top.postMessage('{"user_id":<%=CM.State.CustomProfile.Current.UserID %>, "message_type": "deposit_result", "success": false, "message": "' + errorMessage + '"}', targetOrigin);
            }
        } catch (e) { console.log(e); }
    </script>
</asp:Content>

