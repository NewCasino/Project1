<%@ Page Language="C#" PageTemplate="/Affiliates/AffiliateMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>"
    Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>"
    MetaDescription="<%$ Metadata:value(.Description)%>" %>

<asp:content contentplaceholderid="cphHead" runat="Server"> </asp:content>
<asp:content contentplaceholderid="cphMain" runat="Server">
  <div>
    <div class="aff_top_banner"><%=this.GetMetadata(".BannerImage")%>
    </div>
    <div class="aff_content">
      <%=this.GetMetadata(".Html").HtmlEncodeSpecialCharactors() %>
    </div>
  </div>
  <script type="text/javascript">
      $(function () { menu_setMenuCurrent($("#menu li.whyjetbull")); }); 
</script> 
</asp:content>
