<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>

<center>
    <br />
    <%: Html.WarningMessage( this.GetMetadata(".Message") ) %>
</center>