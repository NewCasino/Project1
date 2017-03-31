<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>

<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">
    private PayCardInfoRec PayCard { get; set; }
    private PayCardInfoRec GetExistingPayCard()
    {
        if (this.PayCard == null)
        {
            this.PayCard = GamMatrixClient.GetPayCards(VendorID.Dotpay)
            .OrderByDescending(e => e.LastSuccessDepositDate)
            .FirstOrDefault(e => e.DisplayNumber.Length > 0);
        }
        if (this.PayCard == null)
            throw new InvalidOperationException("This payment method is not configured in GmCore.");
        return this.PayCard;
    }
</script>

<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <Tabs>

        <%---------------------------------------------------------------
            Dotpay
         ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabRecentCards" IsHtmlCaption="true" Caption="<%$ Metadata:value(/Metadata/PaymentMethod/Dotpay.Title) %>" Selected="true">
            <form id="formDotpayPayCard" onsubmit="return false">

                <%------------------------
                   
                -------------------------%>    
                <%: Html.Hidden("dotpayPayCardID", GetExistingPayCard().ID.ToString())%>

                <%-- 
                <% PayCardInfoRec payCard = GetExistingPayCard();
                   if (!payCard.IsDummy)
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
                --%>
                <center>
                    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnDepositWithDotpayPayCard", @class="ContinueButton button" })%>
                </center>
            </form>

        </ui:Panel>

    </Tabs>
</ui:TabbedContent>


<script language="javascript" type="text/javascript">
//<![CDATA[
    $(document).ready(function () {
        $('#formDotpayPayCard').initializeForm();

        $('#btnDepositWithDotpayPayCard').click(function (e) {
            e.preventDefault();
            if (!isDepositInputFormValid())
                return false;

            $(this).toggleLoadingSpin(true);

            var payCardID = $('#formDotpayPayCard input[name="dotpayPayCardID"]').val();
            // <%-- post the prepare form --%>   
            tryToSubmitDepositInputForm(payCardID, function () {
                $('#btnDepositWithDotpayPayCard').toggleLoadingSpin(false);
            });
        });
    });
//]]>
</script>
