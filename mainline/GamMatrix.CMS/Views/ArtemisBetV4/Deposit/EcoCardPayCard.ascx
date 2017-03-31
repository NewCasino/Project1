<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>

<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script language="C#" type="text/C#" runat="server">
    private PayCardInfoRec PayCard { get; set; }
    private PayCardInfoRec GetExistingPayCard()
    {
        if (this.PayCard == null)
        {
            this.PayCard = GamMatrixClient.GetPayCards(VendorID.EcoCard)
            .OrderByDescending(e => e.LastSuccessDepositDate)
            .FirstOrDefault();
        }
        if (this.PayCard == null)
            throw new InvalidOperationException("This payment method is not configured in GmCore.");
        return this.PayCard;
    }
</script>

<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <Tabs>

        <%---------------------------------------------------------------
            EcoCard
         ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabRecentCards" IsHtmlCaption="true" Caption="<%$ Metadata:value(/Metadata/PaymentMethod/EcoCard.Title) %>" Selected="true">
            <form id="formEcoCardPayCard" onsubmit="return false" class="DepositForm formEcoCardPayCard">
                <%------------------------
                   ECO CARD
                -------------------------%>    
                <%: Html.Hidden("ecoCardPayCardID", GetExistingPayCard().ID.ToString())%>
                <div class="Box Container DepositBTNs DepositBTNBox">
                    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnDepositWithEcocardPayCard" })%>
                </div>
            </form>

        </ui:Panel>



    </Tabs>
</ui:TabbedContent>


<script type="text/javascript">
//<![CDATA[
    $(document).ready(function () {
        $('#formEcoCardPayCard').initializeForm();

        $('#btnDepositWithEcocardPayCard').click(function (e) {
            e.preventDefault();
            if (!isDepositInputFormValid())
                return false;

            $(this).toggleLoadingSpin(true);

            var payCardID = $('#formEcoCardPayCard input[name="ecoCardPayCardID"]').val();

            // <%-- post the prepare form --%>   
            tryToSubmitDepositInputForm(payCardID, function () {
                $('#btnDepositWithEcocardPayCard').toggleLoadingSpin(false);
            });
        });
    });
//]]>
</script>