<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<Finance.PaymentMethod>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>

<script language="C#" type="text/C#" runat="server">
    public bool ShowSenderPhoneNumber { get; set; }
    public bool ShowReceiverPhoneNumber { get; set; }
    public bool ShowReceiverBirthDate { get; set; }
    public bool ShowPassword { get; set; }
    public bool ShowReferenceNumber { get; set; }
    public bool ShowSenderTCNumber { get; set; }
    public bool ShowReceiverTCNumber { get; set; }

    private string MetadataPostfix { get; set; }

    protected bool IsAcceptUKTerms()
    {
        UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
        cmUser user = ua.GetByID(Profile.UserID);
        return user.IsTCAcceptRequired.HasFlag(TermsConditionsChange.UKLicense);
    }
    protected override void OnInit(EventArgs e)
    {
        if (Settings.IsUKLicense && !IsAcceptUKTerms())
            Response.Redirect("/Deposit");
        switch (this.Model.UniqueName)
        {
            case "ArtemisSMS_Garanti":
            case "TurkeySMS_Garanti":
                {
                    ShowSenderPhoneNumber = true;
                    ShowReceiverPhoneNumber = true;
                    ShowReceiverBirthDate = false;
                    ShowPassword = true;
                    ShowReferenceNumber = false;
                    ShowSenderTCNumber = false;
                    ShowReceiverTCNumber = false;
                    break;
                }

            case "ArtemisSMS_Akbank":
            case "TurkeySMS_Akbank":
                {
                    ShowSenderPhoneNumber = true;
                    ShowReceiverPhoneNumber = true;
                    ShowReceiverBirthDate = false;
                    ShowPassword = false;
                    ShowReferenceNumber = true;
                    ShowSenderTCNumber = true;
                    ShowReceiverTCNumber = false;
                    break;
                }

            case "ArtemisSMS_Isbank":
            case "TurkeySMS_Isbank":
                {
                    ShowSenderPhoneNumber = true;
                    ShowReceiverPhoneNumber = false;
                    ShowReceiverBirthDate = true;
                    ShowPassword = false;
                    ShowReferenceNumber = true;
                    ShowSenderTCNumber = false;
                    ShowReceiverTCNumber = true;
                    break;
                }

            case "ArtemisSMS_YapiKredi":
                {
                    ShowSenderPhoneNumber = false;
                    ShowReceiverPhoneNumber = true;
                    ShowReceiverBirthDate = false;
                    ShowPassword = true;
                    ShowReferenceNumber = false;
                    ShowSenderTCNumber = false;
                    ShowReceiverTCNumber = true;

                    MetadataPostfix = "_YapiKredi";
                    break;
                }
        }
        base.OnInit(e);
    }

    private SelectList GetCurrencyList()
    {
        var list = GamMatrixClient.GetSupportedCurrencies()
                        .Where(c => string.Equals(c.Code, "TRY", StringComparison.InvariantCultureIgnoreCase))
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

    private string GetMetadataWithPostfix(string path)
    {
        return this.GetMetadata(path + MetadataPostfix).DefaultIfNullOrEmpty(this.GetMetadata(path));
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
<div class="content-wrapper">
<%: Html.H1( string.Format( "{0} - {1}", this.GetMetadata(".HEAD_TEXT"), this.Model.GetTitleHtml()) ) %>
<ui:Panel runat="server" ID="tabbedPayCards">


<% Html.RenderPartial("PaymentMethodDesc", this.Model); %>

<% using (Html.BeginRouteForm("Deposit", new { @action = "ProcessArtemisSMSTransaction"
       , @paymentMethodName = this.Model.UniqueName }
       , FormMethod.Post
       , new { @id = "formProcessArtemisSMSDeposit", @target = "_self" }
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
        <table cellpadding="0" cellspacing="0" border="0" class="inputfield_Table" >
            <tr>
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
    Sender's phone number
-------------------------------------------%>
<% 
 if (this.ShowSenderPhoneNumber)
 { %>
 <ui:InputField ID="fldSenderPhoneNumber" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
<LabelPart><%= this.GetMetadata(".SenderPhoneNumber_Label").SafeHtmlEncode()%></LabelPart>
<ControlPart>
        <%: Html.TextBox("senderPhoneNumber", "", new 
        { 
            @maxlength = 20,
            @dir = "ltr",
            @validator = ClientValidators.Create()
                .Required(this.GetMetadata(".SenderPhoneNumber_Empty"))
                .Custom("validateSenderPhoneNumber")
        } 
        )%>
</ControlPart>
</ui:InputField>
<script type="text/javascript">
//<![CDATA[
    $(function () {
        $('#fldSenderPhoneNumber input[name="senderPhoneNumber"]').allowNumberOnly();
    });
    function validateSenderPhoneNumber() {
        var value = this;
        var ret = /^(\d{3,20})$/.exec(value);
        if (ret == null || ret.length == 0)
            return '<%= this.GetMetadata(".SenderPhoneNumber_Invalid").SafeJavascriptStringEncode() %>';
        return true;
    }
//]]>
</script>
<% } %>


<%------------------------------------------
    Receiver's phone number
-------------------------------------------%>
<% 
 if (this.ShowReceiverPhoneNumber)
 { %>
 <ui:InputField ID="fldReceiverPhoneNumber" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
<LabelPart><%= this.GetMetadataWithPostfix(".ReceiverPhoneNumber_Label").SafeHtmlEncode()%></LabelPart>
<ControlPart>
        <%: Html.TextBox("receiverPhoneNumber", "", new 
        { 
            @maxlength = 20,
            @dir = "ltr",
            @validator = ClientValidators.Create()
                .Required(this.GetMetadataWithPostfix(".ReceiverPhoneNumber_Empty"))
                .Custom("validateReceiverPhoneNumber")
        } 
        )%>
</ControlPart>
</ui:InputField>
<script type="text/javascript">
//<![CDATA[
    $(function () {
        $('#fldReceiverPhoneNumber input[name="receiverPhoneNumber"]').allowNumberOnly();
    });
    function validateReceiverPhoneNumber() {
        var value = this;
        var ret = /^(\d{3,20})$/.exec(value);
        if (ret == null || ret.length == 0)
            return '<%= this.GetMetadataWithPostfix(".ReceiverPhoneNumber_Invalid").SafeJavascriptStringEncode() %>';
        return true;
    }
//]]>
</script>
<% } %>


<%------------------------------------------
    Receiver's Birth Date
-------------------------------------------%>
<% 
 if (this.ShowReceiverBirthDate)
 { %>
 <ui:InputField ID="fldReceiverBirthDate" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
<LabelPart><%= this.GetMetadata(".ReceiverBirthDate_Label").SafeHtmlEncode()%></LabelPart>
<ControlPart>
        <%: Html.DropDownList( "ddlDay", GetDayList()) %>
        <%: Html.DropDownList( "ddlMonth", GetMonthList())%>
        <%: Html.DropDownList("ddlYear", GetYearList(), new { @validator = ClientValidators.Create().Required(this.GetMetadata(".DOB_Empty")).Custom("validateBirthday") })%>
        <%: Html.TextBox("receiverBirthDate", string.Empty, new 
            { 
                @id = "txtBirthday",
                @style = "display:none",
            } ) %>
</ControlPart>
</ui:InputField>
<script type="text/javascript">
//<![CDATA[
function validateBirthday() {
    if( $('#ddlDay').val() == '' || $('#ddlMonth').val() == '' || $('#ddlYear').val() == '' )
        return '<%= this.GetMetadata(".ReceiverBirthDate_Empty").SafeJavascriptStringEncode() %>';

    $('#txtBirthday').val( $('#ddlDay').val() + '/' + $('#ddlMonth').val() + '/' + $('#ddlYear').val() );

    return true;
}

$(function () {
    var fun = function () {
        if ($('#ddlYear').val().length > 0 &&
            $('#ddlMonth').val().length > 0 &&
            $('#ddlDay').val().length > 0) {
            <%-- trigger the validation --%>
            InputFields.fields['fldReceiverBirthDate'].validator.element($('#txtBirthday'));
        }
    };
    $('#ddlDay').change(fun);
    $('#ddlMonth').change(fun);
    $('#ddlYear').change(fun);
}
);

//]]>
</script>
<% } %>

<%------------------------------------------
    Password
-------------------------------------------%>
<% 
 if (this.ShowPassword)
 { %>
 <ui:InputField ID="fldPassword" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
<LabelPart><%= this.GetMetadataWithPostfix(".Password_Label").SafeHtmlEncode()%></LabelPart>
<ControlPart>
        <%: Html.TextBox("password", "", new 
        { 
            @maxlength = 20,
            @dir = "ltr",
            @validator = ClientValidators.Create()
                .Required(this.GetMetadataWithPostfix(".Password_Empty"))
        } 
        )%>
</ControlPart>
</ui:InputField>
<% } %>



<%------------------------------------------
    Reference number
-------------------------------------------%>
<% 
 if (this.ShowReferenceNumber)
 { %>
 <ui:InputField ID="fldReferenceNumber" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
<LabelPart><%= this.GetMetadata(".ReferenceNumber_Label").SafeHtmlEncode()%></LabelPart>
<ControlPart>
        <%: Html.TextBox("referenceNumber", "", new 
        { 
            @maxlength = 20,
            @dir = "ltr",
            @validator = ClientValidators.Create()
                .Required(this.GetMetadata(".ReferenceNumber_Empty"))
        } 
        )%>
</ControlPart>
</ui:InputField>
<% } %>


<%------------------------------------------
    Sender's TC number
-------------------------------------------%>
<% 
 if (this.ShowSenderTCNumber)
 { %>
 <ui:InputField ID="fldSenderTCNumber" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
<LabelPart><%= this.GetMetadata(".SenderTCNumber_Label").SafeHtmlEncode()%></LabelPart>
<ControlPart>
        <%: Html.TextBox("senderTCNumber", "", new 
        { 
            @maxlength = 20,
            @dir = "ltr",
            @validator = ClientValidators.Create()
                .Required(this.GetMetadata(".SenderTCNumber_Empty"))
        } 
        )%>
</ControlPart>
</ui:InputField>
<% } %>



<%------------------------------------------
    Receiver's TC number
-------------------------------------------%>
<% 
 if (this.ShowReceiverTCNumber)
 { %>
 <ui:InputField ID="fldReceiverTCNumber" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
<LabelPart><%= this.GetMetadataWithPostfix(".ReceiverTCNumber_Label").SafeHtmlEncode()%></LabelPart>
<ControlPart>
        <%: Html.TextBox("receiverTCNumber", "", new 
        { 
            @maxlength = 20,
            @dir = "ltr",
            @validator = ClientValidators.Create()
                .Required(this.GetMetadataWithPostfix(".ReceiverTCNumber_Empty"))
        } 
        )%>
</ControlPart>
</ui:InputField>
<% } %>

<%------------------------------------------
    Bonus
 -------------------------------------------%>
<ui:InputField ID="fldBonus" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
<LabelPart></LabelPart>
<ControlPart><div class="hidden">
        <%: Html.CheckBox( "acceptBonus", true, new { @id = "btnAcceptBonus" }) %>
        <label for="btnAcceptBonus"><%= this.GetMetadata(".Bonus_Option").SafeHtmlEncode()%></label></div>
</ControlPart>
</ui:InputField>

<center>
    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @type = "submit", @id = "btnArtemisSMSContinue", @class="ContinueButton button" })%>
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
        <% if (this.ShowSenderPhoneNumber)
           { %>
        <tr>
            <td class="name"><%= this.GetMetadata(".SenderPhoneNumber_Label").SafeHtmlEncode()%></td>
            <td class="value" id="tdSenderPhoneNumber"></td>
        </tr>
        <% } %>

        <% if (this.ShowReceiverPhoneNumber)
           { %>
        <tr>
            <td class="name"><%= this.GetMetadataWithPostfix(".ReceiverPhoneNumber_Label").SafeHtmlEncode()%></td>
            <td class="value" id="tdReceiverPhoneNumber"></td>
        </tr>
        <% } %>

        <% if (this.ShowReceiverBirthDate)
           { %>
        <tr>
            <td class="name"><%= this.GetMetadata(".ReceiverBirthDate_Label").SafeHtmlEncode()%></td>
            <td class="value" id="tdReceiverBirthDate"></td>
        </tr>
        <% } %>

        <% if (this.ShowPassword)
           { %>
        <tr>
            <td class="name"><%= this.GetMetadataWithPostfix(".Password_Label").SafeHtmlEncode()%></td>
            <td class="value" id="tdPassword"></td>
        </tr>
        <% } %>

        <% if (this.ShowReferenceNumber)
           { %>
        <tr>
            <td class="name"><%= this.GetMetadata(".ReferenceNumber_Label").SafeHtmlEncode()%></td>
            <td class="value" id="tdReferenceNumber"></td>
        </tr>
        <% } %>

        <% if (this.ShowSenderTCNumber)
           { %>
        <tr>
            <td class="name"><%= this.GetMetadata(".SenderTCNumber_Label").SafeHtmlEncode()%></td>
            <td class="value" id="tdSenderTCNumber"></td>
        </tr>
        <% } %>

        <% if (this.ShowReceiverTCNumber)
           { %>
        <tr>
            <td class="name"><%= this.GetMetadataWithPostfix(".ReceiverTCNumber_Label").SafeHtmlEncode()%></td>
            <td class="value" id="tdReceiverTCNumber"></td>
        </tr>
        <% } %>
    </table>
    <br /><br />
    <center>
        <%: Html.Button(this.GetMetadata(".Button_Back"), new { @type = "button", @id = "btnArtemisSMSBack", @class="BackButton button" })%>
        <%: Html.Button(this.GetMetadata(".Button_Confirm"), new { @type = "button", @id = "btnArtemisSMSDeposit", @class="ConfirmButton button" })%>
    </center>

</div>

<div id="success_step" style="display:none">
    <%: Html.InformationMessage( this.GetMetadata(".Success_Message") ) %>
</div>

<div id="error_step" style="display:none">
    <%: Html.ErrorMessage("", false, new { @id = "msgArtemisSMSError" })%>
    <br />
    <center>
        <%: Html.Button(this.GetMetadata(".Button_Back"), new { @type = "button", @id = "btnArtemisSMSErrorBack", @class="BackButton button" })%>
    </center>

</div>

</ui:Panel>
</div>

<%  Html.RenderPartial("LocalConnection", this.ViewData); %>


<script type="text/javascript">
    $(function () {
        $('#formProcessArtemisSMSDeposit').initializeForm();

        $('#btnArtemisSMSContinue').click(function (e) {
            e.preventDefault();

            if (!$('#formProcessArtemisSMSDeposit').valid())
                return;

            $('#formProcessArtemisSMSDeposit').hide();
            $('#confirm_step').show();
            var key = $('#table_gamming_account').getSelectableTableValueField();
            $('#tdCreditAccount').text($('#table_gamming_account').getSelectableTableData()[key].DisplayName);
            $('#tdCreditAmount').text($('#fldCurrencyAmount select').val() + ' ' + $('#fldCurrencyAmount input[name="amount"]').val());
            $('#tdSenderPhoneNumber').text($('#fldSenderPhoneNumber input[name="senderPhoneNumber"]').val());
            $('#tdReceiverPhoneNumber').text($('#fldReceiverPhoneNumber input[name="receiverPhoneNumber"]').val());
            $('#tdReceiverBirthDate').text($('#fldReceiverBirthDate input[name="receiverBirthDate"]').val());
            $('#tdPassword').text($('#fldPassword input[name="password"]').val());
            $('#tdReferenceNumber').text($('#fldReferenceNumber input[name="referenceNumber"]').val());
            $('#tdSenderTCNumber').text($('#fldSenderTCNumber input[name="senderTCNumber"]').val());
            $('#tdReceiverTCNumber').text($('#fldReceiverTCNumber input[name="receiverTCNumber"]').val());
        });

        $('#btnArtemisSMSBack').click(function (e) {
            e.preventDefault();
            $('#formProcessArtemisSMSDeposit').show();
            $('#confirm_step').hide();
        });


        $('#btnArtemisSMSDeposit').click(function (e) {
            e.preventDefault();
            if (!$('#formProcessArtemisSMSDeposit').valid())
                return;

            $(this).toggleLoadingSpin(true);

            var options = {
                dataType: "json",
                type: 'POST',
                success: function (json) {
                    $('#confirm_step').hide();
                    $('#btnArtemisSMSDeposit').toggleLoadingSpin(false);
                    if (!json.success) {
                        $('#error_step').show();
                        $('#msgArtemisSMSError div.message_Text').text(json.error);
                        return;
                    }
                    $('#success_step').show();
                },
                error: function (xhr, textStatus, errorThrown) {
                    $('#btnArtemisSMSDeposit').toggleLoadingSpin(false);
                }
            };
            $('#formProcessArtemisSMSDeposit').ajaxForm(options);
            $('#formProcessArtemisSMSDeposit').submit();
        });


        $('#btnArtemisSMSErrorBack').click(function (e) {
            e.preventDefault();
            $('#success_step').hide();
            $('#error_step').hide();
            $('#confirm_step').hide();
            $('#formProcessArtemisSMSDeposit').show();
        });


    });
</script>
<% Html.RenderAction("LimitSetPopup", "Deposit"); %>
</asp:Content>


