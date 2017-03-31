<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">
    private PayCardInfoRec PayCard { get; set; }
    //private double LimitAmount { get; set; }
    protected bool IsSetupMode { get; set; }

    protected override void OnInit(EventArgs eventArgs)
    {
        IsSetupMode = false;
        
        this.PayCard = GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.Moneybookers)
            .OrderByDescending(e => e.LastSuccessDepositDate).FirstOrDefault();

        if (this.PayCard == null)
            throw new InvalidOperationException("This payment method is not configured in GmCore.");
        
        GetTransRequest request = new GetTransRequest()
        {
            SelectionCriteria = new TransSelectParams()
            {
              ByPaymentTypeFromPreTrans = true,
              PaymentTypeFromPreTrans = "Skrill1TapSetup",
              ByTransTypes = true,
              ParamTransTypes = new List<TransType> { TransType.Deposit },
              ByUserID = true,
              ParamUserID = Profile.UserID,
              ByTransStatuses = true,
              ParamTransStatuses = new List<TransStatus> { TransStatus.Success },
              ByDebitPayableTypes = true,
              ParamDebitPayableTypes = new List<PayableType> { PayableType.Ordinary },
              ByDebitPayItemVendorID = true,
              ParamDebitPayItemVendorID = VendorID.Moneybookers,
            },
            PagedData = new PagedDataOfTransInfoRec
            {
                PageSize = 1,
                PageNumber = 0,
            }
        };
        using (GamMatrixClient client = new GamMatrixClient())
        {
            List<TransInfoRec> records = client.SingleRequest<GetTransRequest>(request).PagedData.Records;
            IsSetupMode = records == null || records.Count == 0;
        }
        
        base.OnInit(eventArgs);
    }

    protected override void OnPreRender(EventArgs e)
    {
        btnChangeMaxAmount.Visible = !IsSetupMode;
        base.OnPreRender(e);
    }
</script>

<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <Tabs>
    
        <%---------------------------------------------------------------
            Moneybookers
         ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabRecentCards" IsHtmlCaption="true" Caption="<%$ Metadata:value(/Metadata/PaymentMethod/Moneybookers_1Tap.Title) %>" Selected="true">
            <form id="formMoneybookersPayCard" onsubmit="return false">


                <ui:InputField ID="fldSkrill1TapMaxAmount" runat="server" style="display:none" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	                <LabelPart><%= this.GetMetadata(".Skrill1TapLimit_Label").SafeHtmlEncode()%></LabelPart>
	                <ControlPart>
                        <%: Html.TextBox("maxAmount", "", new 
                        { 
                            @id="txtSkrill1TapMaxAmount",
                            @maxlength=10,
                            @dir = "ltr",
                            @value=0.00,
                            @validator = ClientValidators.Create()
                                        .Required(this.GetMetadata(".Skrill1TapLimit_Empty"))
                                        .Custom("validateLimitAmount")
                        } 
                        )%>
	                </ControlPart>
                </ui:InputField>
                <script language="javascript" type="text/javascript">
                    //<![CDATA[

                    function validateLimitAmount() {
                        var value = this;
                        var limitAmount = parseFloat(value, 10);
                        if ( isNaN(value) || limitAmount <= 0 )
                            return '<%= this.GetMetadata(".Skrill1TapLimit_Label").SafeJavascriptStringEncode() %>';
                        
                        if( limitAmount > Number.MAX_VALUE){
                            return '<%= this.GetMetadata(".Skrill1TapLimit_Label").SafeJavascriptStringEncode() %>';
                        }

                    return true;
                }
                //]]>
            </script>


                <%: Html.Hidden("moneybookerPayCardID", PayCard.ID.ToString())%>

                <br />
                <center>
                    <ui:Button runat="server" id="btnChangeMaxAmount" Text="<%$ Metadata:value(.Button_ChangeMaxAmount) %>"></ui:Button>
                    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnDepositWithMoneybookersPayCard", @class="ContinueButton button" })%>
                </center>
            </form>

        </ui:Panel>

    </Tabs>
</ui:TabbedContent>


<script type="text/javascript">
//<![CDATA[
    $(function () {
        $('#formMoneybookersPayCard').initializeForm();

        var setupMode = <%=IsSetupMode.ToString().ToLowerInvariant()%>;
        if (setupMode) {
            $('#fldSkrill1TapMaxAmount').show();
            $('#btnChangeMaxAmount').hide();
        } else {
            $('#fldSkrill1TapMaxAmount').hide();
            $('#btnChangeMaxAmount').show();
        }
                    
        <%--if( <%= (LimitAmount>0).ToString().ToLowerInvariant() %> )
            $('#fldSkrill1TapMaxAmount').show();--%>

        $('#txtSkrill1TapMaxAmount').change(function (e) {
            $(this).val(formatAmount($(this).val()));
        });

        $('#btnChangeMaxAmount').click(function (e) {
            e.preventDefault();
            $(this).remove();
            $('#fldSkrill1TapMaxAmount').show();
        });

        $('#btnDepositWithMoneybookersPayCard').click(function (e) {
            e.preventDefault();
            if (!isDepositInputFormValid()|| !$('#formMoneybookersPayCard').valid())
                return false;

            $(this).toggleLoadingSpin(true);

            $('#formPrepareDeposit :hidden[name="paymentType"]').remove();
            $('#formPrepareDeposit :hidden[name="tempExternalReference"]').remove();

            $('<input type="hidden" name="paymentType" />').appendTo('#formPrepareDeposit').val(
                $('#txtSkrill1TapMaxAmount').is(':visible') ? 'Skrill1TapSetup' : 'Skrill1Tap'
            );

            $('<input type="hidden" name="tempExternalReference" />').appendTo('#formPrepareDeposit').val(
                $('#txtSkrill1TapMaxAmount').val()
            );

            var payCardID = $('#formMoneybookersPayCard input[name="moneybookerPayCardID"]').val();
            // <%-- post the prepare form --%>   
            tryToSubmitDepositInputForm(payCardID, function () {
                $('#btnDepositWithMoneybookersPayCard').toggleLoadingSpin(false);
            });
        });

        function formatAmount(num) {
            num = num.toString().replace(/[^\.\d]/g, '');
            if (isNaN(num)) num = '0';
            sign = (num == (num = Math.abs(num)));
            num = Math.floor(num * 100 + 0.50000000001);
            cents = num % 100;
            num = Math.floor(num / 100).toString();
            if (cents < 10) cents = '0' + cents;
            return num + '.' + cents;
        }

    });
//]]>
</script>
