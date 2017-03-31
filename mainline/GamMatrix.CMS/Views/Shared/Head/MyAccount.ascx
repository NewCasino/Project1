<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>



<% if( Profile.IsAuthenticated )

   { %>

<div id="myaccount-button-wrap">

    <%: Html.LinkButton(this.GetMetadata(".BUTTON_TEXT"), new { @class = "myaccount-button", @href = this.Url.RouteUrl("Profile", new { @action = "Index" }), @target = "_top" })%>

</div>

<% } %>