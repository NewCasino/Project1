<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>


<center>
    <br />
    <%: Html.ErrorMessage( this.ViewData["ErrorMessage"] as string ) %>
</center>