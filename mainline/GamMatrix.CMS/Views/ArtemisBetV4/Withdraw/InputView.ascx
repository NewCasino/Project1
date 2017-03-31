<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GamMatrixAPI" %>

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

    private string GetLimitationScript()
    {
        decimal dailyLimit = int.MaxValue;
        try
        {
            GetUserDailyLimitsRequest request = new GetUserDailyLimitsRequest()
            {
                TransType = TransType.Withdraw,
                UserID = Profile.UserID,
                RequestCurrency = "EUR",
                VendorID = this.Model.VendorID,
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

        foreach (string currency in this.Model.SupportedCurrencies.GetAll())
        {
            Range limitation = this.Model.GetWithdrawLimitation(currency);
            decimal minAmount = limitation.MinAmount;
            decimal maxAmount = limitation.MaxAmount;
            if (maxAmount > 0)
                MoneyHelper.SmoothCeilingAndFloor(ref minAmount, ref maxAmount);


            var symbol = MoneyHelper.FormatCurrencySymbol(currency);
            if (String.IsNullOrWhiteSpace(symbol))
            {
                symbol = currency;
            }
            
            sb.AppendFormat(CultureInfo.InvariantCulture, "__currency_limit['{0}'] = {{ MinAmount:{1}, MaxAmount:{2}, DailyLimit:{3}, Symbol:'{4}' }};"
                , currency.SafeJavascriptStringEncode()
                , minAmount
                , maxAmount
                , (dailyLimit >= int.MaxValue) ? ((object)"Number.MAX_VALUE") : MoneyHelper.TransformCurrency("EUR", currency, dailyLimit)
                , symbol.SafeJavascriptStringEncode()
                );
        }

        return sb.ToString();
    }

    private string GetCurrencyRatesScript()
    {
        StringBuilder sb = new StringBuilder();
        Dictionary<string, CurrencyExchangeRateRec> currencies = GamMatrixClient.GetCurrencyRates();
        sb.Append("var __currency_rates = {");

        foreach (var currency in currencies)
        {
            sb.AppendFormat(CultureInfo.InvariantCulture, " \"{0}\":{1:F2},"
                , currency.Key.SafeJavascriptStringEncode()
                , currency.Value.MidRate
                );
        }

        if (sb[sb.Length - 1] == ',')
            sb.Remove(sb.Length - 1, 1);

        sb.Append("};");
        return sb.ToString();
    }
    private string GetPropertiesJson()
    {
        StringBuilder sb = new StringBuilder();
        sb.Append("var paymentMethodProperties = {");
        sb.AppendFormat(@" ""uniquename"" : ""{0}"" ", this.Model.UniqueName.SafeJavascriptStringEncode());
        sb.AppendFormat(@", ""fee"": ""{0}"" ", this.Model.WithdrawProcessFee.GetText(this.ViewData.GetValue<string>("Currency", "EUR")).SafeJavascriptStringEncode());
        sb.AppendFormat(@", ""resourcekey"": ""{0}"" ", this.Model.ResourceKey.SafeJavascriptStringEncode());
        sb.AppendFormat(@", ""categoryDisplayName"": ""{0}"" ", this.Model.Category.GetDisplayName().SafeJavascriptStringEncode());
        sb.Append("}");
        return sb.ToString();
    }
</script>

<script type="text/javascript">
    <%=GetPropertiesJson() %>
</script>

<% using (Html.BeginRouteForm("Withdraw", new { @action = "PrepareTransaction", @paymentMethodName = this.Model.UniqueName }, FormMethod.Post, new { @id = "formPrepareWithdraw" }))
   { %>

<%------------------------------------------
    IovationBlackbox
 -------------------------------------------%>
  <%if (Settings.IovationDeviceTrack_Enabled){ %>
        <% Html.RenderPartial("/Components/IovationTrack", this.ViewData);  %>
        <%} %>

<%------------------------------------------
    RequestCreditCurrency
 -------------------------------------------%>
<%: Html.Hidden("requestCreditCurrency", string.Empty, new { @id = "hRepareTransactionRequestCreditCurrency" })%>

<%------------------------------------------
    Gamming Accounts
 -------------------------------------------%>
<ui:InputField ID="fldGammingAccount" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <labelpart><%= this.GetMetadata(".GammingAccount_Label").SafeHtmlEncode()%></labelpart>
    <controlpart>
        <% Html.RenderPartial("/Components/GammingAccountSelector", this.ViewData.Merge(new
           {
               @AutoSelect = true,
               @TableID = "table_gamming_account",
               @ClientOnChangeFunction = "onGammingAccountChanged",
               @DisplayBonusAmount = Settings.Withdrawal_DisplayBonusAmount,
           })); %>
        <%: Html.Hidden("gammingAccountID", "", new { @id = "txtGammingAccountID", @validator = ClientValidators.Create().Required(this.GetMetadata(".GammingAccount_Empty")) })%>
</controlpart>
</ui:InputField>
<script type="text/javascript">
    //<![CDATA[
    var __amount_on_account = 0.00;
    var __account_currency = 'EUR';
    var __account_display_name = '';
    function onGammingAccountChanged(key, data) {
        $('#txtGammingAccountID').val(key);
        //<%-- trigger the validation --%>
        if (InputFields.fields['fldGammingAccount'])
            InputFields.fields['fldGammingAccount'].validator.element($('#txtGammingAccountID'));

        //<%-- change the currency --%>
        $('#ddlCurrency').val(data.BalanceCurrency);
        __amount_on_account = data.BalanceAmount;
        __account_currency = data.BalanceCurrency;
        __account_display_name = data.DisplayName;
        onCurrencyChange();

        $(document.body).trigger('GAMING_ACCOUNT_SEL_CHANGED', data);
    }
    //]]>
</script>


<%------------------------------------------
    Currency and Amount
 -------------------------------------------%>
<ui:InputField ID="fldCurrencyAmount" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <labelpart><%= this.GetMetadata(".CurrencyAmount_Label").SafeHtmlEncode()%></labelpart>
    <controlpart>
        <div class="holder-flex-100">
            <div class="col-50">        
                <%: Html.DropDownList("currency2", GetCurrencyList(), new { @class = "ddlMoneyCurrency", @id="ddlCurrency", @disabled ="disabled",  @onchange="onCurrencyChange()"  })%>
                <%-- We need another hide field for the currency 
                because the currency value will not be included in POST request if the dropdownlist is disabled. --%>
                <%: Html.Hidden( "currency" ) %>
            </div>
            <div class="col-50">        
                <%: Html.AnonymousCachedPartial("/Components/Amount", this.ViewData)%>
                <%: Html.Hidden("payCardID", "") %>
            </div>
     </div>
</controlpart>
    <hintpart>
        <ul class="limit-ul">
            <li id="tdCurrentNotes" style="display:none">
            </li>
            <li id="tdMinLimit" style="display:none">
                <span class="TableCell"><%= this.GetMetadata(".Min").SafeHtmlEncode() %></span>
                <span class="TableCell currency"></span>
                <span class="TableCell amount"></span>
            </li>
            <li id="tdMaxLimit" style="display:none">
                <span class="TableCell"><%= this.GetMetadata(".Max").SafeHtmlEncode() %></span>
                <span class="TableCell currency"></span>
                <span class="TableCell amount"></span>
            </li>
            <li id="tdDailyLimit" style="display:none">
                <span class="TableCell"><%= this.GetMetadata(".DailyLimit").SafeHtmlEncode() %></span>
                <span class="TableCell currency"></span>
                <span class="TableCell amount"></span>
            </li>
        </ul>        
    </hintpart>
</ui:InputField>
<%: Html.WarningMessage( this.GetMetadata(".NOKNotice_Text").SafeHtmlEncode() ,false,new { id = "NokNotice",style="display:none"  }) %>


<script language="javascript" type="text/javascript">
    function checkNOKAndNotice (){
        var IsWhiteLabelOP =  <%=Settings.Site_IsUnWhitelabel ? "true" : "false"%> ;
        var IsBankTransfer = <%=this.Model.UniqueName.Equals("BankTransfer") ? "true" : "false" %> ;
        if( IsBankTransfer && !IsWhiteLabelOP && $("#currency").val() == "NOK"){
            $("#NokNotice").show();
        }
    }
    $(function(){
        checkNOKAndNotice();
    });
    //<![CDATA[ 
    <%= GetLimitationScript() %>
    <%= GetCurrencyRatesScript() %> 

  

    // <%-- Different currency --%>
    $("document").bind("Amount_Blur",function(){
        showDebitAmount(); 
    });
    function showDebitAmount(){
        $('#tdCurrentNotes').hide();
        if( __account_currency == $('#ddlCurrency').val() )
            return;

        var value = $('#txtAmount').data('fillvalue');
        var amount = parseFloat( value.replace(/\$|\,/g, ''), 10);
        if ( amount > 0.00 ){
            var amount = amount / __currency_rates[$('#ddlCurrency').val()] * __currency_rates[__account_currency];

            var text = '<%= this.GetMetadata(".Debit_Amount").SafeJavascriptStringEncode() %>';
        text = text.replace( /(\{0\})/g, __account_display_name);
        text = text.replace( /(\{1\})/g, __account_currency);
        text = text.replace( /(\{2\})/g, amount.toFixed(2));
        $('#tdCurrentNotes').text(text).show();
    }    
} 
var __min_limit = 0.00;
var __max_limit = 0.00;
var __daily_limit = Number.MAX_VALUE;
var __currency_symbol;

var isFromLocker = false;
function onCurrencyChange(){    

    $('#fldCurrencyAmount input[name="currency"]').val( $('#ddlCurrency').val() );
    var limit = __currency_limit[$('#ddlCurrency').val()];
    if( limit != null ){
        __min_limit = limit.MinAmount;
        __max_limit = limit.MaxAmount;
        __daily_limit = limit.DailyLimit;
        __currency_symbol = limit.Symbol;
        $('#tdMinLimit').css( 'display', ((__min_limit > 0.00) ? '' : 'none') );
        $('#tdMaxLimit').css( 'display', ((__max_limit > 0.00) ? '' : 'none') );
        $('#tdDailyLimit').css('display', ((__daily_limit < Number.MAX_VALUE) ? '' : 'none'));
        $('#tdMinLimit .currency').text(__currency_symbol);
        $('#tdMaxLimit .currency').text(__currency_symbol);
        $('#tdDailyLimit .currency').text(__currency_symbol);
        $('#tdMinLimit .amount').text(formatAmount(__min_limit) );
        $('#tdMaxLimit .amount').text(formatAmount(__max_limit) );
        $('#tdDailyLimit .amount').text(formatAmount(__daily_limit));
    }

    showDebitAmount();
    checkNOKAndNotice();
}

function validateAmount(){
    // <%-- Ensure the gamming account is selected --%>
    if( InputFields.fields['fldGammingAccount'] ){
        if( !InputFields.fields['fldGammingAccount'].validator.element($('#txtGammingAccountID')) )
            return true;
    }
    var amount = 0;
    if($('#txtAmount').data('fillvalue') != GetRealAmount($('#txtAmount').val()) ){ 
        amount = $('#txtAmount').val();
    }
    else{
        amount = $('#txtAmount').data('fillvalue');
    } 
    if(  
        amount.toString().indexOf(',') > 0 || 
        amount.toString().indexOf("'") > 0 || 
        amount.toString().indexOf(" ") > 0 || 
        amount.toString().indexOf("-") > 0  ){ 
        amount = GetRealAmount($('#txtAmount').val()); 
    } 
    amount = parseFloat( amount, 10);
    if ( isNaN(amount) || amount <= 0.00 )
        return '<%= this.GetMetadata(".CurrencyAmount_Empty").SafeJavascriptStringEncode() %>';
    if( (__min_limit > 0.00 && amount < __min_limit) ||
        (__max_limit > 0.00 && amount > __max_limit) ){
        return '<%= this.GetMetadata(".CurrencyAmount_OutsideRange").SafeJavascriptStringEncode() %>';
    }

    if (amount > __daily_limit)
        return '<%= this.GetMetadata(".CurrencyAmount_DailyLimit").SafeJavascriptStringEncode() %>';

    var value = amount;
    if( __account_currency != $('#ddlCurrency').val() ){
        value = value / __currency_rates[$('#ddlCurrency').val()] * __currency_rates[__account_currency];
    } 
    if( value > __amount_on_account )
        return '<%= this.GetMetadata(".CurrencyAmount_Insufficient").SafeJavascriptStringEncode() %>';

    try{
        var ret = __customValidateAmount(amount);
        if( ret != true )
            return ret;
    }
    catch(e){
    }
    $("#txtAmount").removeClass("error");
    return true;
}

//]]>
</script>



<% }// form end %>


<script language="javascript" type="text/javascript">
    $(document).ready(function () {
        $('#ddlCurrency').removeAttr('locked');
        $('#formPrepareWithdraw').initializeForm();
    });

    var g_WithdrawInputFormCallback = null;
    function tryToSubmitWithdrawInputForm(payCardID, callback) {
        $('#fldCurrencyAmount input[name="payCardID"]').val(payCardID);
        if (!$('#formPrepareWithdraw').valid()) {
            if (callback !== null) callback();
            return false;
        }

        g_WithdrawInputFormCallback = callback;
        var options = {
            dataType: "json",
            type: 'POST',
            success: function (json) {
                if (g_WithdrawInputFormCallback !== null)
                    g_WithdrawInputFormCallback();

                if (!json.success) {
                    showWithdrawError(json.error);
                    return;
                }

                // <%-- trigger the WITHDRAW_TRANSACTION_PREPARED event --%>
            $(document).trigger('WITHDRAW_TRANSACTION_PREPARED', json.sid);
            showWithdrawConfirmation(json.sid);
        },
        error: function (xhr, textStatus, errorThrown) {
            if (g_WithdrawInputFormCallback !== null)
                g_WithdrawInputFormCallback();
            showWithdrawError(errorThrown);
        }
    };
    $('#formPrepareWithdraw').ajaxForm(options);
    $('#formPrepareWithdraw').submit();
    return true;
}

function isWithdrawInputFormValid() {
    return $('#formPrepareWithdraw').valid();
}
</script>
