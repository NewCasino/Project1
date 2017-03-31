<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>
<asp:content contentplaceholderid="cphMain" runat="Server">
    <div id="buddytransfer-wrapper" class="content-wrapper"> 
        <div class="ErrorInternal"> 
            <center><%: Html.ErrorMessage( this.GetMetadata(".Message").HtmlEncodeSpecialCharactors(), true ) %></center>
        </div>
    </div>
 </asp:content>

