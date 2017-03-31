<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>


<script type="text/C#" runat="server">
    private List<PayCardInfoRec> PayCards { get; set; }
    
    protected override void OnInit(EventArgs e)
    {
        var payCards = GamMatrixClient.GetPayCards()
                        .Where(p => !p.IsDummy &&
                        (p.VendorID == VendorID.Bank ||
                            p.VendorID == VendorID.InPay ||
                            (p.VendorID == VendorID.Envoy &&
                            !string.Equals(p.BankName, "WEBMONEY", StringComparison.OrdinalIgnoreCase) &&
                            !string.Equals(p.BankName, "MONETA", StringComparison.OrdinalIgnoreCase) &&
                            !string.Equals(p.BankName, "INSTADEBIT", StringComparison.OrdinalIgnoreCase) &&
                            !string.Equals(p.BankName, "SPEEDCARD", StringComparison.OrdinalIgnoreCase)) ||
                            p.VendorID == VendorID.EnterCash))
                        // Exclude Turkey Envoy PayCard
                        .Where(p => ((p.VendorID == VendorID.Envoy && p.BankCountryID != 223) ||
                                p.VendorID == VendorID.Bank ||
                                p.VendorID == VendorID.InPay ||
                                p.VendorID == VendorID.EnterCash))
                        .OrderByDescending(p => p.Ins).ToList();

        if (payCards.Any(p => p.VendorID == VendorID.EnterCash && !p.IsDummy && p.ActiveStatus == ActiveStatus.Active))
        {
            var payCardsToRemove = new List<PayCardInfoRec>();
            var banks = GamMatrixClient.GetEnterCashBankInfo(false);
            foreach (var payCard in payCards.Where(p => p.VendorID == VendorID.EnterCash && !p.IsDummy && p.ActiveStatus == ActiveStatus.Active))
            {
                var exists = false;
                if (payCard.DisplaySpecificFields != null)
                {
                    var field = payCard.DisplaySpecificFields.FirstOrDefault(dsf => dsf.Key == "bankid");
                    if (field != null)
                    {
                        long bankID;
                        if (long.TryParse(field.Value, out bankID))
                        {
                            if (banks.Any(b => b.Id == bankID))
                                exists = true;
                        }
                    }
                }

                if (!exists)
                    payCardsToRemove.Add(payCard);
            }
            foreach (var payCard in payCardsToRemove)
            {
                try
                {
                    GamMatrixClient.UpdatePayCardStatus(payCard.ID, ActiveStatus.InActive);
                }
                catch (Exception ex)
                {
                    Logger.Exception(ex);
                }
                payCards.Remove(payCard);
            }
        }

        this.PayCards = payCards;
                                        
        base.OnInit(e);
    }

    private string GetPayCardJson(PayCardInfoRec card)
    {
        return string.Format("{{\"ID\":\"{0}\",\"BankName\":\"{1}\",\"BankCode\":\"{2}\",\"BranchAddress\":\"{3}\",\"BranchCode\":\"{4}\",\"Payee\":\"{5}\",\"PayeeAddress\":\"{6}\",\"AccountNumber\":\"{7}\",\"IBAN\":\"{8}\",\"SWIFT\":\"{9}\",\"Currency\":\"{10}\",\"CountryID\":\"{11}\"}}"
            , card.ID
            , card.BankName.SafeJavascriptStringEncode()
            , card.BankCode.SafeJavascriptStringEncode()
            , card.BankAddress.SafeJavascriptStringEncode()
            , card.BankBranchCode.SafeJavascriptStringEncode()
            , card.OwnerName.SafeJavascriptStringEncode()
            , card.BankBeneficiaryAddress.SafeJavascriptStringEncode()
            , card.BankAccountNo.SafeJavascriptStringEncode()
            , card.BankIBAN.SafeJavascriptStringEncode()
            , card.BankSWIFT.SafeJavascriptStringEncode()
            , card.BaseCurrency.SafeJavascriptStringEncode()
            , card.BankCountryID
            );
    }

    private SelectList GetCountryList()
    {
        Dictionary<long, BankWithdrawalCountryConfig> dic = PaymentMethodManager.GetBankWithdrawalConfiguration();
    
        var list = CountryManager.GetAllCountries()
                    .Where(c => c.UserSelectable && dic.ContainsKey(c.InternalID) && dic[c.InternalID].Type != BankWithdrawalType.None )
                    .Select(c => new { Key = c.InternalID.ToString(), Value = c.DisplayName })
                    .OrderBy(c => c.Value)
                    .ToList();

        object selectedValue = ProfileCommon.Current.UserCountryID;

        return new SelectList(list
            , "Key"
            , "Value"
            , selectedValue
            );
    }

    private string GetCountryJson()
    {
        StringBuilder json = new StringBuilder();
        {
            json.Append("{");
            Dictionary<long, BankWithdrawalCountryConfig> config = PaymentMethodManager.GetBankWithdrawalConfiguration();
            foreach (BankWithdrawalCountryConfig item in config.Values)
            {
                if (item.Type == BankWithdrawalType.None)
                    continue;

                json.AppendFormat("\"{0}\":\"{1}\",", item.InternalID, item.Type.ToString());
            }
            if (json[json.Length - 1] == ',')
                json.Remove(json.Length - 1, 1);
            json.Append("}");
        }
        return json.ToString();
    }
