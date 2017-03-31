<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">
    private PayCardInfoRec GetExistingPayCard()
    {
        PayCardInfoRec payCard = GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.GeorgianCard)
        .OrderByDescending(e => e.LastSuccessDepositDate)
        .FirstOrDefault(p => p.IsDummy);
        if (payCard == null)
            throw new InvalidOperationException("This payment method is not configured in GmCore.");
        return payCard;
    }
</script>

<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <Tabs>

        <%---------------------------------------------------------------
            Georgian Card
         ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabRecentCards" IsHtmlCaption="true" Caption="<%$ Metadata:value(/Metadata/PaymentMethod/GeorgianCard.Title) %>" Selected="true">
            <form id="formGeorgianCardPayCard" onsubmit="return false">

                <br />
                <center>
                    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnDepositWithGeorgianCardPayCard", @class="ContinueButton button" })%>
                </center>
            </form>

        </ui:Panel>

    </Tabs>
</ui:TabbedContent>

<script type="text/javascript">
//<![CDATA[
    $(document).ready(function () {
        $('#formGeorgianCardPayCard').initializeForm();

        $('#btnDepositWithGeorgianCardPayCard').click(function (e) {
            e.preventDefault();
            if (!isDepositInputFormValid())
                return false;

            $(this).toggleLoadingSpin(true);

            var payCardID = '<%= GetExistingPayCard().ID.ToString() %>';
            // <%-- post the prepare form --%>   
            tryToSubmitDepositInputForm(payCardID, function () {
                $('#btnDepositWithGeorgianCardPayCard').toggleLoadingSpin(false);
            });
        });
    });
//]]>
</script>