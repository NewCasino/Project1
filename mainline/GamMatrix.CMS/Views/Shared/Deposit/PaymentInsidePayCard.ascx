<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">
    private PayCardInfoRec PayCard { get; set; }
    private PayCardInfoRec GetExistingPayCard()
    {
        if (this.PayCard == null)
        {
            this.PayCard = GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.PaymentInside)
            .OrderByDescending(e => e.LastSuccessDepositDate).FirstOrDefault();
        }
        if (this.PayCard == null)
            throw new InvalidOperationException("This payment method is not configured in GmCore.");
        return this.PayCard;
    }
</script>

<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <Tabs>

        <%---------------------------------------------------------------
            Moneybookers
         ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabRecentCards" IsHtmlCaption="true" Caption="<%$ Metadata:value(/Metadata/PaymentMethod/PaymentInside.Title) %>" Selected="true">
            <form id="formPaymentInsidePayCard" onsubmit="return false">
                <%------------------------
                    Email
                    
                    The MB deposit is a bit different from other payment method.
                    When user first deposit, use a dummy card and there is nothing to fill for the user.
                    And after a successful deposit, the email field is shown and filled with the email address
                -------------------------%>    
                <%: Html.Hidden("paymentInsidePayCardID", GetExistingPayCard().ID.ToString())%>
                <% PayCardInfoRec payCard = GetExistingPayCard();
                   if (!payCard.IsDummy && !string.IsNullOrWhiteSpace(payCard.DisplayNumber) )
                   { %>
                
                <ui:InputField ID="fldEmail" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	                <LabelPart><%= this.GetMetadata(".Email_Label").SafeHtmlEncode()%></LabelPart>
	                <ControlPart>

                        
                        <%: Html.TextBox("identityNumber", GetExistingPayCard().DisplayNumber, new 
                        { 
                            @maxlength = 255,
                            @dir = "ltr",
                            @readonly = "readonly",
                        } 
                        )%>                        
	                </ControlPart>
                </ui:InputField>


                <% } %>
                <br />
                <center>
                    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnDepositWithPaymentInsidePayCard", @class="ContinueButton button" })%>
                </center>
            </form>

        </ui:Panel>

    </Tabs>
</ui:TabbedContent>


<script type="text/javascript">
//<![CDATA[
    $(function () {
        $('#formPaymentInsidePayCard').initializeForm();

        $('#btnDepositWithPaymentInsidePayCard').click(function (e) {
            e.preventDefault();
            if (!isDepositInputFormValid() )
                return false;

            $(this).toggleLoadingSpin(true);

            var payCardID = $('#formPaymentInsidePayCard input[name="paymentInsidePayCardID"]').val();
            // <%-- post the prepare form --%>   
            tryToSubmitDepositInputForm(payCardID, function () {
                $('#btnDepositWithPaymentInsidePayCard').toggleLoadingSpin(false);
            });
        });
    });
//]]>
</script>
