<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%-- if( Profile.IsAuthenticated ) { %>
<li class="account-link Userprofile">
    <a class=" UserWelcome" > Hi, <span class="NameUser"><%= string.Format( this.GetMetadata(".TEXT"), Profile.DisplayName).SafeHtmlEncode() %></span> </a>
</li>
<% } --%>