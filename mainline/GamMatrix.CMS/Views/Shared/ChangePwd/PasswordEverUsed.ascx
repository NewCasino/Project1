<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<center>
    <br />
    <%: Html.ErrorMessage( this.GetMetadata(".Message") ) %>
</center>

