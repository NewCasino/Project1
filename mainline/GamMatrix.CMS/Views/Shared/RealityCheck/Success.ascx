<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>

<center>
    <br />
    <%: Html.SuccessMessage( this.GetMetadata(".Message") ) %>
</center>