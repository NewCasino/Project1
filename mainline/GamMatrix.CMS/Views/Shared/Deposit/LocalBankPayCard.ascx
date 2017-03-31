<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">
    private int _MaxLengthOfNameOnAccount = -1;
    private int MaxLengthOfNameOnAccount
    {
        get {
            if (_MaxLengthOfNameOnAccount == -1)
            {
                var t = this.GetMetadata(".NameOnAccount_MaxLength").DefaultIfNullOrWhiteSpace("30");
                int.TryParse(t, out _MaxLengthOfNameOnAccount);
                if (_MaxLengthOfNameOnAccount == -1)
                    _MaxLengthOfNameOnAccount = 30;
            }
            
            return _MaxLengthOfNameOnAccount;
        }
    }
    
    private string GetBanksJson()
    {        
        StringBuilder json = new StringBuilder();
        json.Append("var banks = {");
        foreach(string entity in Metadata.GetChildrenPaths("Metadata/PaymentMethod/LocalBank"))
        {
            json.AppendFormat(@" '{0}' : [", entity.Substring(entity.LastIndexOf("/") + 1).SafeJavascriptStringEncode());
            foreach (string bank in Metadata.GetChildrenPaths(entity))
            {
                json.AppendFormat(@" {{'{0}' : '{1}' }},", bank.Substring(bank.LastIndexOf("/") + 1).SafeJavascriptStringEncode(), Metadata.Get(bank).SafeJavascriptStringEncode());
            }
            if (json[json.Length - 1] == ',')
                json.Remove(json.Length - 1, 1);
            json.Append("],");
        }
        if (json[json.Length - 1] == ',')
            json.Remove(json.Length - 1, 1);
        json.Append("}");

        return json.ToString();
    }

    private List<SelectListItem> GetBankList()
    {
        string[] bankPaths = Metadata.GetChildrenPaths("Metadata/PaymentMethod/LocalBank/Bank/" + Profile.UserCountryID);
        if(bankPaths == null || bankPaths.Length == 0)
            throw new InvalidOperationException("There is no bank for your country.");

        List<SelectListItem> list = new List<SelectListItem>();
        foreach(string bankPath in bankPaths)
        {
            string bank = bankPath.Substring(bankPath.LastIndexOf("/") + 1);
            list.Add(new SelectListItem()
            {
                Value = bank,
                Text = Metadata.Get(System.IO.Path.Combine(bankPath, ".DisplayName")).DefaultIfNullOrWhiteSpace(bank),
            });
        }
        
        return list;
    }

    private PayCardInfoRec PayCard { get; set; }
    private PayCardInfoRec GetExistingPayCard()
    {
        if (this.PayCard == null)
        {
            this.PayCard = GamMatrixClient.GetPayCards(VendorID.LocalBank)
            .OrderByDescending(e => e.LastSuccessDepositDate)
            .FirstOrDefault();
        }
        if (this.PayCard == null)
            throw new InvalidOperationException("This payment method is not configured in GmCore.");
        return this.PayCard;
    }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        if (Profile.UserCountryID == 223) // Turkey
        {
            fldBankAccountNo.Visible = false;
            scriptBankAccountNo.Visible = false;
        }
        else if (Profile.UserCountryID == 51 || Profile.UserCountryID == 202) // China or Korea
        {
            fldCitizenID.Visible = false;
            scriptCitizenID.Visible = false;
        }
        else if (Profile.UserCountryID == 183) // Russia
        {
            fldCitizenID.Visible = false;
            scriptCitizenID.Visible = false;
        }
    }
    
</script>

