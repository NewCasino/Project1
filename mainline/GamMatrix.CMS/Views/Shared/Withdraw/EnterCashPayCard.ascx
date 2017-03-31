<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Runtime.Serialization.Formatters.Binary" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>

<script language="C#" type="text/C#" runat="server">
    private List<EnterCashRequestBankInfo> _EnterCashBankInfos = null;
    private List<EnterCashRequestBankInfo> EnterCashBankInfos
    {
        get {
            if (_EnterCashBankInfos == null)
            {
                UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
                cmUser user = ua.GetByID(Profile.UserID);
                if (string.IsNullOrEmpty(user.MobilePrefix))
                    return new List<EnterCashRequestBankInfo>();
                
                List<EnterCashRequestBankInfo> list = GamMatrixClient.GetEnterCashBankInfo();
                List<CurrencyData> currencies = GamMatrixClient.GetSupportedCurrencies();
                //CountryInfo country = CountryManager.GetAllCountries().FirstOrDefault(c => c.PhoneCode.Equals(user.MobilePrefix, StringComparison.InvariantCultureIgnoreCase));
                CountryInfo country = CountryManager.GetAllCountries().FirstOrDefault(c => c.InternalID == Profile.UserCountryID);
                _EnterCashBankInfos = new List<EnterCashRequestBankInfo>();
                                
                foreach (EnterCashRequestBankInfo bankInfo in list)
                { 
                    if(bankInfo.WithdrawalSupport 
                        && currencies.Exists(c=>c.Code.Equals(bankInfo.Currency, StringComparison.InvariantCultureIgnoreCase))
                        && bankInfo.ClearingHouse.Equals(country.ISO_3166_Alpha2Code, StringComparison.InvariantCultureIgnoreCase))
                    {
                        _EnterCashBankInfos.Add(bankInfo);
                    }
                }

                if (_EnterCashBankInfos.Count > 0)
                {
                    // Finland - 79 FI & Sweden - 211 SE 
                    if (Profile.UserCountryID == 79)
                    {
                        BinaryFormatter bf = new BinaryFormatter();
                        MemoryStream ms = new MemoryStream();

                        bf.Serialize(ms, _EnterCashBankInfos[0]);
                        ms.Seek(0, SeekOrigin.Begin);
                        EnterCashRequestBankInfo othersBank = bf.Deserialize(ms) as EnterCashRequestBankInfo;
                        othersBank.Name = this.GetMetadata(".OtherBanks");
                        _EnterCashBankInfos.Insert(0, othersBank);
                    }
                    else if (Profile.UserCountryID == 211)
                    {
                        _EnterCashBankInfos[0].Name = this.GetMetadata(".AllSwedishBanks");
                    }
                }
            }

            return _EnterCashBankInfos;
        }
    }

    private PayCardInfoRec GetDummyPayCard()
    {
        PayCardInfoRec payCard = GamMatrixClient.GetPayCards(GamMatrixAPI.VendorID.EnterCash)
            .Where(p => p.IsDummy)
            .FirstOrDefault();
        if (payCard == null)
            throw new Exception("EnterCash is not configrured in GmCore correctly, missing dummy pay card.");
        return payCard;
    }


    private SelectList GetEnterCashBankList()
    {

        var list = EnterCashBankInfos.Select(b => new { Key = b.Id, Value = string.Format("{0} - {1}", b.Name, b.ClearingHouse) }).ToList();

        CountryInfo country = CountryManager.GetAllCountries().FirstOrDefault(c => c.InternalID == Profile.UserCountryID);

        string selectedValue = null;
        if (EnterCashBankInfos.Exists(b => b.ClearingHouse.Equals(country.ISO_3166_Alpha2Code, StringComparison.InvariantCultureIgnoreCase)))
        {
            selectedValue = EnterCashBankInfos.FirstOrDefault(b => b.ClearingHouse.Equals(country.ISO_3166_Alpha2Code, StringComparison.InvariantCultureIgnoreCase)).Id.ToString();
        }

        return new SelectList(list, "Key", "Value", selectedValue);

    }

    private string GetEnterCashBankInfoJson()
    {
        StringBuilder json = new StringBuilder();

        var countries = CountryManager.GetAllCountries();
        
        json.AppendLine("var enterCashBankInfos = {");
        foreach (EnterCashRequestBankInfo bank in EnterCashBankInfos)
        {
            var country = countries.FirstOrDefault(p => p.ISO_3166_Alpha2Code.Equals(bank.ClearingHouse, StringComparison.InvariantCultureIgnoreCase));
            
            json.AppendFormat(CultureInfo.InvariantCulture, "'{0}':{{Currency:'{1}', CountryCode:'{2}', PhoneCode:'{3}'"
                , bank.Id
                , bank.Currency.SafeJavascriptStringEncode()
                , bank.ClearingHouse.SafeJavascriptStringEncode()
                , country.PhoneCode
                );

            if (bank.DomesticWithdrawalInfo.Count > 0)
            {
                json.Append(", DomesticWithdrawalInfo: [");
                foreach (string infoName in bank.DomesticWithdrawalInfo)
                {
                    json.AppendFormat(CultureInfo.InvariantCulture, " '{0}',", infoName);
                }
                if (json[json.Length - 1] == ',')
                    json.Remove(json.Length - 1, 1);
                json.Append("]");
            }
            if (bank.InternationalWithdrawalInfo.Count > 0)
            {
                json.Append(", InternationalWithdrawalInfo: [");
                foreach (string infoName in bank.DomesticWithdrawalInfo)
                {
                    json.AppendFormat(CultureInfo.InvariantCulture, " '{0}',", infoName);
                }
                if (json[json.Length - 1] == ',')
                    json.Remove(json.Length - 1, 1);
                json.Append("]");
            }
            json.Append("},");
        }
        if (json[json.Length - 1] == ',')
            json.Remove(json.Length - 1, 1);
        json.AppendLine("};");
        return json.ToString();
    }

    private string PaymentUniqueName;
    
    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        
        string paymentTitleMetadataPath = string.Format("/Metadata/PaymentMethod/{0}.Title", this.Model.UniqueName);
        
        if (EnterCashBankInfos.Count == 0)
        {
            divError.Visible = true;
            tabbedPayCards.Visible = false;
            //scriptWithdrawWithEnterCashPayCard.Visible = false;
            return;
        }
        divError.Visible = false;
        tabbedPayCards.Visible = true;
        //scriptWithdrawWithEnterCashPayCard.Visible = true;
        
        PaymentUniqueName = this.Model.UniqueName; 
    }
