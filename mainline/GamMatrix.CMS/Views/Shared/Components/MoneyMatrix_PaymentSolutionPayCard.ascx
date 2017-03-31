<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.Common.Components.MoneyMatrixPaymentSolutionPrepareViewModel>" %>

<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrix.CMS.Models.Common.Components" %>

<script runat="server">
    private const string DummyKey = "IsDummy";

    public const string PaymentParameterFieldKey = "PaymentParameter";

    private List<PayCardInfoRec> _payCards;

    private List<PayCardInfoRec> PayCards
    {
        get
        {
            if (_payCards != null)
            {
                return _payCards;
            }

            if (Model.RelatedMoneyMatrixPaymentSolutionNames != null)
            {
                _payCards = GamMatrixClient.GetMoneyMatrixPayCardsByPaymentSolutionNamesOrDummy(Model.RelatedMoneyMatrixPaymentSolutionNames).ToList();
            }
            else
            {
                _payCards = GamMatrixClient.GetMoneyMatrixPayCardsByPaymentSolutionNameOrDummy(Model.MoneyMatrixPaymentSolutionName).ToList();
            }

            if (!_payCards.Any())
            {
                throw new InvalidOperationException("This payment method is not configured in GmCore.");
            }

            return _payCards;
        }
    }

    private PayCardInfoRec DummyPayCard
    {
        get
        {
            var candidates = this.PayCards.Where(x => x.DisplaySpecificFields.FirstOrDefault(y => y.Key == DummyKey) != null).ToList();
            if (candidates.Count > 1)
            {
                return candidates.FirstOrDefault();
            }
            else
            {
                return this.PayCards.FirstOrDefault(x => x.IsDummy);
            }
        }
    }

    private List<PayCardInfoRec> NoneDummyPayCards
    {
        get
        {
            if (Model.InputFields == null || Model.InputFields.Count == 0 || Model.UseDummyPayCard)
            {
                return null;
            }

            return this.PayCards.Where(x => !x.IsDummy && x.DisplaySpecificFields.FirstOrDefault(y => y.Key == DummyKey) == null && (x.SuccessDepositNumber > 0 || x.SuccessWithdrawNumber > 0)).ToList();
        }
    }

    private List<PayCardInfoRec> _gMPayCards;

    private List<PayCardInfoRec> GmPayCards
    {
        get
        {
            if (Model.GmCorePaymentSolutionId == VendorID.Unknown)
            {
                return null;
            }

            if (Model.InputFields == null || Model.InputFields.Count == 0 || Model.UseDummyPayCard)
            {
                return null;
            }

            if (_gMPayCards != null)
            {
                return _gMPayCards;
            }

            _gMPayCards = GamMatrixClient.GetPayCards(Model.GmCorePaymentSolutionId).Where(x => !x.IsDummy && (x.SuccessDepositNumber > 0 || x.SuccessWithdrawNumber > 0)).ToList();
            return _gMPayCards;
        }
    }

    private string RenderRadioInput(long payCardId, string accountNumber, PayCardInfoRec payCard = null, bool isSelected = false)
    {
        var dataPayCardId = "data-id=\"" + payCardId + "\"";

        var dataInputFields = string.Empty;

        if (Model.InputFields != null && Model.InputFields.Count > 0)
        {
            foreach (var inputField in Model.InputFields.Where(f => !f.IsAlwaysUserInput))
            {
                var fieldName = inputField.Name;
                var paymentSolutionName = this.Model.Normalize(Model.MoneyMatrixPaymentSolutionName);

                if (!fieldName.StartsWith(paymentSolutionName) && !fieldName.StartsWith(PaymentParameterFieldKey))
                {
                    fieldName = string.Format("{0}{1}", paymentSolutionName, fieldName);
                }

                var needRender = true;
                if (payCard != null)
                {
                    var field = payCard.DisplaySpecificFields.FirstOrDefault(x => this.Model.Normalize(x.Key) == fieldName);

                    if (field != null)
                    {
                        dataInputFields += string.Format("data-{0}=\"{1}\" ", inputField.Name, field.Value);

                        needRender = false;
                    }
                }

                if (needRender)
                {
                    dataInputFields += string.Format("data-{0}=\"{1}\" ", inputField.Name, accountNumber);
                }
            }
        }

        var radioInput = "<input type=\"radio\" name=\"radioGroupRecentCards\"" + dataPayCardId + dataInputFields + (isSelected ? "checked=\"checked\"" : string.Empty) + "/>";
        radioInput += "<label dir=\"ltr\">" + accountNumber + "</label>";

        return radioInput;
    }

    private MvcHtmlString RenderInputField(MmInputField inputField)
    {
        var clientValidators = ClientValidators.Create();
        if (inputField.IsRequired)
        {
            clientValidators.Required();
        }

        var javaScriptMethod = inputField.ValidationJavaScriptMethodName;
        if (string.IsNullOrEmpty(javaScriptMethod) && !string.IsNullOrEmpty(inputField.Format))
        {
            javaScriptMethod = string.Format("validate{0}", inputField.Name);
        }

        if (!string.IsNullOrEmpty(javaScriptMethod))
        {
            clientValidators.Custom(javaScriptMethod);
        }

        switch (inputField.Type)
        {
            case MmInputFieldType.TextBox:
            case MmInputFieldType.TextBoxEmail:
            case MmInputFieldType.TextBoxIban:
            case MmInputFieldType.TextBoxSwiftCode:
            case MmInputFieldType.TextBoxSortCode:
            case MmInputFieldType.TextBoxTime:
            case MmInputFieldType.TextBoxNumber:
                {
                    if (inputField.Type == MmInputFieldType.TextBoxEmail)
                    {
                        clientValidators.Email();
                    }
                    else if (inputField.Type == MmInputFieldType.TextBoxIban)
                    {
                        clientValidators.Custom("isValidIBANNumber");
                    }
                    else if (inputField.Type == MmInputFieldType.TextBoxSwiftCode)
                    {
                        clientValidators.Custom("validateSwift");
                    }
                    else if (inputField.Type == MmInputFieldType.TextBoxSortCode)
                    {
                        clientValidators.Custom("validateSortCode");
                    }

                    return Html.TextBox(inputField.Name, inputField.DefaultValue,
                       new
                       {
                           @id = string.Format("input{0}", inputField.Name),
                           @dir = "ltr",
                           @validator = clientValidators,
                           @class = "textbox"
                       });
                }
            case MmInputFieldType.DropDownDate:
                return this.RenderDateDropDownList(inputField);
            case MmInputFieldType.DropDown:
                return this.RenderLookupList(inputField, clientValidators);
            default:
                return MvcHtmlString.Empty;
        }
    }

    #region Helper methods

    private MvcHtmlString CreateDropDownList(string fieldId, string fieldName, SelectList listItems, ClientValidators clientValidators, string onChangeFunc = null)
    {
        return Html.DropDownList(fieldName, listItems, new
        {
            @id = fieldId,
            @dir = "ltr",
            @validator = clientValidators,
            @class = "select",
            @onchange = !string.IsNullOrEmpty(onChangeFunc) ? onChangeFunc : string.Empty,
        });
    }

    private MvcHtmlString RenderLookupList(MmInputField inputField, ClientValidators clientValidators)
    {
        var selectList = new SelectList(string.Empty);

        if(inputField.Values != null && inputField.Values.Count > 0)
        {
            selectList = new SelectList(inputField.Values, "Key", "Value");
        }

        var inputName = string.Format("input{0}", inputField.Name);

        return CreateDropDownList(inputName, inputName, selectList, clientValidators);
    }

    private MvcHtmlString RenderDateDropDownList(MmInputField inputField)
    {
        var clientValidators = ClientValidators.Create();
        if (inputField.IsRequired)
        {
            clientValidators.Required();
        }

        var aggregatorFieldId = string.Format("input{0}", inputField.Name);
        var dayFieldId = string.Format("inputDay{0}", inputField.Name);
        var monthFieldId = string.Format("inputMonth{0}", inputField.Name);
        var yearFieldId = string.Format("inputYear{0}", inputField.Name);

        var setDateFunc = string.Format("setDate('{0}', '{1}', '{2}', '{3}')", aggregatorFieldId, dayFieldId, monthFieldId, yearFieldId);

        var dayListItems = DropDownNumericItems(this.GetMetadata(".Day_Label"), 1, 31);
        var dayList = CreateDropDownList(dayFieldId, "input" + dayFieldId, dayListItems, clientValidators.Custom("validateDay"), setDateFunc);

        var monthListItems = DropDownNumericItems(this.GetMetadata(".Month_Label"), 1, 12);
        var monthList = CreateDropDownList(monthFieldId, "input" + monthFieldId, monthListItems, clientValidators.Custom("validateMonth"), setDateFunc);

        var yearLitItems = DropDownNumericItems(this.GetMetadata(".Year_Label"), DateTime.Now.Year, 1900);
        var yearList = CreateDropDownList(yearFieldId, "input" + yearFieldId, yearLitItems, clientValidators.Custom("validateYear"), setDateFunc);

        var date = Html.Hidden(inputField.Name, string.Empty, new
        {
            @id = aggregatorFieldId,
        });

        var dateString = dayList.ToHtmlString() + monthList.ToHtmlString() + yearList.ToHtmlString() + date.ToHtmlString();

        var dateDropDownListList = MvcHtmlString.Create(dateString);

        return dateDropDownListList;
    }

    private SelectList DropDownNumericItems(string labelValue, int minValue, int maxValue)
    {
        var itemList = new Dictionary<string, string> {{"", labelValue}};

        if (minValue < maxValue)
        {
            for (int i = minValue; i <= maxValue; i++)
            {
                itemList.Add(string.Format("{0:00}", i), string.Format("{0:00}", i));
            }
        }
        else
        {
            for (int i = minValue; i > maxValue; i--)
            {
                itemList.Add(i.ToString(), i.ToString());
            }
        }

        return new SelectList(itemList, "Key", "Value");
    }

    #endregion

    protected override void OnPreRender(EventArgs e)
    {
        if ((NoneDummyPayCards == null || NoneDummyPayCards.Count == 0) && (GmPayCards == null || GmPayCards.Count == 0))
        {
            var tabRegisterCaption = Metadata.Get(string.Format("/Metadata/PaymentMethod/MoneyMatrix_{0}.Title", Model.MoneyMatrixPaymentSolutionName.Replace(".", "_")));
            if (!string.IsNullOrEmpty(tabRegisterCaption))
            {
                tabRegisterPayCard.Attributes["Caption"] = tabRegisterCaption;
            }
        }
    }