<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <Tabs>

        <%---------------------------------------------------------------
            Recent cards
         ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabRecentCards" Caption="<%$ Metadata:value(.Tab_RecentPayCards) %>">
            <form id="formRecentCards" onsubmit="return false">

            <%------------------------
                Card List(AJAX LOAD)
            -------------------------%> 
            <ui:InputField ID="fldExistingPayCard" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".Select").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>

                <ul id="paycards-selector">
            
                </ul>
                <%-- <#= d[i].IsBelongsToPaymentMethod ? '' : 'disabled="disabled"' #> --%>
                <script id="pay-card-template" type="text/html">
                <#
                    var d=arguments[0];

                    for(var i=0; i < d.length; i++)     
                    {        
                #>
                    <li>
                        <input type="radio" name="existingPayCard" value="<#= d[i].ID.htmlEncode() #>" id="payCard_<#= d[i].ID.htmlEncode() #>" data-DisplayNumber="<#= d[i].DisplayNumber.htmlEncode()#>" data-BankName="<#= d[i].BankName.htmlEncode()#>" />
                        <label for="payCard_<#= d[i].ID.htmlEncode() #>" dir="ltr">
                            <#= d[i].BankName.htmlEncode() #> - <#= d[i].DisplayNumber.htmlEncode() #>
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
            Bank
            -------------------------------------------%>
            <ui:InputField ID="fldBank2" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".Bank_Label").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>
                    <%: Html.DropDownList("bank", GetBankList(), new { @class = "ddlBank", @id = "ddlBank2", @disabled = "disabled", @onchange = "onBankChange()" })%>
                    <%-- We need another hide field for the Bank ID 
                    because the Bank ID value will not be included in POST request if the dropdownlist is disabled. --%>
                    <%: Html.Hidden("bankName")%>
	            </ControlPart>
            </ui:InputField>
            <script type="text/javascript">
                function onBankChange() {
                    $("input[name='bankName']").val($("#ddlBank").val());
                }
            </script>

            <%------------------------
                Bank Account No
              -------------------------%>    
            <ui:InputField ID="fldBankAccountNo2" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".BankAccountNo_Label").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>
                    <%: Html.TextBox("bankAccountNo", "", new 
                    {
                        @id = "txtBankAccountNo2",
                        @maxlength = 16,
                        @dir = "ltr",
                        @readonly = "readonly",
                        @validator = ClientValidators.Create()
                            .Required(this.GetMetadata(".BankAccountNo_Empty"))
                    } 
                    )%>
	            </ControlPart>
            </ui:InputField>

            <%------------------------
                Citizen ID
              -------------------------%>    
            <ui:InputField ID="fldCitizenID2" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".CitizenID_Label").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>
                    <%: Html.TextBox("citizenID", "", new 
                    {
                        @id = "txtCitizenID2",
                        @maxlength = 16,
                        @dir = "ltr",
                        @readonly = "readonly",
                        @validator = ClientValidators.Create()
                            .Required(this.GetMetadata(".CitizenID_Empty"))
                    } 
                    )%>
	            </ControlPart>
            </ui:InputField>

            <%------------------------
                Name on Account
              -------------------------%>    
            <ui:InputField ID="fldNameOnAccount2" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".NameOnAccount_Label").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>
                    <%: Html.TextBox("nameOnAccount", Profile.DisplayName, new 
                    {
                        @id = "txtNameOnAccount2",
                        @maxlength = MaxLengthOfNameOnAccount,
                        @readonly = "readonly",
                        @validator = ClientValidators.Create().Required(this.GetMetadata(".NameOnAccount_Empty")) 
                    } 
                    )%>
	            </ControlPart>
            </ui:InputField>

            <center>
            <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id = "btnDepositWithExistingCard", @class="ContinueButton button" })%>
            </center>

            </form>
        </ui:Panel>

        <%---------------------------------------------------------------
            Register a card
         ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabRegister" Selected="true" Caption="<%$ Metadata:value(.Tabs_RegisterPayCard) %>">
            <form id="formRegisterPayCard" onsubmit="return false" method="post" action="<%= this.Url.RouteUrl("Deposit", new { @action = "RegisterLocalBankPayCard", @vendorID=this.Model.VendorID }).SafeHtmlEncode() %>" enctype="application/x-www-form-urlencoded">
            <%------------------------------------------
                Bank
                -------------------------------------------%>
            <ui:InputField ID="fldBank" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".Bank_Label").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>
                    <%: Html.DropDownList("bank", GetBankList(), new { @class = "ddlBank", @id = "ddlBank", @onchange = "onBankChange()" })%>
                    <%-- We need another hide field for the Bank ID 
                    because the Bank ID value will not be included in POST request if the dropdownlist is disabled. --%>
                    <%: Html.Hidden("bankName")%>
	            </ControlPart>
            </ui:InputField>
            <script type="text/javascript">
                function onBankChange() {
                    $("input[name='bankName']").val($("#ddlBank").val());
                }
                $(function () {
                    $("#ddlBank").trigger('change');
                });
            </script>

            <%------------------------
                Bank Account No
              -------------------------%>    
            <ui:InputField ID="fldBankAccountNo" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".BankAccountNo_Label").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>
                    <%: Html.TextBox("bankAccountNo", "", new 
                    {
                        @id = "txtBankAccountNo",
                        @maxlength = 16,
                        @minlength = 6,
                        @dir = "ltr",
                        @validator = ClientValidators.Create()
                            .Required(this.GetMetadata(".BankAccountNo_Empty"))
                            .MinLength(6,this.GetMetadata(".BankAccountNo_Invalid"))
                            .Custom("validateBankAccountNo")
                    } 
                    )%>
	            </ControlPart>
            </ui:InputField>
            <ui:MinifiedJavascriptControl runat="server" ID="scriptBankAccountNo" AppendToPageEnd="true" Enabled="false">
            <script language="javascript" type="text/javascript">
            //<![CDATA[
                function validateBankAccountNo() {
                    var value = this;
                    var ret = /^(\d{6,16})$/.exec(value);
                    if (ret == null || ret.length == 0)
                        return '<%= this.GetMetadata(".BankAccountNo_Invalid").SafeJavascriptStringEncode() %>';
                    return true;
                }
            //]]>
            </script>
            </ui:MinifiedJavascriptControl>

            <%------------------------
                Citizen ID
              -------------------------%>    
            <ui:InputField ID="fldCitizenID" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".CitizenID_Label").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>
                    <%: Html.TextBox("citizenID", "", new 
                    {
                        @id = "txtCitizenID",
                        @maxlength = 16,
                        @dir = "ltr",
                        @validator = ClientValidators.Create()
                            .Required(this.GetMetadata(".CitizenID_Empty"))
                            .Custom("validateCitizenID")
                    } 
                    )%>
	            </ControlPart>
            </ui:InputField>
            <ui:MinifiedJavascriptControl runat="server" ID="scriptCitizenID" AppendToPageEnd="true" Enabled="false">
            <script language="javascript" type="text/javascript">
            //<![CDATA[
                function validateCitizenID() {                    
                    return true;
                }
            //]]>
            </script>
            </ui:MinifiedJavascriptControl>

            <%------------------------
                Name on Account
              -------------------------%>    
            <ui:InputField ID="fldNameOnAccount" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".NameOnAccount_Label").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>
                    <%: Html.TextBox("nameOnAccount", Profile.DisplayName, new 
                    {
                        @id = "txtNameOnAccount",
                        @maxlength = MaxLengthOfNameOnAccount,
                        @validator = ClientValidators.Create().Required(this.GetMetadata(".NameOnAccount_Empty")) 
                    } 
                    )%>
	            </ControlPart>
            </ui:InputField>
                
            <%= this.GetMetadata(".Instruction") %>
            <center>
            <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id = "btnRegisterCardAndDeposit", @class="ContinueButton button" })%>
            </center>
            </form>
        </ui:Panel>

    </Tabs>

