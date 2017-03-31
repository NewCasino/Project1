<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>



<%---------------------------------------------------------------
    APX bank transfer
 ----------------------------------------------------------------%>
<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <tabs>


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
                    BankBranchCode (Readonly)
                 ----------------------------------------------------------------%>
                <ui:InputField ID="fldBankBranchCode2" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
                <LabelPart><%= this.GetMetadata(".BankBranchCode_Label").SafeHtmlEncode()%></LabelPart>
                <ControlPart>
                        <%: Html.TextBox("bankBranchCode", "", new 
                        {
                            @readonly = "readonly",
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
                    TC Number  (Readonly) 
                 ----------------------------------------------------------------%>
                <ui:InputField ID="fldTCNumber2" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	                <LabelPart><%= this.GetMetadata(".TCNumber_Label").SafeHtmlEncode()%></LabelPart>
	                <ControlPart>
                        <%: Html.TextBox("payee", "", new 
                        {
                            @readonly = "readonly",
                        })%>
                    </ControlPart>
                </ui:InputField>

                
                <%---------------------------------------------------------------
                        Date of Birth
                 ----------------------------------------------------------------%>
                <ui:InputField ID="fldDateOfBirth2" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
                <LabelPart><%= this.GetMetadata(".DateOfBirth_Label").SafeHtmlEncode()%></LabelPart>
                <ControlPart>
                        <%: Html.TextBox("dateOfBirth2", "", new
                            {
                                @readonly = "readonly"
                            })%>
                    </ControlPart>
                </ui:InputField>

                <%---------------------------------------------------------------
                        Cell Phone Number
                 ----------------------------------------------------------------%>
                <ui:InputField ID="fldCellPhoneNumber2" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
                <LabelPart><%= this.GetMetadata(".CellPhoneNumber_Label").SafeHtmlEncode()%></LabelPart>
                <ControlPart>
                        <%: Html.TextBox("cellPhoneNumber2", "", new
                            {
                                @readonly = "readonly",
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
            Register a bank
         ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabRegister" Selected="true" Caption="<%$ Metadata:value(.Tabs_RegisterPayCard) %>">

        
        
        <form id="formRegisterPayCard" method="post" 
        action="<%= this.Url.RouteUrl("Withdraw", new { @action = "RegisterAPXBankPayCard" }).SafeHtmlEncode() %>" enctype="application/x-www-form-urlencoded">


        

        <%---------------------------------------------------------------
            BankName  ( 50 charactor )
         ----------------------------------------------------------------%>
        <ui:InputField ID="fldBankName" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	        <LabelPart><%= this.GetMetadata(".BankName_Label").SafeHtmlEncode()%></LabelPart>
	        <ControlPart>
                <%: Html.TextBox("bankName", "", new 
                {
                    @maxlength = "50",
                    @validator = ClientValidators.Create()
                        .Required(this.GetMetadata(".BankName_Empty")),
                })%>
            </ControlPart>
        </ui:InputField>
        


        <%---------------------------------------------------------------
            BranchAddress
         ----------------------------------------------------------------%>
        <ui:InputField ID="fldBranchAddress" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata(".BranchAddress_Label").SafeHtmlEncode()%></LabelPart>
        <ControlPart>
                <%: Html.TextBox("branchAddress", "", new 
                {
                    @maxlength = "40",
                    @validator = ClientValidators.Create().Required(this.GetMetadata(".BranchAddress_Empty"))
                })%>
            </ControlPart>
        </ui:InputField>

        <%---------------------------------------------------------------
             Bank Branch Code
         ----------------------------------------------------------------%>
        <ui:InputField ID="fldBankBranchCode" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata(".BankBranchCode_Label").SafeHtmlEncode()%></LabelPart>
        <ControlPart>
                <%: Html.TextBox("bankBranchCode", "", new 
                {
                    @maxlength = "40",
                    @validator = ClientValidators.Create().Required(this.GetMetadata(".BankBranchCode_Empty"))
                })%>
            </ControlPart>
        </ui:InputField>
            <script type="text/javascript">
                $(function () {
                    //$('#fldBankBranchCode input').allowNumberOnly();
                });
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
                    @maxlength = "26",
                    @validator = ClientValidators.Create()
                        .Required(this.GetMetadata(".IBAN_Empty"))
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
                var validationExpressionOfIBAN = /^(TR)(([a-z]|[0-9]){24,24})$/i;
                if (value == null ||
                    value.length == 0 ||
                    validationExpressionOfIBAN == null) {
                    return true;
                }

                var ret = validationExpressionOfIBAN.exec(value);
                if (ret == null || ret.length == 0)
                    return '<%= this.GetMetadata(".Format_Invalid").SafeJavascriptStringEncode() %>';
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
                    @maxlength = "16",
                    @dir = "ltr",
                    @validator = ClientValidators.Create()
                        .Required(this.GetMetadata(".SWIFT_Empty"))
                        .Custom("validateSWIFT"),
                })%>
            </ControlPart>
        </ui:InputField>
        <script language="javascript" type="text/javascript">
            function isSWIFTRequired() { return g_CurrentConfiguration != null && g_CurrentConfiguration.showSWIFT; }
            function validateSWIFT() {
                var value = this;
                var validationExpressionOfSWIFT = /^(([a-z]|[0-9]){8,11})$/i;
                if (value == null ||
                    value.length == 0 ||
                    validationExpressionOfSWIFT == null) {
                    return true;
                }
                var ret = validationExpressionOfSWIFT.exec(value);
                if (ret == null || ret.length == 0)
                    return '<%= this.GetMetadata(".Format_Invalid").SafeJavascriptStringEncode() %>';
                return true;
            }
        </script>

        <%---------------------------------------------------------------
            TC Number ( 11 digit )
         ----------------------------------------------------------------%>
        <ui:InputField ID="fldTCNumber" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	        <LabelPart><%= this.GetMetadata(".TCNumber_Label").SafeHtmlEncode()%></LabelPart>
	        <ControlPart>
                <%: Html.TextBox("tcNumber", "", new 
                {
                    @maxlength = "11",
                    @validator = ClientValidators.Create()
                        .Required(this.GetMetadata(".TCNumber_Empty"))
                })%>
            </ControlPart>
        </ui:InputField>
        <script type="text/javascript">
            $(function () {
                $('#fldTCNumber input').allowNumberOnly();
            });
        </script>

        <%---------------------------------------------------------------
             Date of Birth
         ----------------------------------------------------------------%>
        <ui:InputField ID="fldDateOfBirth" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata(".DateOfBirth_Label").SafeHtmlEncode()%></LabelPart>
        <ControlPart>
                <%: Html.TextBox("dateOfBirth", "", new 
                {
                    @maxlength = "10",
                    @validator = ClientValidators.Create().Custom("ValidateDate").Required(this.GetMetadata(".DateOfBirth_Empty"))
                })%>
            </ControlPart>
        </ui:InputField>
            <script type="text/javascript">
                function ValidateDate(sender, args) {
                    var dateString = this;
                    var isValid = false;

                    var regex = /(((0[1-9]|1[0-9])|2[0-9]|3[0-1])\/(0[1-9]|1[0-2])\/((19|20)\d\d))$/;
                    if (regex.test(dateString)) {
                        var parts = dateString.split("/");
                        var dt = new Date(parts[1] + "/" + parts[0] + "/" + parts[2]);
                        isValid = (dt.getDate() == parts[0] && dt.getMonth() + 1 == parts[1] && dt.getFullYear() == parts[2]);
                    } else {
                        isValid = false;
                    }

                    if (!isValid) {
                        return '<%= this.GetMetadata(".DateOfBirth_Invalid").SafeJavascriptStringEncode() %>';
                    } else {
                        return true;
                    }
                }
            </script>


        <%---------------------------------------------------------------
             Cell Phone Number
         ----------------------------------------------------------------%>
        <ui:InputField ID="fldCellPhoneNumber" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart><%= this.GetMetadata(".CellPhoneNumber_Label").SafeHtmlEncode()%></LabelPart>
        <ControlPart>
                <%: Html.TextBox("cellPhoneNumber", "", new 
                {
                    @maxlength = "16",
                    @validator = ClientValidators.Create().Required(this.GetMetadata(".CellPhoneNumber_Empty"))
                })%>
            </ControlPart>
        </ui:InputField>
        <script type="text/javascript">
            $(function () {
                $('#fldCellPhoneNumber input').allowNumberOnly();
            });
        </script>

        <center>
            <br />
            <%: Html.Button(this.GetMetadata(".Button_Back"), new { @id = "btnWithdrawBack", @type = "button", @onclick = string.Format("$(this).toggleLoadingSpin(true);self.location='{0}';return false;", this.Url.RouteUrl("Withdraw", new { @action = "Index" }).SafeJavascriptStringEncode()) })%>
            <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id = "btnRegisterCardAndWithdraw" })%>
        </center>

        </form>

        </ui:Panel>

    </tabs>
