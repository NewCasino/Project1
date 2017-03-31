<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div id="message-wrapper" class="content-wrapper">
<ui:Panel runat="server" ID="pnMessage">
    <center>
        <br />
        <%: Html.WarningMessage(this.GetMetadata(".Message").HtmlEncodeSpecialCharactors(), true)%>
    </center>
</ui:Panel>
</div>
</asp:Content>
