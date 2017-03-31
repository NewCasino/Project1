<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<% Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Error, this.GetMetadata(".Failed_Message"))); %>
<% Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Info, this.GetMetadata(".SignUp_Here"))); %>
<div class="AccountButtonContainer">
	<a class="Button AccountButton" href="<%= Url.RouteUrl("Register") %>">
		<strong class="ButtonText"><%= this.GetMetadata(".SignUp_Button").SafeHtmlEncode()%></strong>
	</a>
</div>