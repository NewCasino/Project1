<%@ Page Language="C#" PageTemplate="/App_Download/App_Download_Master.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<h1 class="h1"><div class="h1_Right"><div class="h1_Left"><div class="h1_Middle"><span id="GeneralPageTitle"><%= this.GetMetadata(".ContentTitle").HtmlEncodeSpecialCharactors() %></span></div></div></div></h1>
<ui:Panel runat="server" ID="pnGeneralLiteral">
<div class="app_download_content">
<%= this.GetMetadata(".Html").HtmlEncodeSpecialCharactors() %>
<div style="padding-left:25px;">
<%= this.GetMetadata(".QR_Code_Html").HtmlEncodeSpecialCharactors() %>
</div>
</div>

</ui:Panel>
</asp:Content>