</script>

<%---------------------------------------------------------------
EnterCash
----------------------------------------------------------------%>
<script type="text/javascript">
<%=GetEnterCashBankInfoJson() %>
</script>
<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <Tabs>
    <%---------------------------------------------------------------
    Recent banks
    ----------------------------------------------------------------%>
    <ui:Panel runat="server" ID="tabRecentCards" Caption="<%$ Metadata:value(.Tab_ExistingPayCards) %>">
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

            
        <%------------------------------------------
            Bank ID
            -------------------------------------------%>
        <ui:InputField ID="fldBankID2" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	        <LabelPart><%= this.GetMetadata(".BankID_Label").SafeHtmlEncode()%></LabelPart>
	        <ControlPart>
                <%: Html.DropDownList("bankID2", GetEnterCashBankList(), new { @class = "ddlBankID", @id = "ddlBankID2", @disabled = "disabled", @onchange = "onBankID2Change()" })%>
                <%-- We need another hide field for the Bank ID 
                because the Bank ID value will not be included in POST request if the dropdownlist is disabled. --%>
                <%: Html.Hidden("bankID")%>
	        </ControlPart>
        </ui:InputField>
        <script type="text/javascript">

            function initFields2(enterCashBank) {
                var $tabRecentCards = $('#tabRecentCards');
                $tabRecentCards.find('.inputfield').hide();
                $tabRecentCards.find('#fldExistingPayCard').show();
                $tabRecentCards.find('#fldBankID2').show();

                var withdrawalInfo = enterCashBank.DomesticWithdrawalInfo;

                for (var i = 0; i < withdrawalInfo.length; i++) {
                    switch (withdrawalInfo[i]) {
                        case "bic":
                            $tabRecentCards.find('#fldBIC2').show();
                            break;
                        case "iban":
                            $tabRecentCards.find('#fldIBAN2').show();
                            break;
                        case "clearing_number":
                            $tabRecentCards.find('#fldClearingNumber2').show();
                            break;
                        case "account_number":
                            $tabRecentCards.find('#fldAccountNumber2').show();
                            break;
                        case "beneficiary_name":
                            $tabRecentCards.find('#fldBeneficiaryName2').show();
                            break;
                        case "beneficiary_address":
                            $tabRecentCards.find('#fldBeneficiaryAddress2').show();
                            break;
                    }
                }
            }

            function onBankID2Change() {
                var bankID = $('#fldBankID2 #ddlBankID2').val();
                var enterCashBank = enterCashBankInfos[bankID];
                $('#fldBankID2 input[name="bankID"]').val(bankID);

                initFields2(enterCashBank);

                $(document).trigger("ENTERCASH_BANK_CHANGED", enterCashBank);
            }
        </script>

        <%---------------------------------------------------------------
            BIC ( 26 Alphanumeric )
         ----------------------------------------------------------------%>
        <ui:InputField ID="fldBIC2" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	        <LabelPart><%= this.GetMetadata(".BIC_Label").SafeHtmlEncode()%></LabelPart>
	        <ControlPart>
                <%: Html.TextBox("bic", "", new 
                {
                    @dir = "ltr",
                    @readonly = "readonly",
                    @maxlength = "26",
                    @validator = ClientValidators.Create()
                        .Required(this.GetMetadata(".BIC_Empty"))
                })%>
            </ControlPart>
            <HintPart>
            </HintPart>
        </ui:InputField>

        <%---------------------------------------------------------------
            IBAN ( 26 Alphanumeric )
            Permitted IBAN characters are the digits 0 to 9 and the 26 upper case Latin alphabetic characters A to Z
         ----------------------------------------------------------------%>
        <ui:InputField ID="fldIBAN2" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	        <LabelPart><%= this.GetMetadata(".IBAN_Label").SafeHtmlEncode()%></LabelPart>
	        <ControlPart>
                <%: Html.TextBox("iban", "", new 
                {
                    @dir = "ltr",
                    @maxlength = "26",
                    @readonly = "readonly",
                    @validator = ClientValidators.Create()
                        .Required(this.GetMetadata(".IBAN_Empty"))
                })%>
            </ControlPart>
            <HintPart>
            </HintPart>
        </ui:InputField>

        <%---------------------------------------------------------------
            Clearing number
         ----------------------------------------------------------------%>
        <ui:InputField ID="fldClearningNumber2" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	        <LabelPart><%= this.GetMetadata(".ClearingNumber_Label").SafeHtmlEncode()%></LabelPart>
	        <ControlPart>
                <%: Html.TextBox("ClearningNumber", "", new 
                {
                    @dir = "ltr",
                    @readonly = "readonly",
                    @maxlength = "26",
                    @validator = ClientValidators.Create()
                        .Required(this.GetMetadata(".ClearningNumber_Empty"))
                })%>
            </ControlPart>
            <HintPart>
            </HintPart>
        </ui:InputField>

        <%---------------------------------------------------------------
            Account number
         ----------------------------------------------------------------%>
        <ui:InputField ID="fldAccountNumber2" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	        <LabelPart><%= this.GetMetadata(".AccountNumber_Label").SafeHtmlEncode()%></LabelPart>
	        <ControlPart>
                <%: Html.TextBox("AccountNumber", "", new 
                {
                    @dir = "ltr",
                    @maxlength = "26",
                    @readonly = "readonly",
                    @validator = ClientValidators.Create()
                        .Required(this.GetMetadata(".AccountNumber_Empty"))
                })%>
            </ControlPart>
            <HintPart>
            </HintPart>
        </ui:InputField>

        <%---------------------------------------------------------------
            Clearing number
         ----------------------------------------------------------------%>
        <ui:InputField ID="fldClearingNumber2" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	        <LabelPart><%= this.GetMetadata(".ClearingNumber_Label").SafeHtmlEncode()%></LabelPart>
	        <ControlPart>
                <%: Html.TextBox("ClearingNumber", "", new 
                {
                    @dir = "ltr",
                    @maxlength = "26",
                    @readonly = "readonly",
                    @validator = ClientValidators.Create()
                        .Required(this.GetMetadata(".ClearingNumber_Empty"))
                })%>
            </ControlPart>
            <HintPart>
            </HintPart>
        </ui:InputField>

        <%---------------------------------------------------------------
            beneficiary name
         ----------------------------------------------------------------%>
        <ui:InputField ID="fldBeneficiaryName2" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	        <LabelPart><%= this.GetMetadata(".BeneficiaryName_Label").SafeHtmlEncode()%></LabelPart>
	        <ControlPart>
                <%: Html.TextBox("beneficiaryName", "", new 
                {
                    @readonly = "readonly",
                    @validator = ClientValidators.Create()
                        .Required(this.GetMetadata(".BeneficiaryName_Empty"))
                })%>
            </ControlPart>
        </ui:InputField>
            
            <center>
                <br />
                <%: Html.Button(this.GetMetadata(".Button_Back"), new { @id = "btnWithdrawBack", @type = "button", @onclick = string.Format("$(this).toggleLoadingSpin(true);self.location='{0}';return false;", this.Url.RouteUrl("Withdraw", new { @action = "Index" }).SafeJavascriptStringEncode()) })%>
                <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnWithdrawWithExistingCard" })%>
            </center>
        </form>

    </ui:Panel>

    <%---------------------------------------------------------------
    Register a pay card
    ----------------------------------------------------------------%>
    <ui:Panel runat="server" ID="tabRegister" IsHtmlCaption="true" Selected="true" Caption="<%$ Metadata:value(.Tab_RegisterPayCard) %>">
        <form id="formRegisterEnterCashPayCard" action="<%= this.Url.RouteUrl("Withdraw", new { @action = "RegisterEnterCashPayCard", @vendorID=this.Model.VendorID }).SafeHtmlEncode() %>" method="post" enctype="application/x-www-form-urlencoded">
        <%------------------------------------------
            Bank ID
            -------------------------------------------%>
        <ui:InputField ID="fldBankID" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	        <LabelPart><%= this.GetMetadata(".BankID_Label").SafeHtmlEncode()%></LabelPart>
	        <ControlPart>
                <%: Html.DropDownList("bankID2", GetEnterCashBankList(), new 
                { 
                    @class = "ddlBankID", 
                    @id = "ddlBankID", 
                    @onchange = "onBankIDChange()",
                    @validator = ClientValidators.Create()
                        .Required("Please select your bank")
                })%>
                <%-- We need another hide field for the Bank ID 
                because the Bank ID value will not be included in POST request if the dropdownlist is disabled. --%>
                <%: Html.Hidden("bankID")%>
	        </ControlPart>
        </ui:InputField>
        <script type="text/javascript">
            <%=GetEnterCashBankInfoJson() %>

            function initFields(enterCashBank)
            {     
                var $tabRegister = $('#tabRegister');
                $tabRegister.find('.inputfield').hide();
                $tabRegister.find('#fldBankID').show();

                var withdrawalInfo = enterCashBank.DomesticWithdrawalInfo;

                for (var i = 0; i < withdrawalInfo.length; i++) {
                    switch (withdrawalInfo[i]) {
                        case "bic":
                            $tabRegister.find('#fldBIC').show();
                            break;
                        case "iban":
                            $tabRegister.find('#fldIBAN').show();
                            break;
                        case "clearing_number":
                            $tabRegister.find('#fldClearingNumber').show();
                            break;
                        case "account_number":
                            $tabRegister.find('#fldAccountNumber').show();
                            break;
                        case "beneficiary_name":
                            $tabRegister.find('#fldBeneficiaryName').show();
                            break;
                        case "beneficiary_address":
                            $tabRegister.find('#fldBeneficiaryAddress').show();
                            break;
                    }
                }
            }

            function onBankIDChange() {                
                var bankID = $('#fldBankID #ddlBankID').val();
                var enterCashBank = enterCashBankInfos[bankID];
                $('#fldBankID input[name="bankID"]').val(bankID);
                
                initFields(enterCashBank);

                $(document).trigger("ENTERCASH_BANK_CHANGED", enterCashBank);
            }
        </script>

        <%---------------------------------------------------------------
            BIC ( 26 Alphanumeric )
         ----------------------------------------------------------------%>
        <ui:InputField ID="fldBIC" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	        <LabelPart><%= this.GetMetadata(".BIC_Label").SafeHtmlEncode()%></LabelPart>
	        <ControlPart>
                <%: Html.TextBox("bic", "", new 
                {
                    @dir = "ltr",
                    @maxlength = "26",
                    @validator = ClientValidators.Create()
                        .Required(this.GetMetadata(".BIC_Empty"))
                        .Custom("validateBIC")
                })%>
            </ControlPart>
            <HintPart>
            </HintPart>
        </ui:InputField>
        <script type="text/javascript">
            function validateBIC() {
                var value = this;
                var ret = /^([A-Z]|[0-9]){8,8}$|^([A-Z]|[0-9]){11,11}$/.exec(value);
                if (ret == null || ret.length == 0)
                    return '<%= this.GetMetadata(".BIC_Illegal").SafeJavascriptStringEncode() %>';
                return true;
            }
        </script>

        <%---------------------------------------------------------------
            IBAN ( 26 Alphanumeric )
            Permitted IBAN characters are the digits 0 to 9 and the 26 upper case Latin alphabetic characters A to Z
         ----------------------------------------------------------------%>
        <ui:InputField ID="fldIBAN" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	        <LabelPart><%= this.GetMetadata(".IBAN_Label").SafeHtmlEncode()%></LabelPart>
	        <ControlPart>
                <%: Html.TextBox("iban", "", new 
                {
                    @dir = "ltr",
                    @maxlength = "26",
                    @validator = ClientValidators.Create()
                        .Required(this.GetMetadata(".IBAN_Empty"))
                        .Custom("validateIBAN")
                })%>
            </ControlPart>
            <HintPart>
            </HintPart>
        </ui:InputField>
        <script type="text/javascript">
            function validateIBAN() {
                var value = this;
                var ret = /^FI[\d]{16,16}$/.exec(value);
                if (ret == null || ret.length == 0)
                    return '<%= this.GetMetadata(".IBAN_Illegal").SafeJavascriptStringEncode() %>';
                return true;
            }
        </script>        
        

        <%---------------------------------------------------------------
            Account number
         ----------------------------------------------------------------%>
        <ui:InputField ID="fldAccountNumber" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	        <LabelPart><%= this.GetMetadata(".AccountNumber_Label").SafeHtmlEncode()%></LabelPart>
	        <ControlPart>
                <%: Html.TextBox("AccountNumber", "", new 
                {
                    @dir = "ltr",
                    @maxlength = "26",
                    @validator = ClientValidators.Create()
                        .Required(this.GetMetadata(".AccountNumber_Empty"))
                        .Custom("validateAccountNumber")
                })%>
            </ControlPart>
            <HintPart>
            </HintPart>
        </ui:InputField>
        <script type="text/javascript">
            function validateAccountNumber() {
                var value = this;
                var ret = /^[\d]{1,}$/.exec(value);
                if (ret == null || ret.length == 0)
                    return '<%= this.GetMetadata(".AccountNumber_Illegal").SafeJavascriptStringEncode() %>';
                return true;
            }
        </script>

        <%---------------------------------------------------------------
            Clearing number
         ----------------------------------------------------------------%>
        <ui:InputField ID="fldClearingNumber" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	        <LabelPart><%= this.GetMetadata(".ClearingNumber_Label").SafeHtmlEncode()%></LabelPart>
	        <ControlPart>
                <%: Html.TextBox("ClearingNumber", "", new 
                {
                    @dir = "ltr",
                    @maxlength = "26",
                    @validator = ClientValidators.Create()
                        .Required(this.GetMetadata(".ClearingNumber_Empty"))
                        .Custom("validateClearningNumber")
                })%>
            </ControlPart>
            <HintPart>
            </HintPart>
        </ui:InputField>
        <script type="text/javascript">
            function validateClearningNumber() {
                var value = this;
                var ret = /^[\d]{1,}$/.exec(value);
                if (ret == null || ret.length == 0)
                    return '<%= this.GetMetadata(".ClearingNumber_Illegal").SafeJavascriptStringEncode() %>';
                return true;
            }
        </script>


        <%---------------------------------------------------------------
            beneficiary name
         ----------------------------------------------------------------%>
        <ui:InputField ID="fldBeneficiaryName" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	        <LabelPart><%= this.GetMetadata(".BeneficiaryName_Label").SafeHtmlEncode()%></LabelPart>
	        <ControlPart>
                <%: Html.TextBox("beneficiaryName", "", new 
                {
                    @validator = ClientValidators.Create()
                        .Required(this.GetMetadata(".BeneficiaryName_Empty"))
                        .Custom("validateBeneficiaryName"),
                })%>
            </ControlPart>
        </ui:InputField>
        <script language="javascript" type="text/javascript">
            function validateBeneficiaryName() {
                var value = this;
                return true;
            }
        </script>

        <%---------------------------------------------------------------
            beneficiary name
         ----------------------------------------------------------------%>
        <ui:InputField ID="fldBeneficiaryAddress" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	        <LabelPart><%= this.GetMetadata(".BeneficiaryAddress_Label").SafeHtmlEncode()%></LabelPart>
	        <ControlPart>
                <%: Html.TextBox("beneficiaryAddress", "", new 
                {
                    @validator = ClientValidators.Create()
                        .Required(this.GetMetadata(".BeneficiaryAddress_Empty"))
                        .Custom("validateBeneficiaryAddress"),
                })%>
            </ControlPart>
        </ui:InputField>
        <script language="javascript" type="text/javascript">
            function validateBeneficiaryAddress() {
                var value = this;
                return true;
            }
        </script>

        <center>
            <br />
            <%: Html.Button(this.GetMetadata(".Button_Back"), new { @id = "btnWithdrawBack", @type = "button", @onclick = string.Format("$(this).toggleLoadingSpin(true);self.location='{0}';return false;", this.Url.RouteUrl("Withdraw", new { @action = "Index" }).SafeJavascriptStringEncode()) })%>
            <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id = "btnRegisterCardAndWithdraw" })%>
        </center>

        </form>
    </ui:Panel>
    </Tabs>
