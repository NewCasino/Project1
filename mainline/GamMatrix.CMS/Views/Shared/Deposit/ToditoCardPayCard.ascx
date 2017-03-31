<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">
    private PayCardInfoRec GetExistingPayCard()
    {
        return GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.ToditoCard)
            .OrderByDescending(e => e.Ins).FirstOrDefault();
    }
</script>

<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <Tabs>

        <%---------------------------------------------------------------
            ToditoCard
         ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabRecentCards"  IsHtmlCaption="true" Caption="<%$ Metadata:value(/Metadata/PaymentMethod/ToditoCard.Title) %>"  Selected="true">
            <form id="formToditoCardPayCard" method="post" action="<%= this.Url.RouteUrl("Deposit", new { @action = "RegisterPayCard", @vendorID=this.Model.VendorID }).SafeHtmlEncode() %>" enctype="application/x-www-form-urlencoded">

                <%------------------------
                    Card Number
                -------------------------%>    
                <ui:InputField ID="fldCardNumber" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	                <LabelPart><%= this.GetMetadata(".CardNumber_Label").SafeHtmlEncode()%></LabelPart>
	                <ControlPart>

                        <% PayCardInfoRec paycard = GetExistingPayCard(); %>
                        <%: Html.TextBox("identityNumber", ((paycard == null) ? string.Empty : paycard.DisplayNumber), new 
                        { 
                            @maxlength = 12,
                            @dir = "ltr",
                            @validator = ClientValidators.Create().RequiredIf("isCardNumberRequired", this.GetMetadata(".CardNumber_Empty"))
                        } 
                        )%>
                        <%: Html.Hidden("toditoPayCardID", ((paycard == null) ? string.Empty : paycard.ID.ToString())) %>
	                </ControlPart>
                </ui:InputField>
                <script type="text/javascript">
                    //<![CDATA[
                    $(function () {
                        if (!isCardNumberRequired()) {
                            $('#fldCardNumber input[name="identityNumber"]').attr('readonly', true);
                            if ($('#fldCardNumber input[name="identityNumber"]').val().length == 0)
                                $('#fldCardNumber').hide();
                        }
                    });
                    function isCardNumberRequired() {
                        return $('#fldCardNumber input[name="toditoPayCardID"]').val().length == 0;
                    }
                    //]]>
                </script>

                <%------------------------
                    NIP
                -------------------------%>    
                <ui:InputField ID="fldSecurityKey" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	                <LabelPart><%= this.GetMetadata(".SecurityKey_Label").SafeHtmlEncode()%></LabelPart>
	                <ControlPart>
                        <%: Html.TextBox("securityKey", "", new 
                        { 
                            @maxlength = 6,
                            @dir = "ltr",
                            @validator = ClientValidators.Create().Required(this.GetMetadata(".SecurityKey_Empty"))
                        } 
                        )%>
	                </ControlPart>
                </ui:InputField>


                <center>
                    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnDepositWithToditoCardPayCard", @class="ContinueButton button" })%>
                </center>
            </form>

        </ui:Panel>

    </Tabs>
</ui:TabbedContent>

<script type="text/javascript">
//<![CDATA[
    $(function () {
        $('#formToditoCardPayCard').initializeForm();

        $('#btnDepositWithToditoCardPayCard').click(function (e) {
            e.preventDefault();
            if (!isDepositInputFormValid() || !$('#formToditoCardPayCard').valid())
                return false;

            $(this).toggleLoadingSpin(true);

            var payCardID = $('#fldCardNumber input[name="toditoPayCardID"]').val();
            if (payCardID.length > 0) {
                // <%-- post the prepare form --%>   
                tryToSubmitDepositInputForm(payCardID, function () {
                    $('#btnDepositWithToditoCardPayCard').toggleLoadingSpin(false);
                });
                return;
            }

            var options = {
                dataType: "json",
                type: 'POST',
                success: function (json) {

                    if (!json.success) {
                        $('#btnDepositWithToditoCardPayCard').toggleLoadingSpin(false);
                        showDepositError(json.error);
                        return;
                    }
                    // <%-- the card is successfully registered, now prepare the transaction --%>
                    $('#fldCardNumber input[name="toditoPayCardID"]').val(json.payCardID);
                    $('#fldCardNumber input[name="identityNumber"]').attr('readonly', true);

                    // <%-- post the prepare form --%>   
                    tryToSubmitDepositInputForm(json.payCardID, function () {
                        $('#btnDepositWithToditoCardPayCard').toggleLoadingSpin(false);
                    });
                },
                error: function (xhr, textStatus, errorThrown) {
                    $('#btnRegisterCardAndDeposit').toggleLoadingSpin(false);
                    showDepositError(errorThrown);
                }
            };
            $('#formToditoCardPayCard').ajaxForm(options);
            $('#formToditoCardPayCard').submit();
        });

        // <%-- bind event to DEPOSIT_TRANSACTION_PREPARED --%>
        $(document).bind('DEPOSIT_TRANSACTION_PREPARED', function (e, sid) {
            var url = '<%= this.Url.RouteUrl( "Deposit", new { @action = "SaveSecurityKey" }).SafeJavascriptStringEncode() %>';
            var data = { sid: sid, securityKey: $('#fldSecurityKey input[name="securityKey"]').val() };
            jQuery.getJSON(url, data, function (json) {
                if (!json.success) {
                    showDepositError(json.error);
                    return;
                }
            });
        });
    });
//]]>
</script>
