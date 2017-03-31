<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>


<script language="C#" type="text/C#" runat="server">
    private List<EnterCashRequestBankInfo> _EnterCashBankInfos = null;
    private List<EnterCashRequestBankInfo> EnterCashBankInfos
    {
        get {
            if (_EnterCashBankInfos == null)
            {
                List<EnterCashRequestBankInfo> list = GamMatrixClient.GetEnterCashBankInfo();
                List<CurrencyData> currencies = GamMatrixClient.GetSupportedCurrencies();
                
                _EnterCashBankInfos = new List<EnterCashRequestBankInfo>();
                                
                foreach (EnterCashRequestBankInfo bankInfo in list)
                { 
                    if(currencies.Exists(c=>c.Code.Equals(bankInfo.Currency, StringComparison.InvariantCultureIgnoreCase)) 
                        && bankInfo.WithdrawalSupport)
                    {
                        _EnterCashBankInfos.Add(bankInfo);
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

        return new SelectList(list
            , "Key"
            , "Value"
            );

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
        tabRegister.Attributes["Caption"] = this.GetMetadata(paymentTitleMetadataPath);
        
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
                <%: Html.DropDownList("bankID2", GetEnterCashBankList(), new { @class = "ddlBankID", @id = "ddlBankID", @onchange = "onBankIDChange()" })%>
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

                for (var i = 0; i < enterCashBank.DomesticWithdrawalInfo.length; i++) {
                    switch (enterCashBank.DomesticWithdrawalInfo[i]) {
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

            setTimeout( function(){ $('#fldBankID #ddlBankID').trigger('change'); }, 1000);
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
                })%>
            </ControlPart>
            <HintPart>
            </HintPart>
        </ui:InputField>

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
                })%>
            </ControlPart>
            <HintPart>
            </HintPart>
        </ui:InputField>

        <%---------------------------------------------------------------
            Clearing number
         ----------------------------------------------------------------%>
        <ui:InputField ID="fldClearningNumber" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	        <LabelPart><%= this.GetMetadata(".ClearingNumber_Label").SafeHtmlEncode()%></LabelPart>
	        <ControlPart>
                <%: Html.TextBox("ClearningNumber", "", new 
                {
                    @dir = "ltr",
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
        <ui:InputField ID="fldAccountNumber" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	        <LabelPart><%= this.GetMetadata(".AccountNumber_Label").SafeHtmlEncode()%></LabelPart>
	        <ControlPart>
                <%: Html.TextBox("accountNumber", "", new 
                {
                    @dir = "ltr",
                    @maxlength = "26",
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
        <ui:InputField ID="fldClearingNumber" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	        <LabelPart><%= this.GetMetadata(".ClearingNumber_Label").SafeHtmlEncode()%></LabelPart>
	        <ControlPart>
                <%: Html.TextBox("clearingNumber", "", new 
                {
                    @dir = "ltr",
                    @maxlength = "26",
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
                
                    //return '<%= this.GetMetadata(".Format_Invalid").SafeJavascriptStringEncode() %>';
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

    $(function () {
        $('#formRegisterEnterCashPayCard').initializeForm();

        $('#btnRegisterCardAndWithdraw').click(function (e) {
            e.preventDefault();

            if (!$('#formRegisterEnterCashPayCard').valid())
                return;

            $(this).toggleLoadingSpin(true);

            var $formPrepareWithdraw = $('#formPrepareWithdraw');
            var $formRegisterEnterCashPayCard = $('#formRegisterEnterCashPayCard');

            $formPrepareWithdraw.append($('<input type="hidden" value="' + $('#formRegisterEnterCashPayCard  input[name="bankID"]').val() + '" name="bankID">'));
            $formPrepareWithdraw.append($('<input type="hidden" value="' + $('#formRegisterEnterCashPayCard  input[name="bic"]').val() + '" name="bic">'));
            $formPrepareWithdraw.append($('<input type="hidden" value="' + $('#formRegisterEnterCashPayCard  input[name="iban"]').val() + '" name="iban">'));
            $formPrepareWithdraw.append($('<input type="hidden" value="' + $('#formRegisterEnterCashPayCard  input[name="clearingNumber"]').val() + '" name="clearingNumber">'));
            $formPrepareWithdraw.append($('<input type="hidden" value="' + $('#formRegisterEnterCashPayCard  input[name="accountNumber"]').val() + '" name="accountNumber">'));
            $formPrepareWithdraw.append($('<input type="hidden" value="' + $('#formRegisterEnterCashPayCard  input[name="beneficiaryName"]').val() + '" name="beneficiaryName">'));
  
            var payCardID = 0;
            tryToSubmitWithdrawInputForm('<%= GetDummyPayCard().ID.ToString() %>', function () {
                $('#btnRegisterCardAndWithdraw').toggleLoadingSpin(false);
            });
        });
    });
//]]>
</script>

<div runat="server" id="divError">
<%: Html.H1("")%>
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
