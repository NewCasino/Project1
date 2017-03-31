<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>
<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
	<%: Html.H1(this.GetMetadata(".PageTitle")) %>
    <ui:Panel runat="server" ID="pnGeneralLiteral">
    <%=this.GetMetadata(".Html").HtmlEncodeSpecialCharactors() %>
    </ui:Panel> 
</asp:Content>