</script>

<div class="BankWithdrawal">
    <fieldset>
    <legend class="Hidden">
    <%= this.GetMetadata(".BankAccount").SafeHtmlEncode() %>
    </legend>
    <p class="SubHeading WithdrawSubHeading">
    <%= this.GetMetadata(".BankAccount").SafeHtmlEncode() %>
    </p>
        <%: Html.Hidden( "payCardID", string.Empty, new { @id = "hBankPayCardID" }) %>

<% Html.RenderPartial("/Components/GenericTabSelector", new GenericTabSelectorViewModel(new List<GenericTabData> 
{ 
new GenericTabData 
{ 
Name = this.GetMetadata(".Tab_RecentPayCards"), 
Attributes = new Dictionary<string, string>() { {"id", "#tabExistingCard"} } 
},
new GenericTabData 
{ 
Name = this.GetMetadata(".Tabs_RegisterPayCard"), 
Attributes = new Dictionary<string, string>() { {"id", "#tabRegisterCard"} } 
}
})
{
ComponentId = "cardActionSelector"
}); %>

<div class="TabContent" id="tabExistingCard">
        
        <ul class="FormList">
        <li class="FormItem">
                    <ul class="PayCardList">
                        <% foreach (PayCardInfoRec card in this.PayCards)
                           { %>
                        <li>
                            <input type="radio" name="existingPayCardID" class="FormRadio" id="btnPayCard_<%: card.ID %>" value="<%: card.ID %>" data-json="<%= GetPayCardJson(card).SafeHtmlEncode() %>" />
                            <label for="btnPayCard_<%: card.ID %>"><%= card.DisplayNumber.SafeHtmlEncode() %></label>
                        </li>
                        <% } %>
                    </ul>
        </li>

                <%---------------------------------------------------------------
                    BankName (Readonly)
                 ----------------------------------------------------------------%>
        <li class="FormItem" id="fldBankName2">
        <label class="FormLabel" for="withdrawBankName2">
                    <%= this.GetMetadata(".BankName_Label").SafeHtmlEncode()%>
                    </label>
                    <%: Html.TextBox("bankName2", string.Empty, new Dictionary<string, object>()  
                        { 
                            { "class", "FormInput" },
                            { "id", "withdrawBankName2" },
                            { "dir", "ltr" },
                            { "autocomplete", "off" },
{ "placeholder", this.GetMetadata(".BankName_Label") },
                            { "readonly", "readonly" },
                        }) %>
        </li>


                <%---------------------------------------------------------------
                    BankCode (Readonly)
                 ----------------------------------------------------------------%>
        <li class="FormItem" id="fldBankCode2">
        <label class="FormLabel" for="withdrawBankCode2">
                    <%= this.GetMetadata(".BankCode_Label").SafeHtmlEncode()%>
                    </label>
                    <%: Html.TextBox("bankCode2", string.Empty, new Dictionary<string, object>()  
                        { 
                            { "class", "FormInput" },
                            { "id", "withdrawBankCode2" },
                            { "dir", "ltr" },
                            { "autocomplete", "off" },
{ "placeholder", this.GetMetadata(".BankCode_Label") },
                            { "readonly", "readonly" },
                        }) %>
        </li>


                <%---------------------------------------------------------------
                    BranchAddress (Readonly)
                 ----------------------------------------------------------------%>
        <li class="FormItem" id="fldBranchAddress2">
        <label class="FormLabel" for="withdrawBranchAddress2">
                    <%= this.GetMetadata(".BranchAddress_Label").SafeHtmlEncode()%>
                    </label>
                    <%: Html.TextBox("branchAddress2", string.Empty, new Dictionary<string, object>()  
                        { 
                            { "class", "FormInput" },
                            { "id", "withdrawBranchAddress2" },
                            { "dir", "ltr" },
                            { "autocomplete", "off" },
{ "placeholder", this.GetMetadata(".BranchAddress_Label") },
                            { "readonly", "readonly" },
                        }) %>
        </li>


                <%---------------------------------------------------------------
                    BranchCode (Readonly)
                 ----------------------------------------------------------------%>
        <li class="FormItem" id="fldBranchCode2">
        <label class="FormLabel" for="withdrawBranchCode2">
                    <%= this.GetMetadata(".BranchCode_Label").SafeHtmlEncode()%>
                    </label>
                    <%: Html.TextBox("branchCode2", string.Empty, new Dictionary<string, object>()  
                        { 
                            { "class", "FormInput" },
                            { "id", "withdrawBranchCode2" },
                            { "dir", "ltr" },
                            { "autocomplete", "off" },
{ "placeholder", this.GetMetadata(".BranchCode_Label") },
                            { "readonly", "readonly" },
                        }) %>
        </li>

                <%---------------------------------------------------------------
                    Payee (Readonly)
                 ----------------------------------------------------------------%>
        <li class="FormItem" id="fldPayee2">
        <label class="FormLabel" for="withdrawPayee2">
                    <%= this.GetMetadata(".Payee_Label").SafeHtmlEncode()%>
                    </label>
                    <%: Html.TextBox("payee2", string.Empty, new Dictionary<string, object>()  
                        { 
                            { "class", "FormInput" },
                            { "id", "withdrawPayee2" },
                            { "dir", "ltr" },
                            { "autocomplete", "off" },
{ "placeholder", this.GetMetadata(".Payee_Label") },
                            { "readonly", "readonly" },
                        }) %>
        </li>
                
                <%---------------------------------------------------------------
                    Payee Address (Readonly)
                 ----------------------------------------------------------------%>
        <li class="FormItem" id="fldPayeeAddress2">
        <label class="FormLabel" for="withdrawPayeeAddress2">
                    <%= this.GetMetadata(".PayeeAddress_Label").SafeHtmlEncode()%>
                    </label>
                    <%: Html.TextBox("payeeAddress2", string.Empty, new Dictionary<string, object>()  
                        { 
                            { "class", "FormInput" },
                            { "id", "withdrawPayeeAddress2" },
                            { "dir", "ltr" },
                            { "autocomplete", "off" },
{ "placeholder", this.GetMetadata(".PayeeAddress_Label") },
                            { "readonly", "readonly" },
                        }) %>
        </li>

                <%---------------------------------------------------------------
                    AccountNumber (Readonly)
                 ----------------------------------------------------------------%>
        <li class="FormItem" id="fldAccountNumber2">
        <label class="FormLabel" for="withdrawAccountNumber2">
                    <%= this.GetMetadata(".AccountNumber_Label").SafeHtmlEncode()%>
                    </label>
                    <%: Html.TextBox("accountNumber2", string.Empty, new Dictionary<string, object>()  
                        { 
                            { "class", "FormInput" },
                            { "id", "withdrawAccountNumber2" },
                            { "dir", "ltr" },
{ "type", "number" },
                            { "autocomplete", "off" },
{ "placeholder", this.GetMetadata(".AccountNumber_Label") },
                            { "readonly", "readonly" },
                        }) %>
        </li>


                <%---------------------------------------------------------------
                    IBAN (Readonly)
                 ----------------------------------------------------------------%>
        <li class="FormItem" id="fldIBAN2">
        <label class="FormLabel" for="withdrawIBAN2">
                    <%= this.GetMetadata(".IBAN_Label").SafeHtmlEncode()%>
                    </label>
                    <%: Html.TextBox("IBAN2", string.Empty, new Dictionary<string, object>()  
                        { 
                            { "class", "FormInput" },
                            { "id", "withdrawIBAN2" },
                            { "dir", "ltr" },
                            { "autocomplete", "off" },
                            { "readonly", "readonly" },
{ "placeholder", this.GetMetadata(".IBAN_Label") },
                            { "disabled", "disabled" },
                        }) %>
        </li>

                <%---------------------------------------------------------------
                    SWIFT (Readonly)
                 ----------------------------------------------------------------%>
        <li class="FormItem" id="fldSWIFT2">
        <label class="FormLabel" for="withdrawSWIFT2">
                    <%= this.GetMetadata(".SWIFT_Label").SafeHtmlEncode()%>
                    </label>
                    <%: Html.TextBox("SWIFT2", string.Empty, new Dictionary<string, object>()  
                        { 
                            { "class", "FormInput" },
                            { "id", "withdrawSWIFT2" },
                            { "dir", "ltr" },
                            { "autocomplete", "off" },
                            { "readonly", "readonly" },
{ "placeholder", this.GetMetadata(".SWIFT_Label") },
                            { "disabled", "disabled" },
                        }) %>
        </li>

                <%---------------------------------------------------------------
                    Currency (Readonly)
                 ----------------------------------------------------------------%>
        <li class="FormItem" id="fldCurrency2">
        <label class="FormLabel" for="withdrawCurrency2">
                    <%= this.GetMetadata(".Currency_Label").SafeHtmlEncode()%>
                    </label>
                    <%: Html.TextBox("currency2", string.Empty, new Dictionary<string, object>()  
                        { 
                            { "class", "FormInput" },
                            { "id", "withdrawCurrency2" },
                            { "dir", "ltr" },
                            { "autocomplete", "off" },
                            { "readonly", "readonly" },
{ "placeholder", this.GetMetadata(".Currency_Label") },
                            { "disabled", "disabled" },
                        }) %>
        </li>
        </ul>
