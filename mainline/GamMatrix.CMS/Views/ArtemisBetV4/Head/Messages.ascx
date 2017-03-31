<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%-- if( Profile.IsAuthenticated )
   { %>
<div id="messaegs-button-wrap">
  <a title="<%=this.GetMetadata(".BUTTON_TEXT").SafeHtmlEncode()%>" class="MessagesPanel" href="/Messages" style="display: block;"><%=this.GetMetadata(".BUTTON_TEXT").HtmlEncodeSpecialCharactors()%></a>
</div>

<% } %>
--%>