<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>

<% if( Profile.IsAuthenticated )
   { %>
<div id="deposit-button-wrap">
    <%: Html.LinkButton(this.GetMetadata(".BUTTON_TEXT"), new { @class = "deposit-button", @target = "_top", @href = this.Url.RouteUrl("Deposit", new { @action = "Index" }) })%>
</div>
<% } %>