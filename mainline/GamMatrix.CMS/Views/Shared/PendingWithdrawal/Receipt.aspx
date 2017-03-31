<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrixAPI.GetTransInfoRequest>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>

<script language="C#" type="text/C#" runat="server">
    private string GetMessage()
    {
        string accountName = this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name", this.Model.TransData.DebitPayItemVendorID.ToString()));
        string format = this.GetMetadata(".Message");

        return string.Format(format
            , this.Model.TransData.DebitRealAmount
            , this.Model.TransData.DebitRealCurrency
            , accountName
            );
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<div id="pending-withdrawal-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT"))%>
<ui:Panel runat="server" ID="pnPendingWithdrawal">

    <center>
        <br />
        <%: Html.SuccessMessage(GetMessage()) %>
    </center>
</ui:Panel>

</div>

<script language="javascript" type="text/javascript">
    $(window).load(function () {
        $(document).trigger("BALANCE_UPDATED");
    });
</script>


</asp:Content>

