<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<% if( Profile.IsAuthenticated )
   { %><div id="message-button-wrap">
    <%: Html.LinkButton(this.GetMetadata(".BUTTON_TEXT"), new { @class = "message-button", @href = "/Messages", @target = "_top" })%>
</div><% } %>

