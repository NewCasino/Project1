<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Components.StatusNotificationViewModel>" %>

<div class="<%= Model.GetStatusProperty("Status")%> StatusContainer" <%= Model.GetComponentIdProperty("id=\"", "\"") %>>
	<div class="StatusBackground">
		<div class="StatusIcon">Status</div>
		<% 
			if (Model.IsHtml)
			{
		%>
		<div class="StatusMessage"><%= Model.Message.HtmlEncodeSpecialCharactors()%></div>
		<%
			}
			else
			{
		%>
		<div class="StatusMessage"><%= Model.Message.SafeHtmlEncode()%></div>
		<%
			}
		%>
	</div>
</div>