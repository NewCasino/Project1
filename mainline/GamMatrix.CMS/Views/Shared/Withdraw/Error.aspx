<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>


<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>


<asp:content contentplaceholderid="cphMain" runat="Server">
<div id="withdraw-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT"))%>
<ui:Panel runat="server" ID="pnWithdraw">
    <div id="error_step">
    <center>
        <br />
        <%: Html.ErrorMessage(
            (this.ViewData["ErrorMessage"] as string).DefaultIfNullOrEmpty(
                    this.Request["ErrorMessage"].DefaultIfNullOrEmpty( this.GetMetadata(".Message") ) 
                           )
            ) %>
    </center>
    </div>
</ui:Panel>

</div>
<script>
    try {
        if (top.location.href != self.location.href) {
            if ($(".ConfirmationBox.simplemodal-container", parent.document.body).length > 0) {
                $(".ConfirmationBox.simplemodal-container", parent.document.body).hide();
                top.location.href = self.location.href;
            }
        }
    } catch (err) { console.log(err); }

</script>
</asp:content>

