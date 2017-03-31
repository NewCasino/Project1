<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>

<script language="C#" type="text/C#" runat="server">
    private SelectList GetCurrencyList()
    {
        var list = GamMatrixClient.GetSupportedCurrencies()
                        .Select(c => new { Key = c.Code, Value = c.GetDisplayName() })
                        .ToList();
        return new SelectList(list
            , "Key"
            , "Value"
            );
    }

    private const decimal HARDCODED_MIN_LIMIT = 0.01M;
    private const decimal HARDCODED_MAX_LIMIT = 10000.00M;
    private string GetLimitationScript()
    {
        decimal dailyLimit = int.MaxValue;
        try
        {
            GetUserDailyLimitsRequest request = new GetUserDailyLimitsRequest()
            {
                TransType = TransType.Transfer,
                UserID = Profile.UserID,
                RequestCurrency = "EUR",
                VendorID = VendorID.Unknown,
            };
            using (GamMatrixClient client = GamMatrixClient.Get())
            {
                request = client.SingleRequest<GetUserDailyLimitsRequest>(request);
                dailyLimit = request.AvailableAmountInRequestCurrency;
            }
        }
        catch (Exception ex)
        {
            Logger.Exception(ex);
        }
        
        StringBuilder sb = new StringBuilder();
        sb.AppendFormat(CultureInfo.InvariantCulture, "var __currency_limit = [];");

        foreach (CurrencyData currency in GamMatrixClient.GetSupportedCurrencies())
        {
            decimal minAmount = HARDCODED_MIN_LIMIT;
            decimal maxAmount = MoneyHelper.TransformCurrency( "EUR"
                , currency.ISO4217_Alpha
                , HARDCODED_MAX_LIMIT
                );
            maxAmount = MoneyHelper.SmoothCeiling(maxAmount);
            sb.AppendFormat(CultureInfo.InvariantCulture, "__currency_limit['{0}']={{'MinAmount':{1},'MaxAmount':{2},'DailyLimit':{3}}};"
                , currency.ISO4217_Alpha.SafeJavascriptStringEncode()
                , minAmount
                , maxAmount
                , (dailyLimit >= int.MaxValue) ? ((object)"Number.MAX_VALUE") : MoneyHelper.TransformCurrency("EUR", currency.Code, dailyLimit) 
                );
        }

        return sb.ToString();
    }
</script>




