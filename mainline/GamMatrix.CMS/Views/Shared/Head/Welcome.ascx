<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>

<% if( Profile.IsAuthenticated )
   { %>
<div id="welcome"><%= string.Format( this.GetMetadata(".TEXT"), Profile.DisplayName).HtmlEncodeSpecialCharactors() %></div>

<% } %>