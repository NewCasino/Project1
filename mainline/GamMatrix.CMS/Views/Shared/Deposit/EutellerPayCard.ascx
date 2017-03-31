<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">
    private PayCardInfoRec PayCard { get; set; }
    private PayCardInfoRec GetExistingPayCard()
    {
        if (this.PayCard == null)
        {
            this.PayCard = GamMatrixClient.GetPayCards(VendorID.Euteller)
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
            Euteller
         ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabRecentCards" IsHtmlCaption="true" Caption="<%$ Metadata:value(/Metadata/PaymentMethod/Euteller.Title) %>" Selected="true">
            <form id="formEutellerPayCard" onsubmit="return false">

                <%------------------------
                   
                -------------------------%>    
                <%: Html.Hidden("eutellerPayCardID", GetExistingPayCard().ID.ToString())%>

               
                <center>
                    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnDepositWithEutellerPayCard", @class="ContinueButton button" })%>
                </center>
            </form>

        </ui:Panel>

    </Tabs>
</ui:TabbedContent>


<script language="javascript" type="text/javascript">
//<![CDATA[
    $(function () {
        $('#fldCurrencyAmount #ddlCurrency > option[value!="EUR"]').remove();
        $('#fldCurrencyAmount #ddlCurrency').val('EUR').trigger('change');

        $('#formEutellerPayCard').initializeForm();

        $('#btnDepositWithEutellerPayCard').click(function (e) {
            e.preventDefault();
            if (!isDepositInputFormValid())
                return false;

            $(this).toggleLoadingSpin(true);

            var payCardID = $('#formEutellerPayCard input[name="eutellerPayCardID"]').val();
            // <%-- post the prepare form --%>   
            tryToSubmitDepositInputForm(payCardID, function () {
                $('#btnDepositWithEutellerPayCard').toggleLoadingSpin(false);
            });
        });
    });
//]]>
</script>
