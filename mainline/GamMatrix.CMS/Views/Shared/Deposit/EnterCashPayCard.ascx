<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Runtime.Serialization.Formatters.Binary" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>

<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>

<script language="C#" type="text/C#" runat="server">
    private string depositTypeCode = string.Empty;
    
    private List<EnterCashRequestBankInfo> _EnterCashBankInfos = null;
    private List<EnterCashRequestBankInfo> EnterCashBankInfos
    {
        get {
            if (_EnterCashBankInfos == null)
            {
                bool isBank = false;
                
                depositTypeCode = this.Model.SubCode;
                switch (depositTypeCode)
                {
                    case "ONLINEBANK": // Finland - 79 FI & Sweden - 211 SE 
                        isBank = true;
                        if (Profile.UserCountryID == 79)
                        {
                            depositTypeCode = "BANK_BUTTON";
                            
                        }
                        else if (Profile.UserCountryID == 211)
                            depositTypeCode = "BANK_REFCODE";
                        break;
                    case "WYWALLET":
                    case "SIRU":
                        break;
                    default:
                        depositTypeCode = string.Empty;
                        break;
                }
                if (string.IsNullOrWhiteSpace(depositTypeCode))
                    return new List<EnterCashRequestBankInfo>();

                List<EnterCashRequestBankInfo> list = GamMatrixClient.GetEnterCashBankInfo();
                if (depositTypeCode.Equals("BANK_BUTTON", StringComparison.InvariantCultureIgnoreCase))
                    list.RemoveAll(b => !b.ButtonDepositSupport);

                if (depositTypeCode.Equals("BANK_REFCODE", StringComparison.InvariantCultureIgnoreCase))
                    list.RemoveAll(b => !b.ClearingHouse.Equals("SE", StringComparison.InvariantCultureIgnoreCase));
                
                List<CurrencyData> currencies = GamMatrixClient.GetSupportedCurrencies();
                CountryInfo mobilePrefixCountry = CountryManager.GetAllCountries().FirstOrDefault(c => c.PhoneCode.Equals(UserMobilePrefix, StringComparison.InvariantCultureIgnoreCase));

                if (currencies == null || mobilePrefixCountry == null)
                    return new List<EnterCashRequestBankInfo>();
                
                _EnterCashBankInfos = new List<EnterCashRequestBankInfo>();
                                
                foreach (EnterCashRequestBankInfo bankInfo in list)
                { 
                    if(currencies.Exists(c=>c.Code.Equals(bankInfo.Currency, StringComparison.InvariantCultureIgnoreCase)) 
                        && bankInfo.DepositTypes.Exists(t => t.Equals(depositTypeCode, StringComparison.InvariantCultureIgnoreCase))
                        && bankInfo.DepositSupport)
                    {
                        if (this.Model.UniqueName.Equals("EnterCash_Siru", StringComparison.InvariantCultureIgnoreCase))
                        {
                            if (bankInfo.ClearingHouse.Equals("INTERNATIONAL", StringComparison.InvariantCultureIgnoreCase)
                                || mobilePrefixCountry.ISO_3166_Alpha2Code.Equals(bankInfo.ClearingHouse, StringComparison.InvariantCultureIgnoreCase))
                            {
                                _EnterCashBankInfos.Add(bankInfo);
                            }
                        }
                        else
                        {
                            _EnterCashBankInfos.Add(bankInfo);
                        }
                    }
                }
            }

            return _EnterCashBankInfos;
        }
    }
    
    private SelectList GetPhonePrefixList()
    {
        var list = CountryManager.GetAllPhonePrefix().Select(p => new { Key = p, Value = p }).ToList();
        list.Insert(0, new { Key = string.Empty, Value = this.GetMetadata(".PhonePrefix_Select") });
        
        return new SelectList(list, "Key", "Value");
    }

    private PayCardInfoRec DummyPayCard { get; set; }
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
        json.AppendLine("var enterCashBankInfos = {");
        
        var countries = CountryManager.GetAllCountries();
                    
        foreach (EnterCashRequestBankInfo bank in EnterCashBankInfos)
        {
            var country = countries.FirstOrDefault(p=>p.ISO_3166_Alpha2Code.Equals(bank.ClearingHouse, StringComparison.InvariantCultureIgnoreCase));

            json.AppendFormat(CultureInfo.InvariantCulture, "'{0}':{{Currency:'{1}', CountryCode:'{2}', PhoneCode:'{3}', DepositAmounts:[{4}]}},"
                , bank.Id
                , bank.Currency.SafeJavascriptStringEncode()
                , bank.ClearingHouse.SafeJavascriptStringEncode()
                , country.PhoneCode
                , bank.DepositAmounts== null ? "" : bank.DepositAmounts.ConvertToCommaSplitedString()
                );
        }
        if (json[json.Length - 1] == ',')
            json.Remove(json.Length - 1, 1);
        json.AppendLine("};");
        return json.ToString();
    }

    private string PaymentTitle;
    private string PaymentUniqueName;
    private string UserMobilePrefix = "";
    private string UserMobile = "";
    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        
        string paymentTitleMetadataPath = string.Format("/Metadata/PaymentMethod/{0}.Title", this.Model.UniqueName);
        PaymentTitle = this.GetMetadata(paymentTitleMetadataPath);

        UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
        cmUser user = ua.GetByID(Profile.UserID);
        if (!string.IsNullOrWhiteSpace(user.MobilePrefix))
            UserMobilePrefix = user.MobilePrefix;
        if (!string.IsNullOrWhiteSpace(user.Mobile))
            UserMobile = user.Mobile;
        
        if (EnterCashBankInfos.Count == 0)
        {
            divError.Visible = true;
            tabbedPayCards.Visible = false;
            scriptDepositWithEnterCashPayCard.Visible = false;
            return;
        }

        DummyPayCard = GetDummyPayCard();
        
        divError.Visible = false;
        tabbedPayCards.Visible = true;
        scriptDepositWithEnterCashPayCard.Visible = true;
        
        PaymentUniqueName = this.Model.UniqueName;

        tabRecentCards.Attributes["Caption"] = PaymentTitle;

        fldVerificationCodeForView.Visible = false;
        
        if (this.Model.UniqueName.Equals("EnterCash_WyWallet", StringComparison.InvariantCultureIgnoreCase))
        {
            fldVerificationCode.Visible = true;
            fldPhoneNumber.Visible = true;
            
            scriptPhoneNumber.Visible = true;
            
            if (!string.IsNullOrEmpty(DummyPayCard.BankCode))
            {
                fldVerificationCodeForView.Visible = true;
            }
        }
        else
        {
            fldVerificationCode.Visible = false;
            fldPhoneNumber.Visible = false;
            scriptPhoneNumber.Visible = false;
        }
    }
