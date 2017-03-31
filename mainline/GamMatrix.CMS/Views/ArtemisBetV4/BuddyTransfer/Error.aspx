<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div id="buddytransfer-wrapper" class="content-wrapper">
<h1 id="ProfileTitle" class="ProfileTitle"> <%: this.GetMetadata(".HEAD_TEXT") %> </h1>
<ui:Panel runat="server" ID="pnBuddyTransfer">
<div class="InnerBuddyTransfer">
    <%: Html.ErrorMessage(
        (this.ViewData["ErrorMessage"] as string).DefaultIfNullOrEmpty(
                this.Request["ErrorMessage"].DefaultIfNullOrEmpty( this.GetMetadata(".Message") ) 
                        )
        ) %>
</div>


</ui:Panel>
</div>
</asp:Content>

