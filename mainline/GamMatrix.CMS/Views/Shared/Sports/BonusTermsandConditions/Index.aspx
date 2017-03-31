<%@ Page Language="C#" PageTemplate="/Sports/SportsMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
    <%: Html.H1(this.GetMetadata(".PageTite")) %>
    <ui:Panel runat="server" ID="pnGeneralLiteral">
    <%= this.GetMetadata("/Metadata/Documents/OddsMatrixTermsAndConditions.DefaultHtml").HtmlEncodeSpecialCharactors()%>
    </ui:Panel>    
</asp:Content>

