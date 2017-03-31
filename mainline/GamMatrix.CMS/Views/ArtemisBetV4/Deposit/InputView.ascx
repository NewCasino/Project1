<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script language="C#" type="text/C#" runat="server">

    private decimal GetAmount()
    {
        decimal a = 0.00m;
        if (Request.Cookies["depositAmount"] != null)
        {
            decimal.TryParse(Request.Cookies["depositAmount"].Value, out a);
            Request.Cookies["depositAmount"].Expires = DateTime.Now.AddDays(-1);
            Response.AppendCookie(Request.Cookies["depositAmount"]);
        }
        return a;
    }

    private SelectList GetCurrencyList()
    {
        var allCurrencies = GamMatrixClient.GetSupportedCurrencies();
        var supportCurrencies = new List<CurrencyData>();
        foreach (CurrencyData listitem in allCurrencies)
        {
            if(this.Model.SupportedCurrencies.Type.Equals(Finance.FilteredListBase<string>.FilterType.Include))
            {
                if(this.Model.SupportedCurrencies.List != null) {
                    if (this.Model.SupportedCurrencies.List.Contains(listitem.Code))
                    {
                        supportCurrencies.Add(listitem);
                    }
                }
            }
            else
            {
                if(this.Model.SupportedCurrencies.List == null)
                {
                    supportCurrencies = allCurrencies;
                    break;
                }
                if (!this.Model.SupportedCurrencies.List.Contains(listitem.Code))
                {
                    supportCurrencies.Add(listitem);
                }
            }
        }
        var list = supportCurrencies.Select(c => new { Key = c.Code, Value = c.GetDisplayName() }).ToList();
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
                TransType = TransType.Deposit,
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
        catch(Exception ex)
        {
            Logger.Exception(ex);
        }

        StringBuilder sb = new StringBuilder();
        sb.AppendFormat(CultureInfo.InvariantCulture, "var __currency_limit = [];");

        foreach (string currency in this.Model.SupportedCurrencies.GetAll())
        {
            Range range = this.Model.GetDepositLimitation(currency);
            decimal minAmount = MoneyHelper.TransformCurrency(range.Currency
                , currency
                , range.MinAmount
                );
            decimal maxAmount = MoneyHelper.TransformCurrency(range.Currency
                , currency
                , range.MaxAmount
                );

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
                , (dailyLimit >= int.MaxValue) ? ((object)"Number.MAX_VALUE") : MoneyHelper.TransformCurrency( "EUR", currency, dailyLimit)
                , symbol
                );
        }

        return sb.ToString();
    }

    private string GetPropertiesJson()
    {
        StringBuilder sb = new StringBuilder();
        sb.Append("var paymentMethodProperties = {");
        sb.AppendFormat(@" ""uniquename"" : ""{0}"" ", this.Model.UniqueName.SafeJavascriptStringEncode());
        sb.AppendFormat(@", ""fee"": ""{0}"" ", this.Model.DepositProcessFee.GetText(this.ViewData.GetValue<string>("Currency", "EUR")).SafeJavascriptStringEncode());
        sb.AppendFormat(@", ""processing"": ""{0}"" ", this.Model.ProcessTime.GetDisplayName().SafeJavascriptStringEncode());
        sb.Append("}");
        return sb.ToString();
    }