<%
    using( Html.BeginRouteForm( "Transfer"
       , new { @action = "PrepareTransaction" }
       , FormMethod.Post
       , new { @id = "formTransfer" }) )
   { %>

   <table cellpadding="0" cellspacing="0" border="0" width="100%">
    <tr>
        <tr>
            <td align="center" colspan="3" class="transfer-money-image-wrapper">
                <div id="transfer-money-image"></div>
            </td>
        </tr>
        <td valign="top">
            <%------------------------------------------
                 Debit Gamming Accounts
            -------------------------------------------%>
            <ui:InputField ID="fldDebitGammingAccount" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".DebitGammingAccount_Label").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>
                    <% Html.RenderPartial("/Components/GammingAccountSelector", this.ViewData.Merge(new
                        {
                            @TableID = "table_debit_gamming_account",
                            @ClientOnChangeFunction = "onDebitGammingAccountChanged",               
                        }) ); %>
                    <%: Html.Hidden("debitGammingAccountID", "", new { 
                        @id = "txtDebitGammingAccountID", 
                        @validator = ClientValidators.Create().Required(this.GetMetadata(".DebitGammingAccount_Empty")) 
                    })%>
	            </ControlPart>
            </ui:InputField>
            <script type="text/javascript">
            //<![CDATA[
                var __amount_on_account = 0.00;
                function onDebitGammingAccountChanged(key, data) {
                    $('#txtDebitGammingAccountID').val(key);

                    if ($('#table_credit_gamming_account').getSelectableTableValueField() == key) {
                        $('#table_credit_gamming_account').removeSelection();
                    }
                    $('#ddlCurrency').val(data.BalanceCurrency);
                    onCurrencyChange();
                    __amount_on_account = data.BalanceAmount;

                    //<%-- trigger the validation --%>
                    if (InputFields.fields['fldDebitGammingAccount'])
                        InputFields.fields['fldDebitGammingAccount'].validator.element($('#txtDebitGammingAccountID'));

                }

                
            //]]>
            </script>

           


            <%------------------------------------------
                    Currency and Amount
            -------------------------------------------%>
            <ui:InputField ID="fldCurrencyAmount" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".CurrencyAmount_Label").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>
                    <table cellpadding="0" cellspacing="0" border="0">
                    <tr>
                        <td>
                            <%: Html.DropDownList("currency2", GetCurrencyList(), new { @class = "ddlMoneyCurrency", @id="ddlCurrency", @disabled ="disabled" })%>
                            <%-- We need another hide field for the currency 
                            because the currency value will not be included in POST request if the dropdownlist is disabled. --%>
                            <%: Html.Hidden( "currency" ) %>
                        </td>
                        <td>&#160;</td>
                        <td>
                            <%: Html.AnonymousCachedPartial("/Components/Amount", this.ViewData)%>
                            <%: Html.Hidden("payCardID", "") %>
                        </td>
                    </tr>
                </table>
	            </ControlPart>
                <HintPart>
                <ul class="limit-ul">
                    <li id="tdMinLimit" style="display:none">
                        <table cellpadding="2" cellspacing="0">
                            <tr>
                                <td><%= this.GetMetadata(".Min").SafeHtmlEncode() %></td>
                                <td class="currency"></td>
                                <td class="amount"></td>
                            </tr>
                        </table>
                    </li>
                    <li id="tdMaxLimit" style="display:none">
                        <table cellpadding="2" cellspacing="0">
                            <tr>
                                <td><%= this.GetMetadata(".Max").SafeHtmlEncode()%></td>
                                <td class="currency"></td>
                                <td class="amount"></td>
                            </tr>
                        </table>
                    </li>
                    <li id="tdDailyLimit" style="display:none">
                        <span class="TableCell"><%= this.GetMetadata(".DailyLimit").SafeHtmlEncode() %></span>
                        <span class="TableCell currency"></span>
                        <span class="TableCell amount"></span>
                    </li>
                </ul>        
            </HintPart>
            </ui:InputField>
        </td>
        <td></td>
        <td valign="top">
            <%------------------------------------------
                 Credit Gamming Accounts
            -------------------------------------------%>
            <ui:InputField ID="fldCreditGammingAccount" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".CreditGammingAccount_Label").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>
                    <% Html.RenderPartial("/Components/GammingAccountSelector", this.ViewData.Merge(new
                        {
                            @TableID = "table_credit_gamming_account",
                            @ClientOnChangeFunction = "onCreditGammingAccountChanged",               
                        }) ); %>
                    <%: Html.Hidden("creditGammingAccountID", "", new { 
                        @id = "txtCreditGammingAccountID", 
                        @validator = ClientValidators.Create().Required(this.GetMetadata(".CreditGammingAccount_Empty")) 
                    })%>
	            </ControlPart>
            </ui:InputField>
            <script type="text/javascript">
            //<![CDATA[
                function onCreditGammingAccountChanged(key, data) {
                    $('#txtCreditGammingAccountID').val(key);

                    if ($('#table_debit_gamming_account').getSelectableTableValueField() == key) {
                        $('#table_debit_gamming_account').removeSelection();
                    }

                    //<%-- trigger the validation --%>
                    if (InputFields.fields['fldCreditGammingAccount'])
                        InputFields.fields['fldCreditGammingAccount'].validator.element($('#txtCreditGammingAccountID'));

                    $(document).trigger('GAMING_ACCOUNT_SEL_CHANGED', data); 
                }


            //]]>
            </script>
            
        </td>
    </tr>
    <tr>
        <td colspan="3">
             <%------------------------------------------
                Deposit Bonus Code
            -------------------------------------------%>
            <% Html.RenderPartial("/Deposit/BonusCode", this.ViewData.Merge( new { TransType = TransType.Transfer } )); %>
        </td>
    </tr>
    
    <tr>
        <td colspan="3">
            <%: Html.Button( this.GetMetadata(".Button_Transfer"), new { @id = "btnTransferMoney" } ) %>
            <%: Html.Button( this.GetMetadata(".Button_TransferAll"), new { @id = "btnTransferAllMoney", @type="button" } ) %>
        </td>
    </tr>
   </table>
<% } %>

<script type="text/javascript">
//<![CDATA[
// <%-- Format the input amount to comma seperated amount --%>
//function formatAmount(num) {
//    num = num.toString().replace(/\$|\,/g, '');
//    if (isNaN(num)) num = '0';
//    sign = (num == (num = Math.abs(num)));
//    num = Math.floor(num * 100 + 0.50000000001);
//    cents = num % 100;
//    num = Math.floor(num / 100).toString();
//    if (cents < 10) cents = '0' + cents;
//    for (var i = 0; i < Math.floor((num.length - (1 + i)) / 3); i++)
//    num = num.substring(0, num.length - (4 * i + 3)) + ',' + num.substring(num.length - (4 * i + 3));
//    return num + '.' + cents;
//}
<%= GetLimitationScript() %>
//function onAmountChange() {
//    $('#txtAmount').val(formatAmount($('#txtAmount').val()));
//};
//function onAmountFocus() {
//    $('#txtAmount').val($('#txtAmount').val().replace(/\$|\,/g, '')).select();
//}
var __min_limit = 0.00;
var __max_limit = 0.00;
var __daily_limit = Number.MAX_VALUE;