</script>


<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <Tabs>
        <%---------------------------------------------------------------
            EnterCash
         ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabRecentCards" IsHtmlCaption="true" Selected="true">
            <form id="formEnterCashPayCard" action="<%= this.Url.RouteUrl("Deposit", new { @action = "SaveEnterCash", @vendorID=this.Model.VendorID }).SafeHtmlEncode() %>" method="post" enctype="application/x-www-form-urlencoded">
                <%: Html.Hidden( "sid", "") %>
                <%: Html.Hidden("paymentName", PaymentUniqueName)%>
                <%: Html.Hidden("paymentType", depositTypeCode)%>
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

                    function onBankIDChange() {
                        var bankID = $('#fldBankID #ddlBankID').val();
                        var enterCashBank = enterCashBankInfos[bankID];
                        $('#fldBankID input[name="bankID"]').val(bankID);

                        if(enterCashBank.DepositAmounts != null && enterCashBank.DepositAmounts.length > 0)
                        {
                            var $amountContainer = $('#fldCurrencyAmount #txtAmount').parent();
                            if($amountContainer.find('#ddlEnterCashAmount').length == 0)
                            {
                                $amountContainer.append($('<select onchange="onEnterCashAmountChange()" name="enterCashAmount" id="ddlEnterCashAmount" class="ddlAmount select"></select>'));
                            }
                            var $ddlEnterCashAmount = $amountContainer.find('#ddlEnterCashAmount');
                            if(bankID != ($ddlEnterCashAmount.data('bankID') || $ddlEnterCashAmount.attr('data-bankID')))
                            {
                                $ddlEnterCashAmount.data('bankID', bankID);
                                $ddlEnterCashAmount.empty();
                                for(var i = 0; i < enterCashBank.DepositAmounts.length; i++)
                                {
                                    $ddlEnterCashAmount.append($('<option value="{0}">{0}</option>'.format(enterCashBank.DepositAmounts[i])));
                                }
                            }
                            setTimeout( function(){ $('#fldCurrencyAmount #ddlEnterCashAmount').trigger('change'); }, 500);
                            $('#fldCurrencyAmount #txtAmount').hide();
                            $ddlEnterCashAmount.show();
                        }
                        else
                        {
                            $('#fldCurrencyAmount #txtAmount').show();
                            if($ddlEnterCashAmount!=null && $ddlEnterCashAmount.length>0)
                                $ddlEnterCashAmount.hide();
                        }

                        $(document).trigger("ENTERCASH_BANK_CHANGED", enterCashBank);
                    }

                    function onEnterCashAmountChange()
                    {
                        $('#fldCurrencyAmount #txtAmount').val($('#fldCurrencyAmount #ddlEnterCashAmount').val());
                    }

                    $(function(){
                        setTimeout( function(){ $('#fldBankID #ddlBankID').trigger('change'); }, 1000);                        
                    });
                </script>
                
                <ui:InputField ID="fldVerificationCodeForView" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
                <LabelPart><%= this.GetMetadata(".VerificationCode_Label").SafeHtmlEncode()%></LabelPart>
                <ControlPart>
                <%: Html.TextBox("verificationCode", DummyPayCard.BankCode, new 
                            {
                                @disabled = "disabled",
                                @readonly = "readonly",
                            })
                %>
                <%: Html.Button("Change code", new { @id = "btnChangeVerificationCode"})%>
                </ControlPart>
                </ui:InputField>
                
                <%------------------------
                    Phone Number
                -------------------------%>    
                <ui:InputField ID="fldPhoneNumber" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	                <LabelPart><%= this.GetMetadata(".SendVerificationCode_Label").SafeHtmlEncode()%></LabelPart>
	                <ControlPart>
                        <span id="spMessgaeMobiledonotSupport" class="messgae-mobiledonot-support"><%= this.GetMetadata(".Message_MobileDonotSupport").SafeHtmlEncode()%></span>
                        <%: Html.TextBox("mobile", string.Format("{0}-{1}", UserMobilePrefix, UserMobile), new { @id = "txtMobile", @readonly = "readonly" })%>                        
                        <%: Html.DropDownList("newMobilePrefix", GetPhonePrefixList(), new { @id = "ddlNewMobilePrefix", @class = "ddlPhonePrefix", @style = "display:none" })%>
                        <%: Html.TextBox("newMobile", "", new 
                            {
                                @maxlength = "30",
                                @id = "txtNewMobile",
                                @class = "tbPhoneCode",
                                @style = "display:none", 
                                @validator = ClientValidators.Create()
                                    .RequiredIf( "isMobileRequired", this.GetMetadata(".Mobile_Empty"))
                                    .MinLength(7, this.GetMetadata(".Mobile_Incorrect"))
                                    .Number(this.GetMetadata(".Mobile_Incorrect"))
                                    .Custom("validateMobileNumber")
                            }
                        ) %>
                        <%: Html.Hidden("realMobilePrefix", UserMobilePrefix, new { @id = "hdRealMobilePrefix" })%>
                        <%: Html.Hidden("realMobile", UserMobile, new { @id = "hdRealMobile" })%>
                        <div class="controls_addition">
                        <%: Html.Button(this.GetMetadata(".Button_UpdateMobile"), new { @id = "btnUpdateMobile", @style = "display:none"})%>
                        <%: Html.Button(this.GetMetadata(".Button_SendVerificationCode"), new { @id = "btnSendEnterCashVerificationCode" })%>
                        </div>
	                </ControlPart>
                </ui:InputField>
                <ui:MinifiedJavascriptControl runat="server" ID="scriptPhoneNumber" AppendToPageEnd="true" Enabled="false">
                <script type="text/javascript">
                    function isMobileRequired() {
                        return true;
                    }

                    function validateMobileNumber() {
                        var value = this;
                        if (value.length > 0) {
                            if ($('#ddlNewMobilePrefix').val() == '')
                                return '<%= this.GetMetadata(".PhonePrefix_Empty").SafeJavascriptStringEncode() %>';
                        }
                        return true;
                    }

                    var $btnSendEnterCashVerificationCode = $("#btnSendEnterCashVerificationCode");
                    var _countDownSecondsForSendEnterCashVerificationCode = 60;

                    function countDownForResend() {
                        _countDownSecondsForSendEnterCashVerificationCode = _countDownSecondsForSendEnterCashVerificationCode - 1;
                        if (_countDownSecondsForSendEnterCashVerificationCode > 0) {
                            $btnSendEnterCashVerificationCode.find('.button_Center span').text('<%= this.GetMetadata(".VerificationCode_CountDown_Text").SafeJavascriptStringEncode() %>'.format(_countDownSecondsForSendEnterCashVerificationCode));
                            window.setTimeout(countDownForResend, 1000);
                        }
                        else {
                            $btnSendEnterCashVerificationCode.find('.button_Center span').text('<%= this.GetMetadata(".VerificationCode_Resend").SafeJavascriptStringEncode() %>');
                            $btnSendEnterCashVerificationCode.removeAttr("disabled");
                        }
                    }

                    $(document).bind("ENTERCASH_BANK_CHANGED", function (e, data) {
                        if (data != null && data != '') {
                            $('#ddlNewMobilePrefix option').remove();
                            $('#ddlNewMobilePrefix').append('<option value="' + data.PhoneCode + '">' + data.PhoneCode + '</option>');
                            $('#ddlNewMobilePrefix').val(data.PhoneCode).trigger('change');
                        }
                    });

                    function initEnterCashMobileControl() {
                        var $hdRealMobilePrefix = $('#hdRealMobilePrefix');
                        var enterCashBank = enterCashBankInfos[$('#formEnterCashPayCard #ddlBankID').val()];

                        if ($hdRealMobilePrefix.val() != enterCashBank.PhoneCode) {
                            $('#spMessgaeMobiledonotSupport').show();
                            $('#ddlNewMobilePrefix').show();
                            $('#txtNewMobile').show();
                            $('#btnUpdateMobile').show();

                            $('#txtMobile').hide();
                            $('#btnSendEnterCashVerificationCode').hide();
                        }
                        else {
                            $('#spMessgaeMobiledonotSupport').hide();
                            $('#ddlNewMobilePrefix').hide();
                            $('#txtNewMobile').hide();
                            $('#btnUpdateMobile').hide();

                            $('#txtMobile').show();
                            $('#btnSendEnterCashVerificationCode').show();
                        }
                    }

                    $(function () {
                        $btnSendEnterCashVerificationCode.removeAttr("disabled");

                        var $hdRealMobilePrefix = $('#hdRealMobilePrefix');
                        var enterCashBank = enterCashBankInfos[$('#formEnterCashPayCard input[name="bankID"]').val()];

                        window.setTimeout(initEnterCashMobileControl, 500);

                        $('#btnUpdateMobile').click(function (e) {
                            e.preventDefault();

                            if (!$('#formEnterCashPayCard').validate().element($('#formEnterCashPayCard #txtNewMobile')))
                                return false;

                            var $this = $(this);
                            $this.toggleLoadingSpin(true);

                            var mobilePrefix = $('#formEnterCashPayCard #ddlNewMobilePrefix').val();
                            var mobileNumber = $('#formEnterCashPayCard #txtNewMobile').val();

                            $.post('<%= this.Url.RouteUrl("Profile", new { @action = "UpdateMobile" }).SafeJavascriptStringEncode() %>',
                                { mobilePrefix: mobilePrefix, mobile: mobileNumber },
                                function (json) {
                                    var $btnUpdateMobile = $("#btnUpdateMobile");
                                    $btnUpdateMobile.toggleLoadingSpin(false);

                                    if (json.success) {
                                        alert('You have updated your mobile.');
                                        var $formEnterCashPayCard = $('#formEnterCashPayCard');

                                        var mobilePrefix = $('#formEnterCashPayCard #ddlNewMobilePrefix').val();
                                        var mobileNumber = $('#formEnterCashPayCard #txtNewMobile').val();

                                        $formEnterCashPayCard.find('#hdRealMobilePrefix').val(mobilePrefix);
                                        $formEnterCashPayCard.find('#hdRealMobile').val(mobileNumber);

                                        $formEnterCashPayCard.find('#spMessgaeMobiledonotSupport').hide();
                                        $formEnterCashPayCard.find('#ddlNewMobilePrefix').hide();
                                        $formEnterCashPayCard.find('#txtNewMobile').hide();
                                        $btnUpdateMobile.hide();

                                        $formEnterCashPayCard.find('#txtMobile').show().val(mobilePrefix + '-' + mobileNumber);
                                        $formEnterCashPayCard.find('#btnSendEnterCashVerificationCode').show();
                                    }
                                    else {
                                        alert(json.error);
                                    }
                                }, 'json').error(function () {
                                $("#btnUpdateMobile").toggleLoadingSpin(false);
                            });
                        });

                        $btnSendEnterCashVerificationCode.click(function (e) {
                            e.preventDefault();

                            if (!$('#formEnterCashPayCard').validate().element($('#formEnterCashPayCard input[name="mobile"]')))
                                return false;

                            var $this = $(this);
                            $this.toggleLoadingSpin(true);

                            var bankID = $('#formEnterCashPayCard input[name="bankID"]').val();
                            var mobilePrefix = $('#formEnterCashPayCard #hdRealMobilePrefix').val();
                            var mobileNumber = $('#formEnterCashPayCard #hdRealMobile').val();

                            $.post('<%= this.Url.RouteUrl("Deposit", new { @action = "SendEnterCashVerificationCode", @vendorID=this.Model.VendorID }).SafeJavascriptStringEncode() %>',
                                { bankID: bankID, phoneNumber: mobilePrefix + mobileNumber },
                                function (json) {
                                    var $btnSendEnterCashVerificationCode = $("#btnSendEnterCashVerificationCode");
                                    $btnSendEnterCashVerificationCode.toggleLoadingSpin(false);
                                    if (json.success) {
                                        alert('The verification code has been sent to your mobile, please check your message.');
                                        $btnSendEnterCashVerificationCode.attr("disabled", "disabled");
                                        countDownForResend();
                                    }
                                    else {
                                        alert(json.error);
                                    }
                                }, 'json').error(function () {
                                $btnSendEnterCashVerificationCode.toggleLoadingSpin(false);
                                $btnSendEnterCashVerificationCode.find('.button_Center span').text('<%= this.GetMetadata(".VerificationCode_Resend").SafeJavascriptStringEncode() %>');
                            });
                        });
                    });
                </script>
                </ui:MinifiedJavascriptControl>

                <%------------------------
                    Verification Code
                -------------------------%>    
                <ui:InputField ID="fldVerificationCode" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	                <LabelPart><%= this.GetMetadata(".VerificationCode_Label").SafeHtmlEncode()%></LabelPart>
	                <ControlPart>
                        <%: Html.TextBox("verificationCode", "", new 
                        { 
                            @maxlength = 50,
                            @dir = "ltr",
                            @validator = ClientValidators.Create().Required(this.GetMetadata(".VerificationCode_Empty"))
                        }
                        )%>
	                </ControlPart>
                </ui:InputField>
                

                <center>
                    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id = "btnDepositWithEnterCashPayCard", @class="ContinueButton button" })%>
                </center>
            </form>
        </ui:Panel>
    </Tabs>
