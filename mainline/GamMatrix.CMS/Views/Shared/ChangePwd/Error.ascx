<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<center>
    <br />
    <%: Html.ErrorMessage( this.ViewData["ErrorMessage"] as string ) %>
</center>