<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>



<%---------------------------------------------------------------
    TurkeyBank transfer
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
        action="<%= this.Url.RouteUrl("Withdraw", new { @action = "RegisterTurkeyBankPayCard" }).SafeHtmlEncode() %>" enctype="application/x-www-form-urlencoded">


        

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
            BranchCode ( 6 digit )
         ----------------------------------------------------------------%>
        <ui:InputField ID="fldBranchCode" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	        <LabelPart><%= this.GetMetadata(".BranchCode_Label").SafeHtmlEncode()%></LabelPart>
	        <ControlPart>
                <%: Html.TextBox("branchCode", "", new 
                {
                    @dir = "ltr",
                    @maxlength = "6",
                    @validator = ClientValidators.Create()
                        .Required(this.GetMetadata(".BranchCode_Empty"))
                })%>
            </ControlPart>
        </ui:InputField>
        <script type="text/javascript">
            $(function () {
                $('#fldBranchCode input').allowNumberOnly();
            });
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
            AccountNumber ( 10 digit )
         ----------------------------------------------------------------%>
        <ui:InputField ID="fldAccountNumber" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	        <LabelPart><%= this.GetMetadata(".AccountNumber_Label").SafeHtmlEncode()%></LabelPart>
	        <ControlPart>
                <%: Html.TextBox("accountNumber", "", new 
                {
                    @dir = "ltr",
                    @maxlength = "10",
                    @validator = ClientValidators.Create()
                        .Required(this.GetMetadata(".AccountNumber_Empty"))
                })%>
            </ControlPart>
        </ui:InputField>
        <script type="text/javascript">
            $(function () {
                $('#fldAccountNumber input').allowNumberOnly();
            });
        </script>
       

        <%---------------------------------------------------------------
            IBAN ( 26 Alphanumeric )
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
                    $('#fldBranchCode2 input[type="text"]').val(parCards[i].BranchCode);
                    $('#fldAccountNumber2 input[type="text"]').val(parCards[i].AccountNumber);
                    $('#fldIBAN2 input[type="text"]').val(parCards[i].IBAN);
                    $('#fldTCNumber2 input[type="text"]').val(parCards[i].BankAdditionalInfo);
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
    };

    function __loadRecentPayCards(payCardID) {
        $('#paycards-selector').data('payCardID', payCardID);
        var url = '<%= this.Url.RouteUrl( "Withdraw", new { @action="GetTurkeyBankPayCards" }).SafeJavascriptStringEncode() %>';
        jQuery.getJSON(url, null, __populatePayCards);
    }

    $(function () {
        $('#formRegisterPayCard').initializeForm();
        $('#formRecentCards').initializeForm();

        __populatePayCards( <% Html.RenderAction("GetTurkeyBankPayCards");  %> );

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