</ui:TabbedContent>

<ui:MinifiedJavascriptControl runat="server" ID="scriptDepositWithEnterCashPayCard" AppendToPageEnd="true" Enabled="false">
<script type="text/javascript">
//<![CDATA[
    $(function () {
        $('#formEnterCashPayCard').initializeForm();

        var hasVerificationCode = <%=(!String.IsNullOrEmpty(DummyPayCard.BankCode)).ToString().ToLowerInvariant()%>;
        if (hasVerificationCode) {

            $('#fldPhoneNumber').hide();
            $('#fldVerificationCode').hide();
        }

        $('#btnChangeVerificationCode').click(function() {
            $('#fldPhoneNumber').show();
            $('#fldVerificationCode').show();
            $('#fldVerificationCodeForView').hide();
        });
        
        var depositTypeCode = '<%=depositTypeCode %>';
        switch (depositTypeCode) {
        case 'WYWALLET':
            $('#fldBankID').hide();
            break;

        case 'SIRU':
            $('#fldBankID .inputfield_Label').text(' ');
            var $ddlBankID = $('#ddlBankID');
            $ddlBankID.hide().after($('<input type="text" value="' + $ddlBankID.text() + '" dir="ltr" class="textbox" readonly="readonly" disabled="disabled" />'));
            break;
        }

        $('#btnDepositWithEnterCashPayCard').click(function (e) {
            e.preventDefault();
            if (!isDepositInputFormValid() || !$('#formEnterCashPayCard').valid())
                return false;

            $(this).toggleLoadingSpin(true);

            // <%-- post the prepare form --%>   
            tryToSubmitDepositInputForm('<%= DummyPayCard.ID.ToString() %>', function () {
                $('#btnDepositWithEnterCashPayCard').toggleLoadingSpin(false);
            });
        });


        // <%-- bind event to DEPOSIT_TRANSACTION_PREPARED --%>
        $(document).bind('DEPOSIT_TRANSACTION_PREPARED', function (e, sid) {
            $('#formEnterCashPayCard input[name="sid"]').val(sid);
            var options = {
                dataType: "json",
                type: 'POST',
                success: function (json) {
                    if (!json.success) {
                        $('#btnDepositWithEnterCashPayCard').toggleLoadingSpin(false);
                        showDepositError(json.error);
                        return;
                    }
                },
                error: function (xhr, textStatus, errorThrown) {
                    $('#btnDepositWithEnterCashPayCard').toggleLoadingSpin(false);
                    showDepositError(errorThrown);
                }
            };
            $('#formEnterCashPayCard').ajaxForm(options);
            $('#formEnterCashPayCard').submit();
        });
    });
//]]>
</script>
</ui:MinifiedJavascriptControl>

<div runat="server" id="divError">
<%: Html.H1(PaymentTitle)%>
<ui:Panel runat="server" ID="pnError">
<%: Html.WarningMessage(this.GetMetadata(".NoAvailableBank")) %>

<center>
    <%: Html.Button(this.GetMetadata(".Button_Back"), new { @id = "btnBackFromDepositWithEnterCashPayCard", @onclick = "backToDepositIndexPage(); return false;", @class="BackButton button" })%>
</center>
<script type="text/javascript">
    function backToDepositIndexPage() {
        window.location = '<%= this.Url.RouteUrl("Deposit").SafeJavascriptStringEncode() %>';
        return false;
    }
</script>
</ui:Panel>
</div>