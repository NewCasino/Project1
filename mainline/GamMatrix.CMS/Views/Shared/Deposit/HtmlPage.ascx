<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">
    private PayCardInfoRec GetExistingPayCard()
    {
        PayCardInfoRec payCard = GamMatrixClient.GetPayCards(VendorID.MoneyMatrix).FirstOrDefault(p => p.IsDummy);
        if (payCard == null)
        {
            throw new InvalidOperationException("This payment method is not configured in GmCore.");
        }

        return payCard;
    }
</script>
<style type="text/css">
    .inputfield .controls .lst-amounts.select{max-width: 500px;width: 90%!important;}
</style>
<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <Tabs>
        <ui:Panel runat="server" ID="tabSkrillPayCard" IsHtmlCaption="true" Caption="<%$ Metadata:value(/Metadata/PaymentMethod/MoneyMatrix_Skrill.Title) %>" Selected="true">
            <form id="formSkrillPayCard" onsubmit="return false">
                <ui:InputField ID="fldSkrillEmailAddress" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	                <LabelPart><%= this.GetMetadata(".SkrillEmailAddress_Label").SafeHtmlEncode()%></LabelPart>
	                <ControlPart>
                        
                        <%: Html.TextBox("SkrillEmailAddress", "", new 
                        {
                            @id = "txtSkrillEmailAddress",
                            @dir = "ltr",
                            @validator = ClientValidators.Create().Email(this.GetMetadata(".SkrillEmailAddress_Invalid"))
                        }
                        )%>

	                </ControlPart>
                </ui:InputField>
                <center>
                    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnDepositWithSkrillPayCard", @class="ContinueButton button" })%>
                </center>
            </form>
        </ui:Panel>
    </Tabs>
</ui:TabbedContent>


<script language="javascript" type="text/javascript">
    $(document).ready(function () {
        $('#formSkrillPayCard').initializeForm();
        $('#formPrepareDeposit').append($('<input type="hidden" name="SkrillEmailAddress" id="hdnSkrillEmailAddress"/>'));

        $('#btnDepositWithSkrillPayCard').click(function (e) {
            e.preventDefault();

            $('#hdnSkrillEmailAddress').val($('#txtSkrillEmailAddress').val());

            if (!isDepositInputFormValid() || !$('#formSkrillPayCard').valid())
                return false;

            $(this).toggleLoadingSpin(true);

            var payCardID = '<%= GetExistingPayCard().ID.ToString() %>';

            // <%-- post the prepare form --%>   
            tryToSubmitDepositInputForm(payCardID, function () {
                $('#btnDepositWithSkrillPayCard').toggleLoadingSpin(false);
            });
        });

        // <%-- bind event to DEPOSIT_TRANSACTION_PREPARED --%>
        $(document).bind('DEPOSIT_TRANSACTION_PREPARED', function (e, sid) {
            
        });
    });
</script>