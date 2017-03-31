<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<% Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Success, this.GetMetadata("/ChangePassword/_Success_ascx.Message")) { IsHtml = true }); %>
<script language="javascript" type="text/javascript">
    function GotoHomePage() {
        top.location = "/";
    }
    setTimeout(GotoHomePage(), 3000);
</script>