</div>
    <div class="TabContent Hidden" id="tabRegisterCard">
            
            <%: Html.Hidden("vendorID", "", new { @id = "hBankPayCardVendorID" })%>
        <ul class="FormList">
            

            <%---------------------------------------------------------------
                Country
            ----------------------------------------------------------------%>
    <li class="FormItem" id="fldBankCountry">
                <label class="FormLabel" for="ddlBankCountry">
                    <%= this.GetMetadata(".BankCountry_Label").SafeHtmlEncode()%>
                </label>
                <%: Html.DropDownList( "countryID", GetCountryList(), new Dictionary<string, object>() 
                    { 
                        { "id", "ddlBankCountry" },
                        { "data-json", GetCountryJson() },
{ "disabled", "disabled" },
                        { "class", "FormInput" },
                    }) %>
                <span class="FormStatus">Status</span>
    <span class="FormHelp"></span>
    </li>


            <%---------------------------------------------------------------
                BankName
            ----------------------------------------------------------------%>
    <li class="FormItem" id="fldBankName">
                <label class="FormLabel" for="withdrawBankName">
                    <%= this.GetMetadata(".BankName_Label").SafeHtmlEncode()%>
                </label>
                <%: Html.TextBox("bankName", string.Empty, new Dictionary<string, object>()  
                    { 
                        { "class", "FormInput" },
                        { "id", "withdrawBankName" },
                        { "dir", "ltr" },
                        { "autocomplete", "off" },
{ "disabled", "disabled" },
{ "placeholder", this.GetMetadata(".BankName_Label") },
                        { "data-validator", ClientValidators.Create().RequiredIf("isBankNameRequired", this.GetMetadata(".BankName_Empty")).Custom("validateBankName") }
                    }) %>
                <span class="FormStatus">Status</span>
    <span class="FormHelp"></span>
    </li>
            <script type="text/javascript">
                function isBankNameRequired() { return g_CurrentConfiguration != null && g_CurrentConfiguration.showBankName; }
                function validateBankName() {
                    var value = this;
                    if (value == null ||
                    value.length == 0 ||
                    g_CurrentConfiguration == null ||
                    g_CurrentConfiguration.validationExpressionOfBankName == null) {
                        return true;
                    }
                    var ret = g_CurrentConfiguration.validationExpressionOfBankName.exec(value);
                    if (ret == null || ret.length == 0)
                        return '<%= this.GetMetadata(".Format_Invalid").SafeJavascriptStringEncode() %>';
                    return true;
                }
            </script>

            <%---------------------------------------------------------------
                BankCode
            ----------------------------------------------------------------%>
    <li class="FormItem" id="fldBankCode">
                <label class="FormLabel" for="withdrawBankCode">
                    <%= this.GetMetadata(".BankCode_Label").SafeHtmlEncode()%>
                </label>
                <%: Html.TextBox("bankCode", string.Empty, new Dictionary<string, object>()  
                    { 
                        { "class", "FormInput" },
                        { "id", "withdrawBankCode" },
                        { "dir", "ltr" },
                        { "autocomplete", "off" },
{ "disabled", "disabled" },
{ "placeholder", this.GetMetadata(".BankCode_Label") },
                        { "data-validator", ClientValidators.Create().RequiredIf("isBankCodeRequired", this.GetMetadata(".BankCode_Empty")).Custom("validateBankCode") }
                    }) %>
                <span class="FormStatus">Status</span>
    <span class="FormHelp"></span>
    </li>
            <script type="text/javascript">
                function isBankCodeRequired() { return g_CurrentConfiguration != null && g_CurrentConfiguration.showBankCode; }
                function validateBankCode() {
                    var value = this;
                    if (value == null ||
                    value.length == 0 ||
                    g_CurrentConfiguration == null ||
                    g_CurrentConfiguration.validationExpressionOfBankCode == null) {
                        return true;
                    }
                    var ret = g_CurrentConfiguration.validationExpressionOfBankCode.exec(value);
                    if (ret == null || ret.length == 0)
                        return '<%= this.GetMetadata(".Format_Invalid").SafeJavascriptStringEncode() %>';
                    return true;
                }
        </script>

            <%---------------------------------------------------------------
                BranchAddress
            ----------------------------------------------------------------%>
    <li class="FormItem" id="fldBranchAddress">
                <label class="FormLabel" for="withdrawBranchAddress">
                    <%= this.GetMetadata(".BranchAddress_Label").SafeHtmlEncode()%>
                </label>
                <%: Html.TextBox("branchAddress", string.Empty, new Dictionary<string, object>()  
                    { 
                        { "class", "FormInput" },
                        { "id", "withdrawBranchAddress" },
                        { "dir", "ltr" },
                        { "autocomplete", "off" },
{ "disabled", "disabled" },
{ "placeholder", this.GetMetadata(".BranchAddress_Label") },
                        { "data-validator", ClientValidators.Create().RequiredIf("isBranchAddressRequired", this.GetMetadata(".BranchAddress_Empty")).Custom("validateBranchAddress") }
                    }) %>
                <span class="FormStatus">Status</span>
    <span class="FormHelp"></span>
    </li>
            <script type="text/javascript">
                function isBranchAddressRequired() { return g_CurrentConfiguration != null && g_CurrentConfiguration.showBranchAddress; }
                function validateBranchAddress() {
                    var value = this;
                    if (value == null ||
                    value.length == 0 ||
                    g_CurrentConfiguration == null ||
                    g_CurrentConfiguration.validationExpressionOfBranchAddress == null) {
                        return true;
                    }
                    var ret = g_CurrentConfiguration.validationExpressionOfBranchAddress.exec(value);
                    if (ret == null || ret.length == 0)
                        return '<%= this.GetMetadata(".Format_Invalid").SafeJavascriptStringEncode() %>';
                    return true;
                }
        </script>

            <%---------------------------------------------------------------
                BranchCode
            ----------------------------------------------------------------%>
    <li class="FormItem" id="fldBranchCode">
                <label class="FormLabel" for="withdrawBranchCode">
                    <%= this.GetMetadata(".BranchCode_Label").SafeHtmlEncode()%>
                </label>
                <%: Html.TextBox("branchCode", string.Empty, new Dictionary<string, object>()  
                    { 
                        { "class", "FormInput" },
                        { "id", "withdrawBranchCode" },
                        { "dir", "ltr" },
                        { "autocomplete", "off" },
{ "disabled", "disabled" },
{ "placeholder", this.GetMetadata(".BranchCode_Label") },
                        { "data-validator", ClientValidators.Create().RequiredIf("isBranchCodeRequired", this.GetMetadata(".BranchCode_Empty")).Custom("validateBranchCode") }
                    }) %>
                <span class="FormStatus">Status</span>
    <span class="FormHelp"></span>
    </li>
            <script type="text/javascript">
                function isBranchCodeRequired() { return g_CurrentConfiguration != null && g_CurrentConfiguration.isBranchCodeRequired; }
                function validateBranchCode() {
                    var value = this;
                    if (value == null ||
                    value.length == 0 ||
                    g_CurrentConfiguration == null ||
                    g_CurrentConfiguration.validationExpressionOfBranchCode == null) {
                        return true;
                    }
                    var ret = g_CurrentConfiguration.validationExpressionOfBranchCode.exec(value);
                    if (ret == null || ret.length == 0)
                        return '<%= this.GetMetadata(".Format_Invalid").SafeJavascriptStringEncode() %>';
                    return true;
                }
            </script>

            <%---------------------------------------------------------------
                Payee
            ----------------------------------------------------------------%>
    <li class="FormItem" id="fldPayee">
                <label class="FormLabel" for="withdrawPayee">
                    <%= this.GetMetadata(".Payee_Label").SafeHtmlEncode()%>
                </label>
                <%: Html.TextBox("payee", string.Empty, new Dictionary<string, object>()  
                    { 
                        { "class", "FormInput" },
                        { "id", "withdrawPayee" },
                        { "dir", "ltr" },
                        { "autocomplete", "off" },
{ "disabled", "disabled" },
{ "placeholder", this.GetMetadata(".Payee_Label") },
                        { "data-validator", ClientValidators.Create().RequiredIf("isPayeeRequired", this.GetMetadata(".Payee_Empty")).Custom("validatePayee") }
                    }) %>
                <span class="FormStatus">Status</span>
    <span class="FormHelp"></span>
    </li>
            <script type="text/javascript">
                function isPayeeRequired() { return g_CurrentConfiguration != null && g_CurrentConfiguration.showPayee; }
                function validatePayee() {
                    var value = this;
                    if (value == null ||
                    value.length == 0 ||
                    g_CurrentConfiguration == null ||
                    g_CurrentConfiguration.validationExpressionOfPayee == null) {
                        return true;
                    }
                    var ret = g_CurrentConfiguration.validationExpressionOfPayee.exec(value);
                    if (ret == null || ret.length == 0)
                        return '<%= this.GetMetadata(".Format_Invalid").SafeJavascriptStringEncode() %>';
                    return true;
                }
            </script>
            
        <%---------------------------------------------------------------
            Payee Address 
         ----------------------------------------------------------------%>
        <li class="FormItem" id="fldPayeeAddress">
                <label class="FormLabel" for="withdrawPayeeAddress">
                    <%= this.GetMetadata(".PayeeAddress_Label").SafeHtmlEncode()%>
                </label>
                <%: Html.TextBox("payeeAddress", string.Empty, new Dictionary<string, object>()  
                    { 
                        { "class", "FormInput" },
                        { "id", "withdrawPayeeAddress" },
                        { "dir", "ltr" },
                        { "autocomplete", "off" },
{ "disabled", "disabled" },
{ "placeholder", this.GetMetadata(".PayeeAddress_Label") },
                        { "data-validator", ClientValidators.Create().RequiredIf("isPayeeAddressRequired", this.GetMetadata(".PayeeAddress_Empty")).Custom("validatePayeeAddress") }
                    }) %>
                <span class="FormStatus">Status</span>
    <span class="FormHelp"></span>
    </li>
            <script type="text/javascript">
                function isPayeeAddressRequired() { return g_CurrentConfiguration != null && g_CurrentConfiguration.showPayeeAddress; }
                function validatePayeeAddress() {
                    var value = this;
                    if (value == null ||
                    value.length == 0 ||
                    g_CurrentConfiguration == null ||
                    g_CurrentConfiguration.validationExpressionOfPayeeAddress == null) {
                        return true;
                    }
                    var ret = g_CurrentConfiguration.validationExpressionOfPayeeAddress.exec(value);
                    if (ret == null || ret.length == 0)
                        return '<%= this.GetMetadata(".Format_Invalid").SafeJavascriptStringEncode() %>';
                    return true;
                }
            </script>

            <%---------------------------------------------------------------
                AccountNumber
            ----------------------------------------------------------------%>
    <li class="FormItem" id="fldAccountNumber">
                <label class="FormLabel" for="withdrawAccountNumber">
                    <%= this.GetMetadata(".AccountNumber_Label").SafeHtmlEncode()%>
                </label>
                <%: Html.TextBox("accountNumber", string.Empty, new Dictionary<string, object>()  
                    { 
                        { "class", "FormInput" },
                        { "id", "withdrawAccountNumber" },
                        { "dir", "ltr" },
{ "type", "number" },
                        { "autocomplete", "off" },
{ "disabled", "disabled" },
{ "placeholder", this.GetMetadata(".AccountNumber_Label") },
                        { "data-validator", ClientValidators.Create().RequiredIf("isAccountNumberRequired", this.GetMetadata(".AccountNumber_Empty")).Custom("validateAccountNumber") }
                    }) %>
                <span class="FormStatus">Status</span>
    <span class="FormHelp"></span>
    </li>
            <script type="text/javascript">
                function isAccountNumberRequired() { return g_CurrentConfiguration != null && g_CurrentConfiguration.showAccountNumber; }
                function validateAccountNumber() {
                    var value = this;
                    if (value == null ||
                    value.length == 0 ||
                    g_CurrentConfiguration == null ||
                    g_CurrentConfiguration.validationExpressionOfAccountNumber == null) {
                        return true;
                    }
                    var ret = g_CurrentConfiguration.validationExpressionOfAccountNumber.exec(value);
                    if (ret == null || ret.length == 0)
                        return '<%= this.GetMetadata(".Format_Invalid").SafeJavascriptStringEncode() %>';
                    return true;
                }
            </script>

            <%---------------------------------------------------------------
                IBAN
            ----------------------------------------------------------------%>
    <li class="FormItem" id="fldIBAN">
                <label class="FormLabel" for="withdrawIBAN">
                    <%= this.GetMetadata(".IBAN_Label").SafeHtmlEncode()%>
                </label>
                <%: Html.TextBox("iban", string.Empty, new Dictionary<string, object>()  
                    { 
                        { "class", "FormInput" },
                        { "id", "withdrawIBAN" },
                        { "dir", "ltr" },
                        { "autocomplete", "off" },
{ "disabled", "disabled" },
{ "placeholder", this.GetMetadata(".IBAN_Label") },
                        { "data-validator", ClientValidators.Create().RequiredIf("isIBANRequired", this.GetMetadata(".IBAN_Empty")).Custom("validateIBAN") }
                    }) %>
                <span class="FormStatus">Status</span>
    <span class="FormHelp"></span>
    </li>
            <script type="text/javascript">
                function isIBANRequired() { return g_CurrentConfiguration != null && g_CurrentConfiguration.showIBAN; }
                function validateIBAN() {
                    var value = this;
                    if (value == null ||
                    value.length == 0 ||
                    g_CurrentConfiguration == null ||
                    g_CurrentConfiguration.validationExpressionOfIBAN == null) {
                        return true;
                    }
                    var ret = g_CurrentConfiguration.validationExpressionOfIBAN.exec(value);
                    if (ret == null || ret.length == 0)
                        return '<%= this.GetMetadata(".Format_Invalid").SafeJavascriptStringEncode() %>';

                    if (value == g_CurrentConfiguration.exampleOfIBAN)
                        return '<%= this.GetMetadata(".IBAN_Invalid").SafeJavascriptStringEncode() %>';

                    return true;
                }
            </script>

            <%---------------------------------------------------------------
                SWIFT
            ----------------------------------------------------------------%>
    <li class="FormItem" id="fldSWIFT">
                <label class="FormLabel" for="withdrawSWIFT">
                    <%= this.GetMetadata(".SWIFT_Label").SafeHtmlEncode()%>
                </label>
                <%: Html.TextBox("swift", string.Empty, new Dictionary<string, object>()  
                    { 
                        { "class", "FormInput" },
                        { "id", "withdrawSWIFT" },
                        { "dir", "ltr" },
                        { "autocomplete", "off" },
{ "disabled", "disabled" },
{ "placeholder", this.GetMetadata(".SWIFT_Label") },
                        { "data-validator", ClientValidators.Create().RequiredIf("isSWIFTRequired", this.GetMetadata(".SWIFT_Empty")).Custom("validateSWIFT") }
                    }) %>
                <span class="FormStatus">Status</span>
    <span class="FormHelp"></span>
    </li>
            <script type="text/javascript">
                function isSWIFTRequired() { return g_CurrentConfiguration != null && g_CurrentConfiguration.showSWIFT; }
                function validateSWIFT() {
                    var value = this;
                    if (value == null ||
                    value.length == 0 ||
                    g_CurrentConfiguration == null ||
                    g_CurrentConfiguration.validationExpressionOfSWIFT == null) {
                        return true;
                    }
                    var ret = g_CurrentConfiguration.validationExpressionOfSWIFT.exec(value);
                    if (ret == null || ret.length == 0)
                        return '<%= this.GetMetadata(".Format_Invalid").SafeJavascriptStringEncode() %>';

                    if (value == g_CurrentConfiguration.exampleOfSWIFT)
                        return '<%= this.GetMetadata(".SWIFT_Invalid").SafeJavascriptStringEncode() %>';

                    return true;
                }
            </script>


            <%---------------------------------------------------------------
                CheckDigits
            ----------------------------------------------------------------%>
    <li class="FormItem" id="fldCheckDigits">
                <label class="FormLabel" for="withdrawCheckDigits">
                    <%= this.GetMetadata(".CheckDigits_Label").SafeHtmlEncode()%>
                </label>
                <%: Html.TextBox("checkDigits", string.Empty, new Dictionary<string, object>()  
                    { 
                        { "class", "FormInput" },
                        { "id", "withdrawCheckDigits" },
                        { "dir", "ltr" },
                        { "autocomplete", "off" },
{ "disabled", "disabled" },
{ "placeholder", this.GetMetadata(".CheckDigits_Label") },
                        { "data-validator", ClientValidators.Create().RequiredIf("isCheckDigitsRequired", this.GetMetadata(".CheckDigits_Empty")).Custom("validateCheckDigits") }
                    }) %>
                <span class="FormStatus">Status</span>
    <span class="FormHelp"></span>
    </li>
            <script type="text/javascript">
                function isCheckDigitsRequired() { return g_CurrentConfiguration != null && g_CurrentConfiguration.showCheckDigits; }
                function validateCheckDigits() {
                    var value = this;
                    if (value == null ||
                    value.length == 0 ||
                    g_CurrentConfiguration == null ||
                    g_CurrentConfiguration.validationExpressionOfCheckDigits == null) {
                        return true;
                    }
                    var ret = g_CurrentConfiguration.validationExpressionOfCheckDigits.exec(value);
                    if (ret == null || ret.length == 0)
                        return '<%= this.GetMetadata(".Format_Invalid").SafeJavascriptStringEncode() %>';
                    return true;
                }
            </script>

            <%---------------------------------------------------------------
                Persinal ID Number
            ----------------------------------------------------------------%>
    <li class="FormItem" id="fldPersonalIDNumber">
                <label class="FormLabel" for="withdrawCurrency">
                    <%= this.GetMetadata(".PersonalIDNumber_Label").SafeHtmlEncode()%>
                </label>
                <%: Html.TextBox("additionalInformation", string.Empty, new Dictionary<string, object>()  
                    { 
                        { "class", "FormInput" },
                        { "id", "withdrawCurrency" },
                        { "dir", "ltr" },
{ "type", "number" },
                        { "autocomplete", "off" },
{ "disabled", "disabled" },
{ "placeholder", this.GetMetadata(".PersonalIDNumber_Label") },
                        { "data-validator", ClientValidators.Create().RequiredIf("isPersonalIDNumberRequired", this.GetMetadata(".PersonalIDNumber_Empty")).Custom("validatePersonalIDNumber") }
                    }) %>
                <span class="FormStatus">Status</span>
    <span class="FormHelp"></span>
    </li>
            <script type="text/javascript">
                function isPersonalIDNumberRequired() { return g_CurrentConfiguration != null && g_CurrentConfiguration.showPersonalIDNumber; }
                function validatePersonalIDNumber() {
                    var value = this;
                    if (value == null ||
                    value.length == 0 ||
                    g_CurrentConfiguration == null ||
                    g_CurrentConfiguration.validationExpressionOfPersonalIDNumber == null) {
                        return true;
                    }
                    var ret = g_CurrentConfiguration.validationExpressionOfPersonalIDNumber.exec(value);
                    if (ret == null || ret.length == 0)
                        return '<%= this.GetMetadata(".Format_Invalid").SafeJavascriptStringEncode() %>';
                    return true;
                }
            </script>


            <%---------------------------------------------------------------
                Base Currency
            ----------------------------------------------------------------%>
    <li class="FormItem" id="fldPayCardCurrency">
                <label class="FormLabel" for="withdrawBaseCurrency">
                    <%= this.GetMetadata(".Currency_Label").SafeHtmlEncode()%>
                </label>
                <%: Html.DropDownList("bankCurrency", new List<SelectListItem>(), new Dictionary<string, object>()
                {
                    { "class", "FormInput" },
{ "disabled", "disabled" },
                    { "id", "withdrawBaseCurrency" },
                })%>
                <span class="FormStatus">Status</span>
    <span class="FormHelp"></span>
    </li>
        </ul>
</div>

    </fieldset>
</div>

<ui:MinifiedJavascriptControl runat="server" AppendToPageEnd="true" Enabled="false">
    <% Html.RenderPartial("BankPayCardScript"); %>
</ui:MinifiedJavascriptControl>