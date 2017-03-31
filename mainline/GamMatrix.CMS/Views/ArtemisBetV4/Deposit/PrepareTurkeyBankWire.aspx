<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<Finance.PaymentMethod>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>

<script language="C#" type="text/C#" runat="server">
    protected override void OnPreRender(EventArgs e)
    {
        if (Settings.IsUKLicense && !IsAcceptUKTerms())
            Response.Redirect("/Deposit");
        base.OnPreRender(e);
    }
    protected bool IsAcceptUKTerms()
    {
        UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
        cmUser user = ua.GetByID(Profile.UserID);
        return user.IsTCAcceptRequired.HasFlag(TermsConditionsChange.UKLicense);
    }
    private SelectList GetCurrencyList()
    {
        var list = GamMatrixClient.GetSupportedCurrencies()
                        .Where( c => string.Equals( c.Code, "TRY", StringComparison.InvariantCultureIgnoreCase) )
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


    private SelectList GetDayList()
    {
        Dictionary<string, string> dayList = new Dictionary<string, string>();
        dayList.Add(string.Empty, this.GetMetadata(".DOB_Day"));
        for (int i = 1; i <= 31; i++)
        {
            dayList.Add(string.Format("{0:00}", i), string.Format("{0:00}", i));
        }

        return new SelectList(dayList, "Key", "Value", string.Empty);
    }

    private SelectList GetMonthList()
    {
        Dictionary<string, string> dayList = new Dictionary<string, string>();
        dayList.Add(string.Empty, this.GetMetadata(".DOB_Month"));
        for (int i = 1; i <= 12; i++)
        {
            dayList.Add(string.Format("{0:00}", i), string.Format("{0:00}", i));
        }

        return new SelectList(dayList, "Key", "Value", string.Empty);
    }

    private SelectList GetYearList()
    {
        Dictionary<string, string> dayList = new Dictionary<string, string>();
        dayList.Add(string.Empty, this.GetMetadata(".DOB_Year"));
        for (int i = DateTime.Now.Year - 17; i > 1900; i--)
        {
            dayList.Add(i.ToString(), i.ToString());
        }

        return new SelectList(dayList, "Key", "Value", string.Empty);
    }

    private List<SelectListItem> GetBankList()
    {
        List<SelectListItem> list = new List<SelectListItem>();
        Type type = typeof(TurkeyBankWirePaymentMethod);
        Array values = Enum.GetValues(type);
        string[] table1paths = Metadata.GetChildrenPaths("/Metadata/TurkeyBankWire_Banks");
        string bankText;
        string bankValue = string.Empty;
        for (int i = 0; i < table1paths.Length; i++)
        {
            bankValue = table1paths[i].Substring(table1paths[i].LastIndexOf("/") + 1);
            if (values.ConvertToCommaSplitedString().Contains(bankValue)) {
                bankText = this.GetMetadata(string.Format("{0}.Text", table1paths[i])).DefaultIfNullOrEmpty(bankValue);
                SelectListItem item = new SelectListItem()
                {
                    Text = bankText,
                    Value = bankValue
                };
                list.Add(item);
            }
        }
        return list;
    }
</script>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div class="Breadcrumbs" role="navigation">
        <ul class="BreadMenu Container" role="menu">
            <li class="BreadItem" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
                <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Title") %>">
                    <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Name") %></span>
                </a>
            </li>
            <li class="BreadItem" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
                <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/DepositPage/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/ResponsibleGaming/.Title") %>">
                    <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/DepositPage/.Name") %></span>
                </a>
            </li>
            <li class="BreadItem BreadCurrent" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
                <a class="BreadLink url" href="javascript:;" itemprop="url" title="<%= this.Model.GetTitleHtml().HtmlEncodeSpecialCharactors() %>">
                    <span itemprop="title"><%= this.Model.GetTitleHtml().HtmlEncodeSpecialCharactors() %></span>
                </a>
            </li>
        </ul>
    </div>
<div id="deposit-wrapper" class="content-wrapper BreadMenu">
<%: Html.H1( string.Format( "{0} - {1}", this.GetMetadata(".HEAD_TEXT"), this.Model.GetTitleHtml()) ) %>
<ui:Panel runat="server" ID="pnDeposit">

 
<% Html.RenderPartial("PaymentMethodDesc", this.Model); %>

<% using (Html.BeginRouteForm("Deposit", new
   {
       @action = "ProcessTurkeyBankWireTransaction"
       , @paymentMethodName = this.Model.UniqueName }
       , FormMethod.Post
       , new { @id = "formProcessTurkeyBankWireDeposit", @target = "_self" }
       ))
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
        <table cellpadding="0" cellspacing="0" border="0" class="holder-flex-100">
            <tr class="holder-flex-100">
                <td class="col-50">
                    <%: Html.DropDownList("currency2", GetCurrencyList(), new { @class = "ddlMoneyCurrency", @id="ddlCurrency", @onchange="onCurrencyChange()" })%>
                    <%-- We need another hide field for the currency 
                    because the currency value will not be included in POST request if the dropdownlist is disabled. --%>
                    <%: Html.Hidden( "currency" ) %>
                </td>
                <td class="col-50">
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




<%------------------------------------------
    FullName
-------------------------------------------%>
 <ui:InputField ID="fldFullName" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
<LabelPart><%= this.GetMetadata(".FullName_Label").SafeHtmlEncode()%></LabelPart>
<ControlPart>
        <%: Html.TextBox("fullname", Profile.DisplayName, new 
        { 
            @maxlength = 50,
            @dir = "ltr",
            @validator = ClientValidators.Create()
                .Required(this.GetMetadata(".FullName_Empty"))
        } 
        )%>
</ControlPart>
</ui:InputField>

<%------------------------------------------
    Citizen ID
-------------------------------------------%>
 <ui:InputField ID="fldCitizenID" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
<LabelPart><%= this.GetMetadata(".CitizenID_Label").SafeHtmlEncode()%></LabelPart>
<ControlPart>
        <%: Html.TextBox("citizenID", "", new 
        {
            @maxlength = 50,
            @dir = "ltr",
            @validator = ClientValidators.Create()
                .Required(this.GetMetadata(".CitizenID_Empty"))
        } 
        )%>
</ControlPart>
</ui:InputField>


<%------------------------------------------
    Bank
-------------------------------------------%>
 <ui:InputField ID="fldBank" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
<LabelPart><%= this.GetMetadata(".Bank_Label").SafeHtmlEncode()%></LabelPart>
<ControlPart>
        <%: Html.DropDownList("paymentMethod", GetBankList())%>
</ControlPart>
</ui:InputField>


<%------------------------------------------
    Transaction ID
-------------------------------------------%>
 <ui:InputField ID="fldTransactionID" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
<LabelPart><%= this.GetMetadata(".TransactionID_Label").SafeHtmlEncode()%></LabelPart>
<ControlPart>
        <%: Html.TextBox("transactionID", "", new 
        {
            @maxlength = 50,
            @dir = "ltr",
        } 
        )%>
</ControlPart>
</ui:InputField>


<center>
    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @type = "submit", @id = "btnTurkeyBankWireContinue", @class="ContinueButton button" })%>
