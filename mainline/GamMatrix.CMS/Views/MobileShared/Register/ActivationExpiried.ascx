<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<% Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Error, this.GetMetadata(".Expiried_Message"))); %>