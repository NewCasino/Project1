<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">
    private PayCardInfoRec GetExistingPayCard()
    {
        PayCardInfoRec payCard = GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.Trustly)
        .FirstOrDefault(p => p.IsDummy);
        if (payCard == null)
            throw new InvalidOperationException("This payment method is not configured in GmCore.");
        return payCard;
    }
</script>

<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <Tabs>

        <%---------------------------------------------------------------
            Trustly
         ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabRecentCards" IsHtmlCaption="true" Caption="<%$ Metadata:value(/Metadata/PaymentMethod/Trustly.Title) %>" Selected="true">
            <form id="formTrustlyPayCard" onsubmit="return false">

                <br />
                <center>
                    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnDepositWithTrustlyPayCard" })%>
                </center>
            </form>

        </ui:Panel>

    </Tabs>
</ui:TabbedContent>

<script type="text/javascript">
//<![CDATA[
    $(function () {
        $('#formTrustlyPayCard').initializeForm();  

        $('#btnDepositWithTrustlyPayCard').click(function (e) {
            e.preventDefault();
            if (!isDepositInputFormValid())
                return false;

            $(this).toggleLoadingSpin(true);

            var payCardID = '<%= GetExistingPayCard().ID.ToString() %>';
            // <%-- post the prepare form --%>   
            tryToSubmitDepositInputForm(payCardID, function () {
                $('#btnDepositWithTrustlyPayCard').toggleLoadingSpin(false);
            });
        });
    });
//]]>
</script>
