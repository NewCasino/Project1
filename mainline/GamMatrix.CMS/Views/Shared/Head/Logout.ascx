<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<% if (Profile.IsAuthenticated)
   {
       using (Html.BeginRouteForm("Login", new { @action = "SignOut" }, FormMethod.Post, new { @target = "_top" }))
       { %>
 
<div id="logout-button-wrap">
    <%: Html.Button(this.GetMetadata(".BUTTON_TEXT"), new { @class = "logout-button", @type = "submit" })%>
</div>

<%  
       }
   } 
%>