</script>
<script type="text/javascript">
<%=GetPropertiesJson() %>
</script>
<% using (Html.BeginRouteForm("Deposit", new { @action = "PrepareTransaction", @paymentMethodName = this.Model.UniqueName }, FormMethod.Post, new { @id = "formPrepareDeposit", @onsubmit="return false;" }))
   { %>

<%------------------------------------------
    IovationBlackbox
 -------------------------------------------%>
  <%if (Settings.IovationDeviceTrack_Enabled){ %>
        <% Html.RenderPartial("/Components/IovationTrack", this.ViewData);  %>
        <%} %>
<%------------------------------------------
    Gamming Accounts
 -------------------------------------------%>
<ui:InputField ID="fldGammingAccount" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
<LabelPart><%= this.GetMetadata(".GammingAccount_Label").SafeHtmlEncode()%></LabelPart>
<ControlPart>
        <% Html.RenderPartial("/Components/GammingAccountSelector", this.ViewData.Merge(new
           {
               @TableID = "table_gamming_account",
               @ClientOnChangeFunction = "onGammingAccountChanged",
               @AutoSelect = true,
           }) ); %>
        <%: Html.Hidden("gammingAccountID", "", new { @id = "txtGammingAccountID", @validator = ClientValidators.Create().Required(this.GetMetadata(".GammingAccount_Empty")) })%>
</ControlPart>
</ui:InputField>
<script type="text/javascript">
//<![CDATA[
function onGammingAccountChanged(key, data) {
    $('#txtGammingAccountID').val(key);
    //<%-- trigger the validation --%>
    if( InputFields.fields['fldGammingAccount'] )
        InputFields.fields['fldGammingAccount'].validator.element($('#txtGammingAccountID'));
    //<%-- change the currency --%>
    if($("#ddlCurrency").find("option[value='"+ data.BalanceCurrency +"']").length > 0)
        $('#ddlCurrency').val(data.BalanceCurrency);
      onCurrencyChange();
    <% // disable the currency dropdownlist
    if( !this.Model.IsCurrencyChangable ) { %>
    $('#ddlCurrency').attr('disabled',true);
    <% } %>

    $(document).trigger('GAMING_ACCOUNT_SEL_CHANGED', data);     
    
    try {
        __updateBonusCodeField(data.VendorID);
    } catch (e) { }
}
//]]>
</script>

<%------------------------------------------
    Deposit Bonus Code
 -------------------------------------------%>
<div id="deposit_bonus_code"></div>
<% Html.RenderPartial("BonusCode", this.ViewData.Merge( new { TransType = TransType.Deposit } )); %>


<%------------------------------------------
    Currency and Amount
 -------------------------------------------%>
 <ui:InputField ID="fldCurrencyAmount" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
<LabelPart><%= this.GetMetadata(".CurrencyAmount_Label").SafeHtmlEncode()%></LabelPart>
<ControlPart>
    <div class="holder-flex-100">
                <div class="col-50">
                    <%: Html.DropDownList("currency2", GetCurrencyList(), new { @class = "ddlMoneyCurrency", @id="ddlCurrency", @onchange="onCurrencyChange()" })%>
                    <%-- 
                        We need another hide field for the currency 
                        because the currency value will not be included in POST request if the dropdownlist is disabled. 
                        --%>
                    <%: Html.Hidden( "currency" ) %>
                </div>
                <div class="col-50">
                    <%: Html.AnonymousCachedPartial("/Components/Amount", this.ViewData)%> 
                    <%: Html.Hidden("payCardID", "") %>
                </div>
    </div>
</ControlPart>
    <HintPart>
        <ul class="limit-ul">
            
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
        <div style="clear:both"></div>
    </HintPart>
</ui:InputField>

<%------------------------------------------
    Deposit Bonus
 -------------------------------------------%>
<div id="deposit_bonus_info"></div>

<input type="hidden" id="hPrepareTransactionIssuer" name="issuer" value="" />
<br />
<script type="text/javascript">
 
    
    $("document").bind("Amount_Blur", function () {
        loadDepositBonusInfo();
    });
    
    <%= GetLimitationScript() %>
    var __min_limit = 0.00;
    var __max_limit = 0.00;
    var __daily_limit = Number.MAX_VALUE;
    var __currency_symbol;

    var isFromLocker = false;
    function onCurrencyChange() {
        $("#bonusCode,#bonusVendor").val("");
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
            __daily_limit = limit.DailyLimit;
            __currency_symbol = limit.Symbol;

            $('#tdMinLimit').css( 'display', ((__min_limit > 0.00) ? '' : 'none') );
            $('#tdMaxLimit').css('display', ((__max_limit > 0.00) ? '' : 'none'));
            $('#tdDailyLimit').css('display', ((__daily_limit < Number.MAX_VALUE) ? '' : 'none'));
            $('#tdMinLimit .currency').text(__currency_symbol);//$('#ddlCurrency').val()
            $('#tdMaxLimit .currency').text(__currency_symbol);
            $('#tdDailyLimit .currency').text(__currency_symbol);
            $('#tdMinLimit .amount').text(formatAmount(__min_limit),true );
            $('#tdMaxLimit .amount').text(formatAmount(__max_limit),true);
            $('#tdDailyLimit .amount').text(formatAmount(__daily_limit),true);
        }
        loadDepositBonusInfo();
    }

    function validateAmount(){
        // <%-- Ensure the gamming account is selected --%>
        if( InputFields.fields['fldGammingAccount'] ){
            if( !InputFields.fields['fldGammingAccount'].validator.element($('#txtGammingAccountID')) )
                return true;
        }  
        var value = 0;
        if($('#txtAmount').data('fillvalue') != GetRealAmount($('#txtAmount').val()) ){ 
            value = $('#txtAmount').val();
        }
        else{
            value = $('#txtAmount').data('fillvalue');
        } 
        if(value.toString().indexOf(',') > 0 || 
            value.toString().indexOf("'") > 0 || 
            value.toString().indexOf(" ") > 0 || 
            value.toString().indexOf("-") > 0  ){ 
            value = GetRealAmount($('#txtAmount').val()); 
        } 
        var depositAmount = parseFloat(value, 10);
        if ( isNaN(value) || depositAmount <= 0 )
            return '<%= this.GetMetadata(".CurrencyAmount_Empty").SafeJavascriptStringEncode() %>';


        if( (__min_limit > 0.00 && depositAmount < __min_limit) ||
            (__max_limit > 0.00 && depositAmount > __max_limit) ){
            return '<%= this.GetMetadata(".CurrencyAmount_OutsideRange").SafeJavascriptStringEncode() %>';
        }

        if (depositAmount > __daily_limit)
            return '<%= this.GetMetadata(".CurrencyAmount_DailyLimit").SafeJavascriptStringEncode() %>';

        return true;
    }


    function loadDepositBonusInfo(){
        if( $('#txtGammingAccountID').val() == '' )
            return;
        $('#deposit_bonus_info').empty();
        var url = '<%= this.Url.RouteUrl("Deposit", new { @action = "DepositBonusInfo" }).SafeJavascriptStringEncode() %>';
        url = url + '?gammingAccountID=' + $('#txtGammingAccountID').val() + '&currency=' + encodeURIComponent($('#ddlCurrency').val()) + '&amount=' + encodeURIComponent($("input[name='amount']").val());
        $('#deposit_bonus_info').load(url);
    }

    $(document).bind("ENTERCASH_BANK_CHANGED", function(e, data){
        if(data != null && data != '')
        {
            $("#ddlCurrency").attr({ 'locked': 'locked', 'lockValue': data.Currency }).val(data.Currency).trigger("change");
        }
    });

