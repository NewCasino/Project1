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
            sb.AppendFormat(CultureInfo.InvariantCulture, "__currency_limit['{0}'] = {{ MinAmount:{1}, MaxAmount:{2} }};"
                , currency.SafeJavascriptStringEncode()
                , minAmount
                , maxAmount
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
    if (InputFields.fields['fldGammingAccount'])
        InputFields.fields['fldGammingAccount'].validator.element($('#txtGammingAccountID'));

    //<%-- change the currency --%>
    if ($("#ddlCurrency").find("option[value='" + data.BalanceCurrency + "']").length > 0)
        $('#ddlCurrency').val(data.BalanceCurrency);
    onCurrencyChange();
    <% // disable the currency dropdownlist
    if( !this.Model.IsCurrencyChangable ) { %>
    $('#ddlCurrency').attr('disabled', true);
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
        <table cellpadding="0" cellspacing="0" border="0">
            <tr>
                <td>
                    <%: Html.DropDownList("currency2", GetCurrencyList(), new { @class = "ddlMoneyCurrency", @id="ddlCurrency", @onchange="onCurrencyChange()" })%>
                    <%-- We need another hide field for the currency 
                    because the currency value will not be included in POST request if the dropdownlist is disabled. --%>
                    <%: Html.Hidden( "currency" ) %>
                </td>
                <td>&#160;</td>
                <td>
                    <%: Html.TextBox("amount", GetAmount(), new { @class = "txtMoneyAmount", @id = "txtAmount", @dir = "ltr", @onchange = "onAmountChange()", @onblur = "onAmountChange()", @onfocus = "onAmountFocus()", @validator = ClientValidators.Create().Custom("validateAmount") })%>
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
        </ul>
        
    </HintPart>
</ui:InputField>

<%------------------------------------------
    Deposit Bonus
 -------------------------------------------%>
<div id="deposit_bonus_info"></div>

<input type="hidden" id="hPrepareTransactionIssuer" name="issuer" value="" />
<br />

<script type="text/javascript">
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
        for (var i = 0; i < Math.floor((num.length - (1 + i)) / 3) ; i++)
            num = num.substring(0, num.length - (4 * i + 3)) + ',' + num.substring(num.length - (4 * i + 3));
        return num + '.' + cents;
    }
<%= GetLimitationScript() %>
    function onAmountChange() {
        $('#txtAmount').val(formatAmount($('#txtAmount').val()));
        loadDepositBonusInfo();
    };
    function onAmountFocus() {
        $('#txtAmount').val($('#txtAmount').val().replace(/\$|\,/g, '')).select();
    }
    var __min_limit = 0.00;
    var __max_limit = 0.00;

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

        $('#fldCurrencyAmount input[name="currency"]').val($('#ddlCurrency').val());
        var limit = __currency_limit[$('#ddlCurrency').val()];
        if (limit != null) {
            __min_limit = limit.MinAmount;
            __max_limit = limit.MaxAmount;
            $('#tdMinLimit').css('display', ((__min_limit > 0.00) ? '' : 'none'));
            $('#tdMaxLimit').css('display', ((__max_limit > 0.00) ? '' : 'none'));
            $('#tdMinLimit .currency').text($('#ddlCurrency').val());
            $('#tdMaxLimit .currency').text($('#ddlCurrency').val());
            $('#tdMinLimit .amount').text(formatAmount(__min_limit));
            $('#tdMaxLimit .amount').text(formatAmount(__max_limit));
        }
        loadDepositBonusInfo();
    }

    function validateAmount() {
        // <%-- Ensure the gamming account is selected --%>
    if (InputFields.fields['fldGammingAccount']) {
        if (!InputFields.fields['fldGammingAccount'].validator.element($('#txtGammingAccountID')))
            return true;
    }

    var value = this;
    value = value.replace(/\$|\,/g, '');
    if (isNaN(value) || parseFloat(value, 10) <= 0)
        return '<%= this.GetMetadata(".CurrencyAmount_Empty").SafeJavascriptStringEncode() %>';

    if ((__min_limit > 0.00 && parseFloat(value, 10) < __min_limit) ||
        (__max_limit > 0.00 && parseFloat(value, 10) > __max_limit)) {
        return '<%= this.GetMetadata(".CurrencyAmount_OutsideRange").SafeJavascriptStringEncode() %>';
    }
    return true;
}


function loadDepositBonusInfo() {
    if ($('#txtGammingAccountID').val() == '')
        return;
    $('#deposit_bonus_info').empty();
    var url = '<%= this.Url.RouteUrl("Deposit", new { @action = "DepositBonusInfo" }).SafeJavascriptStringEncode() %>';
    url = url + '?gammingAccountID=' + $('#txtGammingAccountID').val() + '&currency=' + encodeURIComponent($('#ddlCurrency').val()) + '&amount=' + encodeURIComponent($('#txtAmount').val());
    $('#deposit_bonus_info').load(url);
}

//]]>
</script>


