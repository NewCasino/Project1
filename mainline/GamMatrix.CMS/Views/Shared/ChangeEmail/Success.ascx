<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<center>
    <br />
    <%: Html.SuccessMessage( this.GetMetadata(".Message") ) %>
</center>