</center>


<% } // form end%>



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
            <td class="name"><%= this.GetMetadata(".FullName_Label").SafeHtmlEncode()%></td>
            <td class="value" id="tdFullName"></td>
        </tr>
        <tr>
            <td class="name"><%= this.GetMetadata(".CitizenID_Label").SafeHtmlEncode()%></td>
            <td class="value" id="tdCitizenID"></td>
        </tr>
        <tr>
            <td class="name"><%= this.GetMetadata(".Bank_Label").SafeHtmlEncode()%></td>
            <td class="value" id="tdBank"></td>
        </tr>
    </table>
    <br /><br />
    <center>
        <%: Html.Button(this.GetMetadata(".Button_Back"), new { @type = "button", @id = "btnTurkeyBankWireBack", @class="BackButton button" })%>
        <%: Html.Button(this.GetMetadata(".Button_Confirm"), new { @type = "button", @id = "btnTurkeyBankWireDeposit", @class="ConfirmButton button" })%>
    </center>

</div>

<div id="success_step" style="display:none">
    <%: Html.InformationMessage( this.GetMetadata(".Success_Message") ) %>
</div>

<div id="error_step" style="display:none">
    <%: Html.ErrorMessage("", false, new { @id = "msgTurkeyBankWireError" })%>
    <br />
    <center>
        <%: Html.Button(this.GetMetadata(".Button_Back"), new { @type = "button", @id = "btnTurkeyBankWireErrorBack", @class="BackButton button" })%>
    </center>

</div>

</ui:Panel>
</div>



<script type="text/javascript">
    $(function () {
        $('#formProcessTurkeyBankWireDeposit').initializeForm();

        $('#btnTurkeyBankWireContinue').click(function (e) {
            e.preventDefault();

            if (!$('#formProcessTurkeyBankWireDeposit').valid())
                return;

            $('#formProcessTurkeyBankWireDeposit').hide();
            $('#confirm_step').show();
            var key = $('#table_gamming_account').getSelectableTableValueField();
            $('#tdCreditAccount').text($('#table_gamming_account').getSelectableTableData()[key].DisplayName);
            $('#tdCreditAmount').text($('#fldCurrencyAmount select').val() + ' ' + $('#fldCurrencyAmount input[name="amount"]').val());
            $('#tdFullName').text($('#fldFullName input[name="fullname"]').val());
            $('#tdCitizenID').text($('#fldCitizenID input[name="citizenID"]').val());
            $('#tdBank').text($('#fldBank select > option:selected').text());
        });

        $('#btnTurkeyBankWireBack').click(function (e) {
            e.preventDefault();
            $('#formProcessTurkeyBankWireDeposit').show();
            $('#confirm_step').hide();
        });


        $('#btnTurkeyBankWireDeposit').click(function (e) {
            e.preventDefault();
            if (!$('#formProcessTurkeyBankWireDeposit').valid())
                return;

            $(this).toggleLoadingSpin(true);

            var options = {
                dataType: "json",
                type: 'POST',
                success: function (json) {
                    $('#confirm_step').hide();
                    $('#btnTurkeyBankWireDeposit').toggleLoadingSpin(false);
                    if (!json.success) {
                        $('#error_step').show();
                        $('#msgTurkeyBankWireError div.message_Text').text(json.error);
                        return;
                    }
                    $('#success_step').show();
                },
                error: function (xhr, textStatus, errorThrown) {
                    $('#btnTurkeyBankWireDeposit').toggleLoadingSpin(false);
                }
            };
            $('#formProcessTurkeyBankWireDeposit').ajaxForm(options);
            $('#formProcessTurkeyBankWireDeposit').submit();
        });


        $('#btnTurkeyBankWireErrorBack').click(function (e) {
            e.preventDefault();
            $('#success_step').hide();
            $('#error_step').hide();
            $('#confirm_step').hide();
            $('#formProcessTurkeyBankWireDeposit').show();
        });


    });
</script>
<% Html.RenderAction("LimitSetPopup", "Deposit"); %>
<%  Html.RenderPartial("PrepareBodyPlus", this.ViewData ); %>
</asp:Content>