</script>

<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <tabs>
        <ui:Panel runat="server" ID="tabRecentCards" Caption="<%$ Metadata:value(.Tab_ExistingPayCards) %>">
            <form id="formRecentCards" onsubmit="return false">
                <ui:InputField runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	                    <LabelPart><%= Model.Type == TransactionType.Withdraw ? this.GetMetadata(".WithdrawTo").SafeHtmlEncode() : this.GetMetadata(".DepositWith").SafeHtmlEncode() %></LabelPart>
	                    <ControlPart>
                            <ul id="paycards-selector">    
                            <%if (this.NoneDummyPayCards != null && this.NoneDummyPayCards.Count > 0)
                                {
                                    var isSelected = true;
                                    foreach (var payCard in this.NoneDummyPayCards)
                                    { %>
                                    <li>
                                        <%= RenderRadioInput(payCard.ID, payCard.DisplayName, payCard, isSelected) %>
                                    </li>
                                    <% isSelected = false;
                                            }
                                        }
                                        else if (this.GmPayCards != null && this.GmPayCards.Count > 0)
                                        {
                                            var isSelected = true;
                                            foreach (var payCard in this.GmPayCards)
                                            { %>
                                    <li>
                                        <%= RenderRadioInput(DummyPayCard.ID, payCard.DisplayNumber, isSelected: isSelected) %>
                                    </li>
                                    <% isSelected = false;
                                            }
                                        }%>
                            </ul>
                             </ControlPart>
                    </ui:InputField>
                    <% this.Model.ForEachInputFieldInTheModel(() =>
                        {
                        if (Model.CurrentInputField.IsAlwaysUserInput)
                        { %>
                            <ui:InputField runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	                            <LabelPart><%= Model.CurrentInputField.Label.SafeHtmlEncode()%></LabelPart>
	                            <ControlPart>
                                    <%: this.RenderInputField(Model.CurrentInputField) %>
	                            </ControlPart>
                            </ui:InputField>
                            <% }
                       });%>
                <center>
                    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnSubmitRecentCards", @class="ContinueButton button" })%>
                </center>
            </form>
        </ui:Panel>
        
        <ui:Panel runat="server" ID="tabRegisterPayCard" Caption="<%$ Metadata:value(.Tab_RegisterPayCard) %>">
            <form id="formRegisterPayCard" onsubmit="return false">
                
                <% this.Model.ForEachInputFieldInTheModel(() =>
                    { %>
                    <ui:InputField runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	                    <LabelPart><%= Model.CurrentInputField.Label.SafeHtmlEncode()%></LabelPart>
	                    <ControlPart>
                            <%: this.RenderInputField(Model.CurrentInputField) %>
	                    </ControlPart>
                    </ui:InputField>
                <% }); %>

                <center>
                    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnSubmitRegisterPayCard", @class="ContinueButton button" })%>
                </center>
            </form>
        </ui:Panel>
    </tabs>