</ui:TabbedContent>

<script type="text/javascript">
    //<![CDATA[

    function __populatePayCards(json) {
        if (!json.success) {
            showWithdrawError(json.error);
            return;
        }

        $('#paycards-selector').data('payCards', json.payCards);
        $('#paycards-selector').html($('#pay-card-template').parseTemplate(json.payCards));
        $('#paycards-selector input[name="existingPayCard"]').click(function () {
            $('#hExistingPayCardID').val($(this).val());
            InputFields.fields['fldExistingPayCard'].validator.element($('#hExistingPayCardID'));
            var parCards = $('#paycards-selector').data('payCards');
            for (var i = 0; i < parCards.length; i++) {
                if (parCards[i].ID == $(this).val()) {
                    $('#fldBIC2').css('display', (parCards[i].BIC.length > 0) ? '' : 'none');
                    $('#fldIBAN2').css('display', (parCards[i].IBAN.length > 0) ? '' : 'none');
                    $('#fldClearingNumber2').css('display', (parCards[i].ClearingNumber.length > 0) ? '' : 'none');
                    $('#fldAccountNumber2').css('display', (parCards[i].AccountNumber.length > 0) ? '' : 'none');
                    $('#fldBeneficiaryName2').css('display', (parCards[i].BeneficiaryName.length > 0) ? '' : 'none');
                    $('#fldBeneficiaryAddress2').css('display', (parCards[i].BeneficiaryAddress.length > 0) ? '' : 'none');

                    $('#fldBankID2 #ddlBankID2').val(parCards[i].BankID);

                    $('#fldBIC2 input[type="text"]').val(parCards[i].BIC);
                    $('#fldIBAN2 input[type="text"]').val(parCards[i].IBAN);
                    $('#fldClearingNumber2 input[type="text"]').val(parCards[i].ClearingNumber);
                    $('#fldAccountNumber2 input[type="text"]').val(parCards[i].AccountNumber);
                    $('#fldBeneficiaryName2 input[type="text"]').val(parCards[i].BeneficiaryName);
                    $('#fldBeneficiaryAddress2 input[type="text"]').val(parCards[i].BeneficiaryAddress);
                    //$('#fldCurrency2 input[type="text"]').val(parCards[i].Currency);
                }
            }
        });

        // <%-- if more than one pay card, select the first one tab and first pay card --%>
        if (json.payCards.length > 0) {
            $('#tabbedPayCards').showTab('tabRecentCards', true);
            $('#tabbedPayCards').selectTab('tabRecentCards');

            // <%-- if more than 3 cards, hide the registration tab --%>
            if (json.payCards.length >= <%=this.GetMetadata("/Metadata/Settings.max_withdraw_registered_accounts").SafeHtmlEncode() %>) {
                $('#tabbedPayCards').showTab('tabRegister', false);
            }

            // <%-- select the paycard --%>
            var payCardID = $('#paycards-selector').data('payCardID');
            var $input = $('#paycards-selector input[value="' + payCardID + '"]');
            if ($input.length > 0) {
                $input.attr('checked', true).trigger('click');
                $('#tabbedPayCards').selectTab('tabRecentCards');
            }

            if ($('#paycards-selector :checked').length == 0)
                $('#paycards-selector input:first').trigger('click');
        } else { // <%-- hide the recent cards tab and select register tab --%>
            $('#tabbedPayCards').selectTab('tabRegister');
            $('#tabbedPayCards').showTab('tabRegister', true);
            $('#tabbedPayCards').showTab('tabRecentCards', false);
        }

        AdjustCurrency();
    };

    function __loadRecentPayCards(payCardID) {
        $('#paycards-selector').data('payCardID', payCardID);
        var url = '<%= this.Url.RouteUrl( "Withdraw", new { @action="GetEnterCashPayCards" }).SafeJavascriptStringEncode() %>';
        jQuery.getJSON(url, null, __populatePayCards);
    }

    function AdjustCurrency()
    {
        if ($('#tabRecentCards').is(':visible')) {
            $('#fldBankID2 #ddlBankID2').trigger('change');
            console.log(' triggered by recent cards');
        }
        else if ($('#tabRegister').is(':visible')) {
            $('#fldBankID #ddlBankID').trigger('change');
            console.log(' triggered by register cards');
        }
    }

    AdjustCurrency();

    $(function () {
        $('#formRegisterEnterCashPayCard').initializeForm();
        $('#formRecentCards').initializeForm();        
        __populatePayCards(<% Html.RenderAction("GetEnterCashPayCards");%>);

        $('#tabbedPayCards').find('a[href="#tabRecentCards"]').click(function(){
            AdjustCurrency();
        });
        $('#tabbedPayCards').find('a[href="#tabRegister"]').click(function(){
            AdjustCurrency();
        });

        $('#btnRegisterCardAndWithdraw').click(function (e) {
            e.preventDefault();

            if (!$('#formRegisterEnterCashPayCard').valid() )
                return;

            $(this).toggleLoadingSpin(true);

            var options = {
                dataType: "json",
                type: 'POST',
                success: function (json) {
                    // <%-- the card is successfully registered, now prepare the transaction --%>
                    if (!json.success) {
                        $('#btnRegisterCardAndWithdraw').toggleLoadingSpin(false);
                        showWithdrawError(json.error);
                        return;
                    }
                    __loadRecentPayCards(json.payCardID);
                    // <%-- post the prepare form --%>   
                    tryToSubmitWithdrawInputForm(json.payCardID, function () {
                        $('#btnRegisterCardAndWithdraw').toggleLoadingSpin(false);
                    });
                },
                error: function (xhr, textStatus, errorThrown) {
                    $('#btnRegisterCardAndWithdraw').toggleLoadingSpin(false);
                    showWithdrawError(errorThrown);
                }
            };
            $('#formRegisterEnterCashPayCard').ajaxForm(options);
            $('#formRegisterEnterCashPayCard').submit();
        });

        $('#btnWithdrawWithExistingCard').click(function (e) {
            e.preventDefault();

            if ( !$('#formRecentCards').valid() )
                return;

            $(this).toggleLoadingSpin(true);

            var payCardID = $('#hExistingPayCardID').val();
            tryToSubmitWithdrawInputForm(payCardID, function () {
                $('#btnWithdrawWithExistingCard').toggleLoadingSpin(false);
            });
        });
 
    });

    function DisableSpaceAndPunctuation(e) {
        var keyCode = 0;
        if ($('html').hasClass('firefox'))
            keyCode = e.charCode;
        else
            keyCode = e.keyCode;
        switch (keyCode) {
            case 32: case 33: case 34: case 35: case 36: case 37: case 38: case 39: case 40:
            case 41: case 42: case 43: case 44: case 45: case 46: case 47: case 58: case 59:
            case 60: case 61: case 62: case 63: case 64: case 91: case 92: case 93: case 94:
            case 95: case 96: case 123: case 124: case 125: case 126:
                e.preventDefault();
                break;
            default:
                break;

        }
    }

    $('#formRegisterEnterCashPayCard #AccountNumber, #formRegisterEnterCashPayCard #ClearingNumber').keypress(function (e) {
        DisableSpaceAndPunctuation(e);
    });
    $('#formRegisterEnterCashPayCard #AccountNumber, #formRegisterEnterCashPayCard #ClearingNumber').change(function (e) {
        DisableSpaceAndPunctuation(e);
    });

//]]>
</script>

<div runat="server" id="divError">
<ui:Panel runat="server" ID="pnError">
<%: Html.WarningMessage(this.GetMetadata(".NoAvailableBank")) %>

<center>
    <%: Html.Button(this.GetMetadata(".Button_Back"), new { @id = "btnBackFromDepositWithEnterCashPayCard", @onclick = "backToDepositIndexPage(); return false;" })%>
</center>
<script type="text/javascript">
    function backToDepositIndexPage() {
        window.location = '<%= this.Url.RouteUrl("Deposit").SafeJavascriptStringEncode() %>';
        return false;
    }
</script>
</ui:Panel>
</div>
