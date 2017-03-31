<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<Finance.PaymentMethod>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>

<script language="C#" type="text/C#" runat="server">
    private SelectList GetCurrencyList()
    {
        List<SelectListItem> list = GamMatrixClient.GetSupportedCurrencies()
            .FilterForCurrentDomain()
            .Select(c => new SelectListItem { Text = c.GetDisplayName(), Value = c.ISO4217_Alpha })
            .ToList();

        SelectListItem item = list.FirstOrDefault(i => string.Equals(i.Value, Profile.AsCustomProfile().UserCurrency));
        if (item != null)
        {
            item.Selected = true;
        }
        else
        {
            list[0].Selected = true;
        }
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
    protected bool IsAcceptUKTerms()
    {
        UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
        cmUser user = ua.GetByID(Profile.UserID);
        return user.IsTCAcceptRequired.HasFlag(TermsConditionsChange.UKLicense);
    }
    protected override void OnPreRender(EventArgs e)
    {
        if (Settings.IsUKLicense && !IsAcceptUKTerms())
            Response.Redirect("/Deposit");
        string title = this.GetMetadata(".Title");
        if (title != null)
            this.Title = title.Replace("$PAYMENTMETHOD$", this.Model.GetTitleHtml());

        string desc = this.GetMetadata(".Description");
        if (desc != null)
            this.MetaDescription = desc.Replace("$PAYMENTMETHOD$", this.Model.GetTitleHtml());


        string keywords = this.GetMetadata(".Keywords");
        if (keywords != null)
            this.MetaDescription = keywords.Replace("$PAYMENTMETHOD$", this.Model.GetTitleHtml());
        base.OnPreRender(e);
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<div id="deposit-wrapper" class="content-wrapper">
<ui:Header ID="Header1" runat="server" HeadLevel="h1">
    <%= this.GetMetadata(".HEAD_TEXT").SafeHtmlEncode() %>
    -
    <%= this.Model.GetTitleHtml().HtmlEncodeSpecialCharactors() %>
</ui:Header>

<ui:Panel runat="server" ID="pnDeposit">
<% Html.RenderPartial("PaymentMethodDesc", this.Model); %>

<div class="deposit_steps">
<div id="prepare_step">
<% using (Html.BeginRouteForm("Deposit"
       , new{ @action = "ProcessLocalBankTransaction", @paymentMethodName = this.Model.UniqueName}
       , FormMethod.Post
       , new { @id = "formProcessLocalBankTransaction", @target = "_self" }
       ))
   { %>

    <%------------------------------------------
    IovationBlackbox
 -------------------------------------------%>
  <%if (Settings.IovationDeviceTrack_Enabled){ %>
        <% Html.RenderPartial("/Components/IovationTrack", this.ViewData);  %>
        <%} %>
<%: Html.Hidden("payCardID", "", new 
                    { 
                        @id = "hPayCardID",
                    }) %>
   
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
    $('#ddlCurrency').val(data.BalanceCurrency);
    onCurrencyChange();
    <% // disable the currency dropdownlist
    if( !this.Model.IsCurrencyChangable ) { %>
    $('#ddlCurrency').attr('disabled',true);
    <% } %>
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
                    <%: Html.DropDownList("currency2", GetCurrencyList(), new { @class = "ddlMoneyCurrency", @id="ddlCurrency", @onchange="onCurrencyChange()" })%>
                    <%-- We need another hide field for the currency 
                    because the currency value will not be included in POST request if the dropdownlist is disabled. --%>
                    <%: Html.Hidden( "currency" ) %>
                </td>
                <td>&#160;</td>
                <td>
                    <%: Html.TextBox("amount", "0.00", new { @class = "txtMoneyAmount", @id = "txtAmount", @dir = "ltr", @onchange = "onAmountChange()", @onblur = "onAmountChange()", @onfocus = "onAmountFocus()", @validator = ClientValidators.Create().Custom("validateAmount") })%>
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
    for (var i = 0; i < Math.floor((num.length - (1 + i)) / 3); i++)
    num = num.substring(0, num.length - (4 * i + 3)) + ',' + num.substring(num.length - (4 * i + 3));
    return num + '.' + cents;
}
<%= GetLimitationScript() %>
function onAmountChange() {
    $('#txtAmount').val(formatAmount($('#txtAmount').val()));
};
function onAmountFocus() {
    $('#txtAmount').val($('#txtAmount').val().replace(/\$|\,/g, '')).select();
}
var __min_limit = 0.00;
var __max_limit = 0.00;
function onCurrencyChange(){
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
}

function validateAmount(){
    // <%-- Ensure the gamming account is selected --%>
    if( InputFields.fields['fldGammingAccount'] ){
        if( !InputFields.fields['fldGammingAccount'].validator.element($('#txtGammingAccountID')) )
            return true;
    }

    var value = this;
    value = value.replace(/\$|\,/g, '');
    if ( isNaN(value) || parseFloat(value, 10) <= 0 )
        return '<%= this.GetMetadata(".CurrencyAmount_Empty").SafeJavascriptStringEncode() %>';

    if( (__min_limit > 0.00 && parseFloat(value, 10) < __min_limit) ||
        (__max_limit > 0.00 && parseFloat(value, 10) > __max_limit) ){
        return '<%= this.GetMetadata(".CurrencyAmount_OutsideRange").SafeJavascriptStringEncode() %>';
    }
    return true;
}

//]]>
</script>
<% } %>

<% Html.RenderPartial(this.ViewData["PayCardView"] as string, this.Model); %>

</div>


<div id="confirm_step" style="display:none">
    <%------------------------
        The confirmation table
    ------------------------%>
    <table cellpadding="0" cellspacing="0" border="1" rules="all" class="confirmation_table">
        <tr>
            <td class="name"><%= this.GetMetadata(".CreditAccount_Label").SafeHtmlEncode()%></td>
            <td class="value" id="tdCreditAccount"></td>
        </tr>
        <tr>
            <td class="name"><%= this.GetMetadata(".CreditAmount_Label").SafeHtmlEncode()%></td>
            <td class="value" id="tdCreditAmount"></td>
        </tr>
        <tr>
            <td class="name"><%= this.GetMetadata(".Bank_Label").SafeHtmlEncode()%></td>
            <td class="value" id="tdBank"></td>
        </tr>
    </table>
    <br /><br />
    <center>
        <%: Html.Button(this.GetMetadata(".Button_Back"), new { @type = "button", @id = "btnLocalBankBack", @onclick = "returnPreviousDepositStep(); return false;", @class="BackButton button" })%>
        <%: Html.Button(this.GetMetadata(".Button_Confirm"), new { @type = "button", @id = "btnLocalBankDeposit", @class="ConfirmButton button" })%>
    </center>
</div>

<div id="success_step" style="display:none">
    <%: Html.InformationMessage( this.GetMetadata(".Success_Message") ) %>
</div>

<div id="error_step" style="display:none">
    <%: Html.ErrorMessage("", false, new { @id = "msgLocalBankError" })%>
    <br />
    <center>
        <%: Html.Button(this.GetMetadata(".Button_Back"), new { @type = "button", @id = "btnLocalBankErrorBack", @onclick = "returnPreviousDepositStep(); return false;", @class="BackButton button" })%>
    </center>

</div>

</div>

</ui:Panel>

</div>

<script type="text/javascript">
    function isDepositInputFormValid() {
        return $('#formProcessLocalBankTransaction').valid();
    }

    var g_previousDepositSteps = new Array();


    function returnPreviousDepositStep() {
        if (g_previousDepositSteps.length > 0) {
            $('div.deposit_steps > div').hide();
            g_previousDepositSteps.pop().show();
        }
    }

    function showDepositError(errorText) {
        $('#error_step div.message_Text').text(errorText);
        g_previousDepositSteps.push($('div.deposit_steps > div:visible'));
        $('div.deposit_steps > div').hide();
        $('#error_step').show();
    }

    var g_DepositInputFormCallback = null;
    function tryToContinueConfirmStep(payCardID, bankName, displayNumber, callback) {
        $('#fldCurrencyAmount input[name="payCardID"]').val(payCardID);
        if (!$('#formProcessLocalBankTransaction').valid()) {
            if (callback !== null) callback();
            return false;
        }

        $('#hPayCardID').val(payCardID);

        g_previousDepositSteps.push($('div.deposit_steps > div:visible'));

        $('#prepare_step').hide();
        $('#confirm_step').show();

        var key = $('#table_gamming_account').getSelectableTableValueField();
        $('#tdCreditAccount').text($('#table_gamming_account').getSelectableTableData()[key].DisplayName);
        $('#tdCreditAccount').text($('#table_gamming_account').getSelectableTableData()[key].DisplayName);
        $('#tdCreditAmount').text($('#fldCurrencyAmount select').val() + ' ' + $('#fldCurrencyAmount input[name="amount"]').val());
        $('#tdBank').text('{0} - {1}'.format(bankName, displayNumber));

        if (callback !== null) callback();       
    }

    $(function () {
        $('#formProcessLocalBankTransaction').initializeForm();

        $('#btnLocalBankDeposit').click(function (e) {
            e.preventDefault();

            if (!$('#formProcessLocalBankTransaction').valid())
                return;
            $this = $(this);
            $(this).toggleLoadingSpin(true);

            var options = {
                dataType: "json",
                type: 'POST',
                success: function (json) {
                    $('#confirm_step').hide();
                    $('#btnLocalBankDeposit').toggleLoadingSpin(false);

                    if (!json.success) {
                        $('#error_step').show();
                        $('#msgTurkeyBankWireError div.message_Text').text(json.error);
                        return;
                    }

                    $('#success_step').show();
                },
                error: function (xhr, textStatus, errorThrown) {
                    $('#btnLocalBankDeposit').toggleLoadingSpin(false);
                }
            };
            $('#formProcessLocalBankTransaction').ajaxForm(options);
            $('#formProcessLocalBankTransaction').submit();
        });
    });
</script>
<% Html.RenderAction("LimitSetPopup", "Deposit"); %>
<%  Html.RenderPartial("PrepareBodyPlus", this.ViewData ); %>
</asp:Content>