</ui:TabbedContent>
<script language="javascript" type="text/javascript">
    $(function () {
        <% this.Model.ForEachInputFieldInTheModel(() =>
    {
    if (Model.Type == TransactionType.Deposit)
    { %>
        $('#formPrepareDeposit').append($('<input type="hidden" name="<%= Model.CurrentInputField.Name %>" id="<%= string.Format("hdn{0}", Model.CurrentInputField.Name) %>"/>')); 
        <% }
    else if (Model.Type == TransactionType.Withdraw)
    { %>
        $('#formPrepareWithdraw').append($('<input type="hidden" name="<%= Model.CurrentInputField.Name %>" id="<%= string.Format("hdn{0}", Model.CurrentInputField.Name) %>"/>')); 
        <% }
            }); %>

        initCurrency();

        initAmounts();

        $('#tabbedPayCards').showTab('tabRegisterPayCard', true);
        $('#tabbedPayCards').showTab('tabRecentCards', false);
        $('#tabbedPayCards').selectTab('tabRegisterPayCard', true);

        $('#btnSubmitRegisterPayCard').click(function (e) {
            e.preventDefault();

            submitAmounts();

            <% if (Model.Type == TransactionType.Deposit)
    { %>
            if (!isDepositInputFormValid() || !$('#formRegisterPayCard').valid()) {
                return;
            }
            <% }
    else if (Model.Type == TransactionType.Withdraw)
    { %>
            if (!isWithdrawInputFormValid() || !$('#formRegisterPayCard').valid()) {
                return;
            }
            <% } %>

            <% this.Model.ForEachInputFieldInTheModel(() =>
    { %> $('<%= string.Format("#hdn{0}", Model.CurrentInputField.Name) %>').val($('<%= string.Format("#formRegisterPayCard #input{0}", Model.CurrentInputField.Name) %>').val()); <% }); %>

            $('#btnSubmitRegisterPayCard').toggleLoadingSpin(true);

            <% if (Model.Type == TransactionType.Deposit)
    { %>
            tryToSubmitDepositInputForm(
                '<%= DummyPayCard.ID %>',
                function () {
                    $('#btnSubmitRegisterPayCard').toggleLoadingSpin(false);
                });
            <% }
    else if (Model.Type == TransactionType.Withdraw)
    { %>
            tryToSubmitWithdrawInputForm(
                '<%= DummyPayCard.ID %>',
                function () {
                    $('#btnSubmitRegisterPayCard').toggleLoadingSpin(false);
                });
            <% } %>
        });

        <% if ((NoneDummyPayCards != null && NoneDummyPayCards.Count > 0) || (GmPayCards != null && GmPayCards.Count > 0))
    { %>
        $('#tabbedPayCards').showTab('tabRecentCards', true);
        $('#tabbedPayCards').selectTab('tabRecentCards', true);

        <% if (!Model.AllowInfiniteCardEntries)
    { %>
        $('#tabbedPayCards').showTab('tabRegisterPayCard', false);
        <% } %>

        $('#btnSubmitRecentCards').click(function (e) {
            e.preventDefault();

            submitAmounts();

            <% if (Model.Type == TransactionType.Deposit)
    { %>
            if (!isDepositInputFormValid() || !$('#formRecentCards').valid()) {
                return;
            }
            <% }
    else if (Model.Type == TransactionType.Withdraw)
    { %>
            if (!isWithdrawInputFormValid() || !$('#formRecentCards').valid()) {
                return;
            }
            <% } %>

            <% this.Model.ForEachInputFieldInTheModel(() =>
    {
    if (Model.CurrentInputField.IsAlwaysUserInput)
    { %>
            $('<%= string.Format("#hdn{0}", Model.CurrentInputField.Name) %>').val($('<%= string.Format("#formRecentCards #input{0}", Model.CurrentInputField.Name) %>').val()); 
            <% }
    else
    { %>
            $('<%= string.Format("#hdn{0}", Model.CurrentInputField.Name) %>').val($('input[name=radioGroupRecentCards]:checked').data("<%= Model.CurrentInputField.Name.ToLower(CultureInfo.InvariantCulture) %>"));
            <% }
                   }); %>

            $('#btnSubmitRecentCards').toggleLoadingSpin(true);

            <% if (Model.Type == TransactionType.Deposit)
    { %>
            tryToSubmitDepositInputForm(
                $('input[name=radioGroupRecentCards]:checked').data("id"),
                function () {
                    $('#btnSubmitRecentCards').toggleLoadingSpin(false);
                });
            <% }
    else if (Model.Type == TransactionType.Withdraw)
    { %>
            tryToSubmitWithdrawInputForm(
                $('input[name=radioGroupRecentCards]:checked').data("id"),
                function () {
                    $('#btnSubmitRecentCards').toggleLoadingSpin(false);
                });
            <% } %>
        });
        <% } %>

        function initCurrency() {
            <% if (!string.IsNullOrEmpty(Model.SupportedCurrency))
    { %>
            $('#ddlCurrency').val('<%= Model.SupportedCurrency %>');
            $('#ddlCurrency option[value!="<%= Model.SupportedCurrency %>"]').remove();
            <% } %>
        }

        function initAmounts() {
            <% if (Model.SupportedAmounts != null && Model.SupportedAmounts.Length > 0)
    { %>
            var strAmounts = '<%= string.Join(",", Model.SupportedAmounts) %>';

            var txtAmount = $('#fldCurrencyAmount #txtAmount');

            txtAmount.css('visibility', 'hidden');

            var lstAmounts = $('<select id="lstAmounts" class="lst-amounts select" />');

            var strAmountsArr = strAmounts.split(',');

            for (var i = 0; i < strAmountsArr.length; i++) {
                lstAmounts.append($('<option/>').attr('value', strAmountsArr[i]).text(parseFloat(strAmountsArr[i]).toFixed(2)));
            }

            txtAmount.before(lstAmounts);
            <% } %>
        }

        function submitAmounts() {
            <% if (Model.SupportedAmounts != null && Model.SupportedAmounts.Length > 0)
    { %>
            $('[name="amount"]').val($('#lstAmounts').val());
            $('#txtAmount').val($('#lstAmounts').val());
            <% } %>
        }
    });
