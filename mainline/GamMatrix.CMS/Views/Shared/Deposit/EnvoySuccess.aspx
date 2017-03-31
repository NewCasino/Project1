<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<Finance.PaymentMethod>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div id="deposit-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT"))%>
<ui:Panel runat="server" ID="pnDeposit">

<% Html.RenderPartial("PaymentMethodDesc", this.Model); %>
    <center>
        <br />
        <%: Html.InformationMessage( this.GetMetadata(".Message") ) %>
    </center>
</ui:Panel>

</div>


<script type="text/javascript">
    $(function () {
        $(document).trigger("DEPOSIT_COMPLETED");
    });
</script>

</asp:Content>

