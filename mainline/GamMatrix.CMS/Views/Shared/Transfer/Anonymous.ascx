<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>

<div id="transfer-wrapper" class="content-wrapper">
    <%: Html.H1(this.GetMetadata(".HEAD_TEXT"))%>
    <ui:Panel runat="server" ID="pnTransfer">
        <center>
    <br />
    <%: Html.WarningMessage( this.GetMetadata(".Message").HtmlEncodeSpecialCharactors(), true ) %>
</center>
    </ui:Panel>
</div>

