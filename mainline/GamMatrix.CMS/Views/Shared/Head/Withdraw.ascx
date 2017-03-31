<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>

<% if( Profile.IsAuthenticated )
   { %>
<div id="withdraw-button-wrap">
    <%: Html.LinkButton(this.GetMetadata(".BUTTON_TEXT"), new { @class = "withdraw-button", @target = "_top", @href = this.Url.RouteUrl("Withdraw", new { @action = "Index" }) })%>
</div>
<% } %>
