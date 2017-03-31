<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<center>
    <br />
    <%: Html.WarningMessage( this.GetMetadata(".Message").HtmlEncodeSpecialCharactors(), true ) %>
</center>