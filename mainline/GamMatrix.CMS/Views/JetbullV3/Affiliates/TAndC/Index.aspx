<%@ Page Language="C#" PageTemplate="/Affiliates/AffiliateMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>

" MetaKeywords="
<%$ Metadata:value(.Keywords)%>
" MetaDescription="
<%$ Metadata:value(.Description)%>
"%>
<asp:Content ContentPlaceHolderID="cphHead" Runat="Server"> </asp:Content>
<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
  <div>
    <div class="aff_top_banner"><%=this.GetMetadata(".BannerImage")%>
    </div>
    <div class="aff_content" style="text-align:left;">
      <%=this.GetMetadata(".Html").HtmlEncodeSpecialCharactors() %>
    </div>
  </div>
</asp:Content>
