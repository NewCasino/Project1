<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Components.ForfeitBonusWarningViewModel>" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<% 
    if (Model.IsEnabled)
    {
		Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Warning, this.GetMetadata(".Message")));
    }
%>