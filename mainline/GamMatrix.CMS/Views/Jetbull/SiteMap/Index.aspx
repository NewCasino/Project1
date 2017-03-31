<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">  

</asp:Content>
<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
  <div class="sitemap">
    <div class="mainPanel">
      <%: Html.H1(this.GetMetadata(".SiteMap_Text")) %>
      <ui:Panel runat="server" ID="pnGeneralLiteral"> <%= this.GetMetadata(".SiteMap_Html")%> </ui:Panel>
    </div>
    <div class="rightPanel">
      <% if (!Profile.IsAuthenticated){%>
      <a href="/register" class="sitemap_regbutton"><%=this.GetMetadata(".SiteMap_Register_Text").DefaultIfNullOrEmpty("Untitled").SafeHtmlEncode()%></a>
      <%}%>
    </div>
  </div>
</asp:Content>