function onCurrencyChange(){
    $('#fldCurrencyAmount input[name="currency"]').val( $('#ddlCurrency').val() );
    var limit = __currency_limit[$('#ddlCurrency').val()];
    if( limit != null ){
        __min_limit = limit.MinAmount;
        __max_limit = limit.MaxAmount;
        __daily_limit = limit.DailyLimit;
        $('#tdMinLimit').css( 'display', '');
        $('#tdMaxLimit').css('display', ((__max_limit > 0.00) ? '' : 'none'));
        $('#tdDailyLimit').css('display', ((__daily_limit < Number.MAX_VALUE) ? '' : 'none'));
        $('#tdMinLimit .currency').text($('#ddlCurrency').val());
        $('#tdMaxLimit .currency').text($('#ddlCurrency').val());
        $('#tdDailyLimit .currency').text($('#ddlCurrency').val());
        $('#tdMinLimit .amount').text(formatAmount(__min_limit) );
        $('#tdMaxLimit .amount').text(formatAmount(__max_limit));
        $('#tdDailyLimit .amount').text(formatAmount(__daily_limit));
    }
}
function validateAmount(){
    // <%-- Ensure the gamming account is selected --%>
    if( InputFields.fields['fldDebitGammingAccount'] && InputFields.fields['fldCreditGammingAccount'] ){
        if( !InputFields.fields['fldDebitGammingAccount'].validator.element($('#txtDebitGammingAccountID')) ||
            !InputFields.fields['fldCreditGammingAccount'].validator.element($('#txtCreditGammingAccountID')) )
            return true;
    }

    var value = 0;
    if ($('#txtAmount').data('fillvalue') != GetRealAmount($('#txtAmount').val())) {
        value = $('#txtAmount').val();
    }
    else {
        value = $('#txtAmount').data('fillvalue');
    }
    if (value.toString().indexOf(',') > 0 ||
        value.toString().indexOf("'") > 0 ||
        value.toString().indexOf(" ") > 0 ||
        value.toString().indexOf("-") > 0) {
        value = GetRealAmount($('#txtAmount').val());
    }
    if ( isNaN(value) || parseFloat(value, 10) <= 0 )
        return '<%= this.GetMetadata(".CurrencyAmount_Empty").SafeJavascriptStringEncode() %>';

    var amount = parseFloat(value, 10);
    if ((__min_limit > 0.00 && amount < __min_limit) ||
        (__max_limit > 0.00 && amount > __max_limit)) {
        return '<%= this.GetMetadata(".CurrencyAmount_OutsideRange").SafeJavascriptStringEncode() %>';
    }

    if (amount > __daily_limit)
        return '<%= this.GetMetadata(".CurrencyAmount_DailyLimit").SafeJavascriptStringEncode() %>';

    if( parseFloat(value, 10) > __amount_on_account )
        return '<%= this.GetMetadata(".CurrencyAmount_Insufficient").SafeJavascriptStringEncode() %>';
    return true;
}


//]]>
</script>





<script type="text/javascript">
    $(function () {
        $('#formTransfer').initializeForm();

        $('#btnTransferAllMoney').click(function (e) {
            var key = $('#table_debit_gamming_account').getSelectableTableValueField();
            if (key != null) {
                var amount = $('#table_debit_gamming_account').getSelectableTableData()[key].BalanceAmount;
                $('#fldCurrencyAmount #txtAmount,input[name="amount"]').val(formatAmount(amount));
            };
            $('#btnTransferMoney').trigger('click');
        });

        $('#btnTransferMoney').click(function (e) {
            e.preventDefault();

            if (!$('#formTransfer').valid())
                return;

            $(this).toggleLoadingSpin(true);

            var options = {
                dataType: "json",
                type: 'POST',
                success: function (json) {
                    $('#btnTransferMoney').toggleLoadingSpin(false);
                    // <%-- the card is successfully registered, now prepare the transaction --%>
                    if (!json.success) {
                        showTransferError(json.error);
                        return;
                    }

                    // <%-- trigger the TRANSFER_TRANSACTION_PREPARED event --%>
                    $(document).trigger('TRANSFER_TRANSACTION_PREPARED', json.sid);
                    showTransferConfirmation(json.sid);
                },
                error: function (xhr, textStatus, errorThrown) {
                    $('#btnTransferMoney').toggleLoadingSpin(false);
                    showTransferError(errorThrown);
                }
            };
            $('#formTransfer').ajaxForm(options);
            $('#formTransfer').submit();
        });
    });
</script>

<%  Html.RenderPartial("PrepareBodyPlus", this.ViewData ); %>
