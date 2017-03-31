<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<% if (!Profile.IsAuthenticated)
   {
%>
<%: Html.LinkButton(this.GetMetadata(".LINK_TEXT"), new { @class = "forgot_password", @href = this.Url.RouteUrl("ForgotPassword", new { @action = "Index" }), @target = "_top" })%>
<% } %>