</ui:TabbedContent>

<script language="javascript" type="text/javascript">

    
    function __populatePayCards(json) {
        if (!json.success) {
            showDepositError(json.error);
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
                    $('#ddlBank2').val(parCards[i].BankName);
                    $('#txtNameOnAccount2').val(parCards[i].OwnerName);
                    if(parCards[i].BankCountryID == 223)
                    {
                        //$('#txtCitizenID2').val(parCards[i].DisplayNumber);
                        $('#txtCitizenID2').val(parCards[i].DisplayNumber);
                        $('#fldBankAccountNo2').hide();
                        $('#fldCitizenID2').show();
                    }
                    else
                    {
                        $('#txtBankAccountNo2').val(parCards[i].DisplayNumber);
                        $('#fldBankAccountNo2').show();
                        $('#fldCitizenID2').hide();                        
                    }
                }
            }
        });


        // <%-- if more than one pay card, select the first one tab and first pay card --%>
        if (json.payCards.length > 0) {
            $('#tabbedPayCards').showTab('tabRecentCards', true);
            $('#tabbedPayCards').selectTab('tabRecentCards');
            // <%-- if more than 3 cards, hide the registration tab --%>
            if (json.payCards.length >= <%=Settings.Payments_LocalBank_Card_CountLimit.ToString() %>) {
                $('#tabbedPayCards').showTab('tabRegister', false);
            }

            // <%-- select the paycard --%>
            var payCardID =  $('#paycards-selector').data('payCardID');
            var $input = $('#paycards-selector input[value="' + payCardID + '"]');
            if ($input.length > 0) {
                $input.attr('checked', true).trigger('click');
            }
            else
                $('#paycards-selector li input:enabled').first().attr('checked', true).trigger('click');
        } else { // <%-- hide the recent cards tab and select register tab --%>
            $('#tabbedPayCards').selectTab('tabRegister');
            $('#tabbedPayCards').showTab('tabRegister', true);
            $('#tabbedPayCards').showTab('tabRecentCards', false);
        }
    };

    function __loadRecentPayCards(payCardID) {
        $('#paycards-selector').data('payCardID', payCardID);
        var url = '<%= this.Url.RouteUrl( "Deposit", new { @action="GetLocalBankPayCards", @paymentMethodName = this.Model.UniqueName }).SafeJavascriptStringEncode() %>';
        jQuery.getJSON(url, null, __populatePayCards);
    }

    $(document).ready(function () {
        $('#formRegisterPayCard').initializeForm();
        $('#formRecentCards').initializeForm();

        <% if( !string.IsNullOrEmpty(Request["payCardID"]) ) { %>
        $('#paycards-selector').data('payCardID', '<%= Request["payCardID"] %>');
        <% } %>

        __populatePayCards( <% Html.RenderAction("GetLocalBankPayCards", new { paymentMethodName = this.Model.UniqueName });  %> );


        $('#btnDepositWithExistingCard').click(function (e) {
            e.preventDefault();

            // <%-- Validate the formRecentCards Form --%>
            if (!isDepositInputFormValid() || !$('#formRecentCards').valid())
                return false;
            $(this).toggleLoadingSpin(true);

            var payCardID = $('#hExistingPayCardID').val();
            var displayNumber = $('#payCard_' + payCardID).data('displaynumber');
            var bankName = $('#payCard_' + payCardID).data('bankname');
            tryToContinueConfirmStep(payCardID, bankName, displayNumber, function () { 
                        $('#btnDepositWithExistingCard').toggleLoadingSpin(false); 
                    }
                );
        });


        $('#btnRegisterCardAndDeposit').click(function (e) {
            e.preventDefault();
        
            if (!isDepositInputFormValid() || !$('#formRegisterPayCard').valid())
                return false;

            $(this).toggleLoadingSpin(true);

            var options = {
                dataType: "json",
                type: 'POST',
                success: function (json) {
                    // <%-- the card is successfully registered, now prepare the transaction --%>
                    if (!json.success) {
                        $('#btnRegisterCardAndDeposit').toggleLoadingSpin(false);
                        showDepositError(json.error);
                        return;
                    }
                    __loadRecentPayCards(json.payCardID);

                    var displayNumber = $('#txtBankAccountNo').val();
                    if(displayNumber == '')
                        displayNumber = $('#txtCitizenID').val();
                    var bankName = $('#txtBankName').val();;
                    // <%-- post the prepare form --%>   
                    tryToContinueConfirmStep(json.payCardID, bankName, displayNumber, function () {
                        $('#btnRegisterCardAndDeposit').toggleLoadingSpin(false);
                    });
                },
                error: function (xhr, textStatus, errorThrown) {
                    $('#btnRegisterCardAndDeposit').toggleLoadingSpin(false);
                }
            };
            $('#formRegisterPayCard').ajaxForm(options);
            $('#formRegisterPayCard').submit();
        });
    });
</script>