//]]>
</script>
<% } // Form ended %>


<script type="text/javascript">
//<![CDATA[
$(function () {
    $('#ddlCurrency').removeAttr('locked');
    $('#formPrepareDeposit').initializeForm();
});

var g_DepositInputFormCallback = null;
function tryToSubmitDepositInputForm(payCardID, callback) {
    $('#fldCurrencyAmount input[name="payCardID"]').val(payCardID);
    if (!$('#formPrepareDeposit').valid()) {
        if (callback !== null) callback();
        return false;
    }    

    g_DepositInputFormCallback = callback;
    var options = {
        dataType: "json",
        type: 'POST',
        success: function (json) {
            if (g_DepositInputFormCallback !== null)
                g_DepositInputFormCallback();

            if (!json.success) {
                if (json.error === "OUTRANGE") {
                    json.error = "<%=this.GetMetadata(".CurrencyAmount_OutsideRange").SafeJavascriptStringEncode() %>";
                }
                showDepositError(json.error);
                return;
            }

            // <%-- trigger the DEPOSIT_TRANSACTION_PREPARED event --%>
            $(document).trigger('DEPOSIT_TRANSACTION_PREPARED', json.sid);
            if (json.showTC)
                showDepositTermsAndConditions(json.sid);
            else
                showDepositConfirmation(json.sid);
        },
        error: function (xhr, textStatus, errorThrown) {
            if (g_DepositInputFormCallback !== null)
                g_DepositInputFormCallback();
            showDepositError(errorThrown);
        }
    };
    $('#formPrepareDeposit').ajaxForm(options);
    $('#formPrepareDeposit').submit();
    return true;
}

function isDepositInputFormValid() {
    try {
            if (validateBonusCodeVendor() != true) {
                return false;
            }
        } catch (ex) { }

    return $('#formPrepareDeposit').valid();
}
//]]>
</script>
 