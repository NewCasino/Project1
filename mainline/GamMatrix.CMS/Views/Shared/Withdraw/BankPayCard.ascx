<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>

<script language="C#" type="text/C#" runat="server">
private SelectList GetCountryList()
{
    Dictionary<long, BankWithdrawalCountryConfig> dic = PaymentMethodManager.GetBankWithdrawalConfiguration();
    
    var list = CountryManager.GetAllCountries()
                .Where(c => dic.ContainsKey(c.InternalID) && dic[c.InternalID].Type != BankWithdrawalType.None )
                .Select(c => new { Key = c.InternalID.ToString(), Value = c.DisplayName })
                .OrderBy(c => c.Value)
                .ToList();

    object selectedValue = null;
    var ipLocation = CM.State.IPLocation.GetByIP(Request.GetRealUserAddress());
    if (ipLocation != null && ipLocation.Found)
    {
        selectedValue = ipLocation.CountryID;
    }

    return new SelectList(list
        , "Key"
        , "Value"
        , selectedValue
        );
}

</script>

<%---------------------------------------------------------------
    bank transfer
 ----------------------------------------------------------------%>
<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <Tabs>


        <%---------------------------------------------------------------
            Recent banks
         ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabRecentCards" Caption="<%$ Metadata:value(.Tab_RecentPayCards) %>">
            <form id="formRecentCards" onsubmit="return false">
            

                <ui:InputField ID="fldExistingPayCard" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
            <LabelPart></LabelPart>
                <ControlPart>
                        <ul id="paycards-selector">
            
                        </ul>
                        <script id="pay-card-template" type="text/html">
                        <#
                            var d=arguments[0];

                            for(var i=0; i < d.length; i++)     
                            {        
                        #>
                            <li>
                                <input type="radio" name="existingPayCard" value="<#= d[i].ID.htmlEncode() #>" id="payCard_<#= d[i].ID.htmlEncode() #>"/>
                                <label for="payCard_<#= d[i].ID.htmlEncode() #>" dir="ltr">
                                    <#= d[i].BankName.htmlEncode() #> - <#= d[i].DisplayName.htmlEncode() #>
                                </label>
                            </li>
                        <#  }  #>
                        </script>              
                        <%: Html.Hidden("existingPayCardID", "", new 
                                { 
                                    @id = "hExistingPayCardID",
                                    @validator = ClientValidators.Create().Required(this.GetMetadata(".ExistingCard_Empty")) 
                                }) %>
                    </ControlPart>
                </ui:InputField>

                <%---------------------------------------------------------------
                    BankName (Readonly)
                 ----------------------------------------------------------------%>
                <ui:InputField ID="fldBankName2" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
                <LabelPart><%= this.GetMetadata(".BankName_Label").SafeHtmlEncode()%></LabelPart>
                <ControlPart>
                        <%: Html.TextBox("bankName", "", new 
                        {
                            @readonly = "readonly",
                        })%>
                    </ControlPart>
                </ui:InputField>

                <%---------------------------------------------------------------
                    BankCode (Readonly)
                 ----------------------------------------------------------------%>
                <ui:InputField ID="fldBankCode2" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
                <LabelPart><%= this.GetMetadata(".BankCode_Label").SafeHtmlEncode()%></LabelPart>
                <ControlPart>
                        <%: Html.TextBox("bankCode", "", new 
                        {
                            @readonly = "readonly",
        @dir = "ltr"
                        })%>
                    </ControlPart>
                </ui:InputField>

                <%---------------------------------------------------------------
                    BranchAddress (Readonly)
                 ----------------------------------------------------------------%>
                <ui:InputField ID="fldBranchAddress2" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
                <LabelPart><%= this.GetMetadata(".BranchAddress_Label").SafeHtmlEncode()%></LabelPart>
                <ControlPart>
                        <%: Html.TextBox("branchAddress", "", new 
                        {
                            @readonly = "readonly",
                        })%>
                    </ControlPart>
                </ui:InputField>
        
                <%---------------------------------------------------------------
                    BranchCode (Readonly)
                 ----------------------------------------------------------------%>
                <ui:InputField ID="fldBranchCode2" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
                <LabelPart><%= this.GetMetadata(".BranchCode_Label").SafeHtmlEncode()%></LabelPart>
                <ControlPart>
                        <%: Html.TextBox("branchCode", "", new 
                        {
                            @readonly = "readonly",
        @dir = "ltr"
                        })%>
                    </ControlPart>
                </ui:InputField>
        
                <%---------------------------------------------------------------
                    Payee (Readonly)
                 ----------------------------------------------------------------%>
                <ui:InputField ID="fldPayee2" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
                <LabelPart><%= this.GetMetadata(".Payee_Label").SafeHtmlEncode()%></LabelPart>
                <ControlPart>
                        <%: Html.TextBox("payee", "", new 
                        {
                            @readonly = "readonly",
                        })%>
                    </ControlPart>
                </ui:InputField>
                <%---------------------------------------------------------------
                    Payee Address (Readonly)
                 ----------------------------------------------------------------%>
                <ui:InputField ID="fldPayeeAddress2" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
                <LabelPart><%= this.GetMetadata(".PayeeAddress_Label").SafeHtmlEncode()%></LabelPart>
                <ControlPart>
                        <%: Html.TextBox("payeeAddress", "", new 
                        {
                            @readonly = "readonly",
                        })%>
                    </ControlPart>
                </ui:InputField>
        
                <%---------------------------------------------------------------
                    AccountNumber (Readonly)
                 ----------------------------------------------------------------%>
                <ui:InputField ID="fldAccountNumber2" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
                <LabelPart><%= this.GetMetadata(".AccountNumber_Label").SafeHtmlEncode()%></LabelPart>
                <ControlPart>
                        <%: Html.TextBox("accountNumber", "", new 
                        {
                            @readonly = "readonly",
        @dir = "ltr"
                        })%>
                    </ControlPart>
                </ui:InputField>

                <%---------------------------------------------------------------
                    IBAN (Readonly)
                 ----------------------------------------------------------------%>
                <ui:InputField ID="fldIBAN2" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
                <LabelPart><%= this.GetMetadata(".IBAN_Label").SafeHtmlEncode()%></LabelPart>
                <ControlPart>
                        <%: Html.TextBox("iban", "", new 
                        {
                            @readonly = "readonly",
        @dir = "ltr"
                        })%>
                    </ControlPart>
                    <HintPart>
                    </HintPart>
                </ui:InputField>
        

                <%---------------------------------------------------------------
                    SWIFT (Readonly)
                 ----------------------------------------------------------------%>
                <ui:InputField ID="fldSWIFT2" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
                <LabelPart><%= this.GetMetadata(".SWIFT_Label").SafeHtmlEncode()%></LabelPart>
                <ControlPart>
                        <%: Html.TextBox("swift", "", new 
                        {
                            @readonly = "readonly",
        @dir = "ltr"
                        })%>
                    </ControlPart>
                </ui:InputField>

                <%---------------------------------------------------------------
                    Personal ID Number (Readonly)
                 ----------------------------------------------------------------%>
                <ui:InputField ID="fldPersonalIDNumber2" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
                <LabelPart><%= this.GetMetadata(".PersonalIDNumber_Label").SafeHtmlEncode()%></LabelPart>
                <ControlPart>
                        <%: Html.TextBox("additionalInformation", "", new 
                        {
                            @readonly = "readonly",
        @dir = "ltr"
                        })%>
                    </ControlPart>
                </ui:InputField>


                <%---------------------------------------------------------------
                    Currency (Readonly)
                 ----------------------------------------------------------------%>
                <ui:InputField ID="fldCurrency2" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
                <LabelPart><%= this.GetMetadata(".Currency_Label").SafeHtmlEncode()%></LabelPart>
                <ControlPart>
                        <%: Html.TextBox("currency", "", new 
                        {
                            @readonly = "readonly",
        @dir = "ltr"
                        })%>
                    </ControlPart>
                    <HintPart>
                    </HintPart>
                </ui:InputField>
                <center>
                    <br />
                    <%: Html.Button(this.GetMetadata(".Button_Back"), new { @id = "btnWithdrawBack", @type = "button", @class="BackButton button", @onclick = string.Format("$(this).toggleLoadingSpin(true);self.location='{0}';return false;", this.Url.RouteUrl("Withdraw", new { @action = "Index" }).SafeJavascriptStringEncode()) })%>
                    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnWithdrawWithExistingCard", @class="ContinueButton button" })%>
                </center>
            </form>

        </ui:Panel>


        <%---------------------------------------------------------------
            Register a bank
         ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabRegister" Selected="true" Caption="<%$ Metadata:value(.Tabs_RegisterPayCard) %>">

        
        
        <form id="formRegisterPayCard" method="post" action="<%= this.Url.RouteUrl("Withdraw", new { @action = "RegisterBankPayCard" }).SafeHtmlEncode() %>" enctype="application/x-www-form-urlencoded">

        <%: Html.Hidden( "vendorID", "") %>

        <%---------------------------------------------------------------
            Country
         ----------------------------------------------------------------%>
        <ui:InputField ID="fldBankCountry" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata(".BankCountry_Label").SafeHtmlEncode()%></LabelPart>
        <ControlPart>
                <%: Html.DropDownList( "countryID", GetCountryList(), new { @id = "ddlBankCountry" }) %>
            </ControlPart>
        </ui:InputField>

        

        <%---------------------------------------------------------------
            BankName
         ----------------------------------------------------------------%>
        <ui:InputField ID="fldBankName" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata(".BankName_Label").SafeHtmlEncode()%></LabelPart>
        <ControlPart>
                <%: Html.TextBox("bankName", "", new 
                {
                    @validator = ClientValidators.Create()
                        .RequiredIf("isBankNameRequired", this.GetMetadata(".BankName_Empty"))
                        .Custom("validateBankName"),
                })%>
            </ControlPart>
        </ui:InputField>
        <script language="javascript" type="text/javascript">
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
        <ui:InputField ID="fldBankCode" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata(".BankCode_Label").SafeHtmlEncode()%></LabelPart>
        <ControlPart>
                <%: Html.TextBox("bankCode", "", new 
                {
                    @dir = "ltr",
                    @validator = ClientValidators.Create()
                        .RequiredIf("isBankCodeRequired", this.GetMetadata(".BankCode_Empty"))
                        .Custom("validateBankCode"),
                })%>
            </ControlPart>
        </ui:InputField>
        <script language="javascript" type="text/javascript">
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
        <ui:InputField ID="fldBranchAddress" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata(".BranchAddress_Label").SafeHtmlEncode()%></LabelPart>
        <ControlPart>
                <%: Html.TextBox("branchAddress", "", new 
                {
                    @validator = ClientValidators.Create()
                        .RequiredIf("isBranchAddressRequired", this.GetMetadata(".BranchAddress_Empty"))
                        .Custom("validateBranchAddress"),
                })%>
            </ControlPart>
        </ui:InputField>
        <script language="javascript" type="text/javascript">
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
        <ui:InputField ID="fldBranchCode" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata(".BranchCode_Label").SafeHtmlEncode()%></LabelPart>
        <ControlPart>
                <%: Html.TextBox("branchCode", "", new 
                {
                    @dir = "ltr",
                    @validator = ClientValidators.Create()
                        .RequiredIf("isBranchCodeRequired", this.GetMetadata(".BranchCode_Empty"))
                        .Custom("validateBranchCode"),
                })%>
            </ControlPart>
        </ui:InputField>
        <script language="javascript" type="text/javascript">
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
        <ui:InputField ID="fldPayee" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata(".Payee_Label").SafeHtmlEncode()%></LabelPart>
        <ControlPart>
                <%: Html.TextBox("payee", "", new 
                {
                    @validator = ClientValidators.Create()
                        .RequiredIf("isPayeeRequired", this.GetMetadata(".Payee_Empty"))
                        .Custom("validatePayee"),
                })%>
            </ControlPart>
        </ui:InputField>
        <script language="javascript" type="text/javascript">
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
        <ui:InputField ID="fldPayeeAddress" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata(".PayeeAddress_Label").SafeHtmlEncode()%></LabelPart>
        <ControlPart>
                <%: Html.TextBox("payeeAddress", "", new 
                {
                    @validator = ClientValidators.Create()
                        .RequiredIf("isPayeeAddressRequired", this.GetMetadata(".PayeeAddress_Empty"))
                        .Custom("validatePayeeAddress"),
                })%>
            </ControlPart>
        </ui:InputField>
        <script language="javascript" type="text/javascript">
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
        <ui:InputField ID="fldAccountNumber" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata(".AccountNumber_Label").SafeHtmlEncode()%></LabelPart>
        <ControlPart>
                <%: Html.TextBox("accountNumber", "", new 
                {
                    @dir = "ltr",
                    @validator = ClientValidators.Create()
                        .RequiredIf("isAccountNumberRequired", this.GetMetadata(".AccountNumber_Empty"))
                        .Custom("validateAccountNumber"),
                })%>
            </ControlPart>
        </ui:InputField>
        <script language="javascript" type="text/javascript">
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
        <ui:InputField ID="fldIBAN" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata(".IBAN_Label").SafeHtmlEncode()%></LabelPart>
        <ControlPart>
                <%: Html.TextBox("iban", "", new 
                {
                    @dir = "ltr",
                    @validator = ClientValidators.Create()
                        .RequiredIf("isIBANRequired", this.GetMetadata(".IBAN_Empty"))
                        .Custom("validateIBAN"),
                })%>
            </ControlPart>
            <HintPart>
            </HintPart>
        </ui:InputField>
        <script language="javascript" type="text/javascript">
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
        <ui:InputField ID="fldSWIFT" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata(".SWIFT_Label").SafeHtmlEncode()%></LabelPart>
        <ControlPart>
                <%: Html.TextBox("swift", "", new 
                {
                    @dir = "ltr",
                    @validator = ClientValidators.Create()
                        .RequiredIf("isSWIFTRequired", this.GetMetadata(".SWIFT_Empty"))
                        .Custom("validateSWIFT"),
                })%>
            </ControlPart>
        </ui:InputField>
        <script language="javascript" type="text/javascript">
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
        <ui:InputField ID="fldCheckDigits" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata(".CheckDigits_Label").SafeHtmlEncode()%></LabelPart>
        <ControlPart>
                <%: Html.TextBox("checkDigits", "", new 
                {
                    @dir = "ltr",
                    @validator = ClientValidators.Create()
                        .RequiredIf("isCheckDigitsRequired", this.GetMetadata(".CheckDigits_Empty"))
                        .Custom("validateCheckDigits"),
                })%>
            </ControlPart>
        </ui:InputField>
        <script language="javascript" type="text/javascript">
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
        <ui:InputField ID="fldPersonalIDNumber" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata(".PersonalIDNumber_Label").SafeHtmlEncode()%></LabelPart>
        <ControlPart>
                <%: Html.TextBox("additionalInformation", "", new 
                {
                    @dir = "ltr",
                    @validator = ClientValidators.Create()
                        .RequiredIf("isPersonalIDNumberRequired", this.GetMetadata(".PersonalIDNumber_Empty"))
                        .Custom("validatePersonalIDNumber"),
                })%>
            </ControlPart>
        </ui:InputField>
        <script language="javascript" type="text/javascript">
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
            Currency
         ----------------------------------------------------------------%>
        <ui:InputField ID="fldPayCardCurrency" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata(".Currency_Label").SafeHtmlEncode()%></LabelPart>
        <ControlPart>
                <%: Html.DropDownList("currency", new List<SelectListItem>())%>
            </ControlPart>
        </ui:InputField>

        <%: Html.WarningMessage(this.GetMetadata(".Turkey_Bank_Warning"), false, new { @id = "msgTurkeyWarning", @style = "display:none" })%>


        <center>
            <br />
            <%: Html.Button(this.GetMetadata(".Button_Back"), new { @id = "btnWithdrawBack", @type = "button", @class="BackButton button", @onclick = string.Format("$(this).toggleLoadingSpin(true);self.location='{0}';return false;", this.Url.RouteUrl("Withdraw", new { @action = "Index" }).SafeJavascriptStringEncode()) })%>
            <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id = "btnRegisterCardAndWithdraw", @class="ContinueButton button" })%>
        </center>

        </form>

        </ui:Panel>

    </Tabs>
</ui:TabbedContent>


<% Html.RenderPartial("BankPayCardScript"); %>