</ui:TabbedContent>

<script type="text/javascript">
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
                    $('#fldBankName2 input[type="text"]').val(parCards[i].BankName);
                    $('#fldBranchAddress2 input[type="text"]').val(parCards[i].BranchAddress);
                    $('#fldIBAN2 input[type="text"]').val(parCards[i].IBAN);
                    $('#fldSWIFT2 input[type="text"]').val(parCards[i].SWIFT);
                    $('#fldTCNumber2 input[type="text"]').val(parCards[i].BankAdditionalInfo);

                    $('#fldDateOfBirth2 input[type="text"]').val(parCards[i].BirthDate);
                    $('#fldCellPhoneNumber2 input[type="text"]').val(parCards[i].PhoneNumber);
                    $('#fldBankBranchCode2 input[type="text"]').val(parCards[i].BankBranchCode);
                }
            }
        });


        // <%-- if more than one pay card, select the first one tab and first pay card --%>
        if (json.payCards.length > 0) {
            $('#tabbedPayCards').showTab('tabRecentCards', true);
            $('#tabbedPayCards').selectTab('tabRecentCards');

            // <%-- if more than 3 cards, hide the registration tab --%>
            if (json.payCards.length >= 3) {<%--<%= this.GetMetadata("/Metadata/Settings.max_withdraw_registered_accounts").SafeHtmlEncode() %>) {--%>
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
    };

    function __loadRecentPayCards(payCardID) {
        $('#paycards-selector').data('payCardID', payCardID);
        var url = '<%= this.Url.RouteUrl( "Withdraw", new { @action="GetAPXBankPayCards" }).SafeJavascriptStringEncode() %>';
        jQuery.getJSON(url, null, __populatePayCards);
    }

    $(function () {
        $('#formRegisterPayCard').initializeForm();
        $('#formRecentCards').initializeForm();

        __populatePayCards( <% Html.RenderAction("GetAPXBankPayCards");  %>);

        $('#btnRegisterCardAndWithdraw').click(function (e) {
            e.preventDefault();

            if (!isWithdrawInputFormValid() || !$('#formRegisterPayCard').valid())
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
            $('#formRegisterPayCard').ajaxForm(options);
            $('#formRegisterPayCard').submit();
        });

        $('#btnWithdrawWithExistingCard').click(function (e) {
            e.preventDefault();

            if (!isWithdrawInputFormValid() || !$('#formRecentCards').valid())
                return;

            $(this).toggleLoadingSpin(true);

            var payCardID = $('#hExistingPayCardID').val();
            tryToSubmitWithdrawInputForm(payCardID, function () {
                $('#btnWithdrawWithExistingCard').toggleLoadingSpin(false);
            });
        });
    });
</script>
