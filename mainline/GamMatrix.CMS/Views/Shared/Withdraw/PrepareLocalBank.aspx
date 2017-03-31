<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<Finance.PaymentMethod>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
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
        StringBuilder sb = new StringBuilder();
        sb.AppendFormat(CultureInfo.InvariantCulture, "var __currency_limit = [];");

        foreach (string currency in this.Model.SupportedCurrencies.GetAll())
        {
            Range limitation = this.Model.GetWithdrawLimitation(currency);
            decimal minAmount = limitation.MinAmount;
            decimal maxAmount = limitation.MaxAmount;
            if( maxAmount > 0 )
                MoneyHelper.SmoothCeilingAndFloor(ref minAmount, ref maxAmount);
            sb.AppendFormat(CultureInfo.InvariantCulture, "__currency_limit['{0}'] = {{ MinAmount:{1}, MaxAmount:{2} }};"
                , currency.SafeJavascriptStringEncode()
                , minAmount
                , maxAmount
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


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<div id="withdraw-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT"))%>
<ui:Panel runat="server" ID="pnWithdraw">


<% Html.RenderPartial("PaymentMethodDesc", this.Model); %>


<div class="withdraw_steps">
    <div id="prepare_step">
        
        <script type="text/javascript">
        <%=GetPropertiesJson() %>
        </script>

        <% using (Html.BeginRouteForm("Withdraw", new { @action = "ProcessLocalBankTransaction", @paymentMethodName = this.Model.UniqueName }, FormMethod.Post, new { @id = "formProcessLocalBankTransaction" }))
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
	        <LabelPart><%= this.GetMetadata(".GammingAccount_Label").SafeHtmlEncode()%></LabelPart>
	        <ControlPart>
                <% Html.RenderPartial("/Components/GammingAccountSelector", this.ViewData.Merge(new
                   {
                       @AutoSelect = true,
                       @TableID = "table_gamming_account",
                       @ClientOnChangeFunction = "onGammingAccountChanged",
                       @DisplayBonusAmount = Settings.Withdrawal_DisplayBonusAmount,            
                   }) ); %>
                <%: Html.Hidden("gammingAccountID", "", new { @id = "txtGammingAccountID", @validator = ClientValidators.Create().Required(this.GetMetadata(".GammingAccount_Empty")) })%>
	        </ControlPart>
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
                            <%: Html.TextBox("amount", "0.00", new { @class = "txtMoneyAmount", @id = "txtAmount", @dir = "ltr", @onchange = "onAmountChange()", @onblur = "onAmountChange()", @onfocus = "onAmountFocus()", @validator = ClientValidators.Create().Custom("validateAmount") })%>
                            <%: Html.Hidden("payCardID", "") %>
                        </td>
                    </tr>
                </table>
	        </ControlPart>
            <HintPart>
                <ul class="limit-ul">
                    <li id="tdCurrentNotes" style="display:none">
                    </li>
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
                </ul>
        
            </HintPart>
        </ui:InputField>
        <script language="javascript" type="text/javascript">
        //<![CDATA[
        // <%-- Format the input amount to comma seperated amount --%>
        function formatAmount(num) {
            num = num.toString().replace(/\$|\,/g, '');
            if (isNaN(num)) num = '0';
            sign = (num == (num = Math.abs(num)));
            num = Math.floor(num * 100 + 0.50000000001);
            cents = num % 100;
            num = Math.floor(num / 100).toString();
            if (cents < 10) cents = '0' + cents;
            for (var i = 0; i < Math.floor((num.length - (1 + i)) / 3); i++)
            num = num.substring(0, num.length - (4 * i + 3)) + ',' + num.substring(num.length - (4 * i + 3));
            return num + '.' + cents;
        }
        <%= GetLimitationScript() %>
        <%= GetCurrencyRatesScript() %>
        function onAmountChange() {
            $('#txtAmount').val(formatAmount($('#txtAmount').val()));

            showDebitAmount();
        };

        // <%-- Different currency --%>
        function showDebitAmount(){
            $('#tdCurrentNotes').hide();
            if( __account_currency == $('#ddlCurrency').val() )
                return;

            var value = $('#txtAmount').val();
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
        function onAmountFocus() {
            $('#txtAmount').val($('#txtAmount').val().replace(/\$|\,/g, '')).select();
            $('#tdCurrentNotes').hide();
        }
        var __min_limit = 0.00;
        var __max_limit = 0.00;

        var isFromLocker = false;
        function onCurrencyChange(){
            var $ddlCurrency = $('#ddlCurrency');
            if ($ddlCurrency.attr('locked') == 'locked') {
                if (isFromLocker) {
                    isFromLocker = false;
                }
                else {
                    isFromLocker = true;
                    $ddlCurrency.val($ddlCurrency.attr('lockValue')).trigger('change');
                    return;
                }
            }

            $('#fldCurrencyAmount input[name="currency"]').val( $('#ddlCurrency').val() );
            var limit = __currency_limit[$('#ddlCurrency').val()];
            if( limit != null ){
                __min_limit = limit.MinAmount;
                __max_limit = limit.MaxAmount;
                $('#tdMinLimit').css( 'display', ((__min_limit > 0.00) ? '' : 'none') );
                $('#tdMaxLimit').css( 'display', ((__max_limit > 0.00) ? '' : 'none') );
                $('#tdMinLimit .currency').text($('#ddlCurrency').val());
                $('#tdMaxLimit .currency').text($('#ddlCurrency').val());
                $('#tdMinLimit .amount').text(formatAmount(__min_limit) );
                $('#tdMaxLimit .amount').text(formatAmount(__max_limit) );
            }

            showDebitAmount();
        }

        function validateAmount(){
            // <%-- Ensure the gamming account is selected --%>
            if( InputFields.fields['fldGammingAccount'] ){
                if( !InputFields.fields['fldGammingAccount'].validator.element($('#txtGammingAccountID')) )
                    return true;
            }

            var amount = this;
            amount = parseFloat( amount.replace(/\$|\,/g, ''), 10);
            if ( isNaN(amount) || amount <= 0.00 )
                return '<%= this.GetMetadata(".CurrencyAmount_Empty").SafeJavascriptStringEncode() %>';

            if( (__min_limit > 0.00 && parseFloat(amount, 10) < __min_limit) ||
                (__max_limit > 0.00 && parseFloat(amount, 10) > __max_limit) ){
                return '<%= this.GetMetadata(".CurrencyAmount_OutsideRange").SafeJavascriptStringEncode() %>';
            }

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

            return true;
        }

        $(document).bind("ENTERCASH_BANK_CHANGED", function(e, data){
            if(data != null && data != '')
            {
                $("#ddlCurrency").attr({ 'locked': 'locked', 'lockValue': data.Currency }).val(data.Currency).trigger("change");
            }
        });
        //]]>
        </script>



        <% }// form end %>


        <script language="javascript" type="text/javascript">
            $(document).ready(function () {
                $('#ddlCurrency').removeAttr('locked');
                $('#formProcessLocalBankTransaction').initializeForm();
            });

            var g_WithdrawInputFormCallback = null;
            function tryToSubmitWithdrawInputForm(payCardID, callback) {
                $('#fldCurrencyAmount input[name="payCardID"]').val(payCardID);
                if (!$('#formProcessLocalBankTransaction').valid()) {
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
                        else {
                            window.location = json.url;
                        }

                        // <%-- trigger the WITHDRAW_TRANSACTION_PREPARED event --%>
                        //$(document).trigger('WITHDRAW_TRANSACTION_PREPARED', json.sid);
                        //showWithdrawConfirmation(json.sid);
                    },
                    error: function (xhr, textStatus, errorThrown) {
                        if (g_WithdrawInputFormCallback !== null)
                            g_WithdrawInputFormCallback();
                        showWithdrawError(errorThrown);
                    }
                };
                $('#formProcessLocalBankTransaction').ajaxForm(options);
                $('#formProcessLocalBankTransaction').submit();
                return true;
            }

            function isWithdrawInputFormValid() {
                return $('#formProcessLocalBankTransaction').valid();
            }
        </script>

        <% Html.RenderPartial(this.ViewData["PayCardView"] as string, this.Model); %>
    </div>
    <div id="confirm_step" style="display:none">
    </div>
    <div id="error_step" style="display:none">
        <center>
        <br /><br /><br />
        <%: Html.ErrorMessage("Internal Error.", false, new { id="withdraw_error" })%>
        <br /><br /><br />
        <%: Html.Button(this.GetMetadata(".Button_Back"), new { @onclick = "returnPreviousWithdrawStep(); return false;" })%>
        </center>
    </div>
