<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<% if (!Profile.IsAuthenticated)
   {
%>

<%: Html.LinkButton(this.GetMetadata(".LINK_TEXT")
    , new { @class="join_now join2", @href = this.Url.RouteUrl("Register", new { @action = "Index" }), @target = "_top" }
    )%>

<% } %>