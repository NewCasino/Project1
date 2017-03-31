<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<center>
    <br />
    <%: Html.ErrorMessage( this.ViewData["ErrorMessage"] as string ) %>
    <br />
    <%: Html.Button( this.GetMetadata(".Button_Back"), new { @onclick = "self.location=self.location;"}) %>
</center>