</div>

</ui:Panel>
</div>


<script language="javascript" type="text/javascript">
//<![CDATA[
    var g_previousWithdrawSteps = new Array();

    function returnPreviousWithdrawStep() {
        if (g_previousWithdrawSteps.length > 0) {
            $('div.withdraw_steps > div').hide();
            g_previousWithdrawSteps.pop().show();
        }
    }

    function showWithdrawError(errorText) {
        $('#error_step div.message_Text').text(errorText);
        g_previousWithdrawSteps.push($('div.withdraw_steps > div:visible'));
        $('div.withdraw_steps > div').hide();
        $('#error_step').show();
    }

    function showWithdrawConfirmation(sid) {
        g_previousWithdrawSteps.push($('div.withdraw_steps > div:visible'));
        $('div.withdraw_steps > div').hide();
        var url = '<%= this.Url.RouteUrl("Withdraw", new { @action = "Confirmation", @paymentMethodName = this.Model.UniqueName }).SafeJavascriptStringEncode() %>?sid=' + encodeURIComponent(sid);
        $('#confirm_step').show().html('<img border="0" src="/images/icon/loading.gif" />').load(url);
    }
//]]>
</script>

<%  Html.RenderPartial("PrepareBodyPlus", this.ViewData ); %>
</asp:Content>