</script>

<ui:MinifiedJavascriptControl runat="server" ID="script" AppendToPageEnd="true" Enabled="true">
    <script type="text/javascript">
        <% this.Model.ForEachInputFieldInTheModel(() => {
           if (!string.IsNullOrEmpty(Model.CurrentInputField.Format))
           { %>
                function validate<%= Model.CurrentInputField.Name %>() {
                    var errorMessage = "<%= (!string.IsNullOrEmpty(this.GetMetadata("." + Model.CurrentInputField.Name + "_Invalid").SafeJavascriptStringEncode()) ? this.GetMetadata("." + Model.CurrentInputField.Name + "_Invalid").SafeJavascriptStringEncode() : "This field is invalid") %>";
                                    
                    var regExp = new RegExp(/<%= Model.CurrentInputField.Format %>/);

                    return regExp.test(this) || errorMessage;
                }
        <% }}); %>

        function isValidIBANNumber() {
            var input = this;

            var errorMessage = '<%= this.GetMetadata(".Iban_Invalid").SafeJavascriptStringEncode() %>';

            var CODE_LENGTHS = {
                AD: 24, AE: 23, AT: 20, AZ: 28, BA: 20, BE: 16, BG: 22, BH: 22, BR: 29,
                CH: 21, CR: 21, CY: 28, CZ: 24, DE: 22, DK: 18, DO: 28, EE: 20, ES: 24,
                FI: 18, FO: 18, FR: 27, GB: 22, GI: 23, GL: 18, GR: 27, GT: 28, HR: 21,
                HU: 28, IE: 22, IL: 23, IS: 26, IT: 27, JO: 30, KW: 30, KZ: 20, LB: 28,
                LI: 21, LT: 20, LU: 20, LV: 21, MC: 27, MD: 24, ME: 22, MK: 19, MR: 27,
                MT: 31, MU: 30, NL: 18, NO: 15, PK: 24, PL: 28, PS: 29, PT: 25, QA: 29,
                RO: 24, RS: 22, SA: 24, SE: 24, SI: 19, SK: 24, SM: 27, TN: 24, TR: 26
            };
            var iban = String(input).toUpperCase().replace(/[^A-Z0-9]/g, ''), // keep only alphanumeric characters
                code = iban.match(/^([A-Z]{2})(\d{2})([A-Z\d]+)$/), // match and capture (1) the country code, (2) the check digits, and (3) the rest
                digits;
            // check syntax and length
            if (!code || (CODE_LENGTHS[code[1]] != null && iban.length !== CODE_LENGTHS[code[1]])) {
                return errorMessage;
            }

            // rearrange country code and check digits, and convert chars to ints
            digits = (code[3] + code[1] + code[2]).replace(/[A-Z]/g, function (letter) {
                return letter.charCodeAt(0) - 55;
            });
            // final check
            return mod97(digits) === 1 || errorMessage;
        }

        function mod97(string) {
            var checksum = string.slice(0, 2), fragment;
            for (var offset = 2; offset < string.length; offset += 7) {
                fragment = String(checksum) + string.substring(offset, offset + 7);
                checksum = parseInt(fragment, 10) % 97;
            }
            return checksum;
        }

        function validateSwift() {
            var input = this;

            var errorMessage = '<%= this.GetMetadata(".BankSwiftCode_Invalid").SafeJavascriptStringEncode() %>';

            var bankSwiftCodeRegExp = /^([a-zA-Z]){4}([a-zA-Z]){2}([0-9a-zA-Z]){2}([0-9a-zA-Z]{3})?$/;

            return bankSwiftCodeRegExp.test(input) || errorMessage;
        }

        function validateSortCode() {

            var input = this.trim();

            if (input.length === 0) {
                return true;
            }

            var errorMessage = '<%= this.GetMetadata(".BankSortCode_Invalid").SafeJavascriptStringEncode() %>';

            var sortCode = input.replace(/[^0-9]/g, '');

            return sortCode.length === 6 || errorMessage;
        }

        function setDate(fieldId, dayFieldId, monthFieldId, yearFieldId) {
            var value = $('#' + monthFieldId).val() + '/' + $('#' + dayFieldId).val() + '/' + $('#' + yearFieldId).val();

            $('#' + fieldId).val(value);
        }

        function validateDay() {
            var errorMessage = "This field is invalid";
                                    
            var regExp = new RegExp(/^(0[1-9]|1\d|2\d|3[01])/);

            return regExp.test(this) || errorMessage;
        }
        function validateMonth() {
            var errorMessage = "This field is invalid";
                                    
            var regExp = new RegExp(/^(0[1-9]|1[0-2])/);

            return regExp.test(this) || errorMessage;
        }
        function validateYear() {
            var errorMessage = "This field is invalid";
                                    
            var regExp = new RegExp(/^(19|20)\d{2}$/);

            return regExp.test(this) || errorMessage;
        }
    </script>
</ui:MinifiedJavascriptControl>
