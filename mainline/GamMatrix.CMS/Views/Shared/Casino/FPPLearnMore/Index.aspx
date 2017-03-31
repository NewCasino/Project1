<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">


<div id="casino-fpp-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".Title")) %>
<ui:Panel runat="server" ID="pnLearnMoreCasinoFPP">
<%=this.GetMetadata(".HTML").HtmlEncodeSpecialCharactors() %>
</ui:Panel>
</div>
</asp:Content>

