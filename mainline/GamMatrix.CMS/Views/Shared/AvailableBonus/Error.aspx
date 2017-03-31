<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<div id="available-bonus-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT"))%>
<ui:Panel runat="server" ID="pnAvailableBonus">

    <center>
        <%: Html.ErrorMessage(
            (this.ViewData["ErrorMessage"] as string).DefaultIfNullOrEmpty(
                    this.Request["ErrorMessage"].DefaultIfNullOrEmpty( this.GetMetadata(".Message") ) 
                           )
            ) %>
    </center>
</ui:Panel>
</div>
</asp:Content>

