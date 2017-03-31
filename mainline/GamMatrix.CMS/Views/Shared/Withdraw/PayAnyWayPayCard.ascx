<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<script type="text/C#" runat="server">
    private string GetBankName()
    {
        switch (this.Model.UniqueName)
        {
            case "PayAnyWay_Moneta":
                return "MONETA";
            case "PayAnyWay_Yandex":
                return "YANDEX";
            case "PayAnyWay_WebMoney":
                return "WEBMONEY";
            default:
                throw new NotSupportedException();
        }
    }

    private int GetAccountIDMaxLength()
    {
        switch (this.Model.UniqueName)
        {
            case "PayAnyWay_Moneta":
                return 10;
            case "PayAnyWay_Yandex":
                return 15;
            case "PayAnyWay_WebMoney":
                return 12;
            default:
                throw new NotSupportedException();
        }
    }
    protected override void OnPreRender(EventArgs e)
    {
        fldRegisterCardName.Visible = string.Equals(this.Model.UniqueName, "PayAnyWay_WebMoney", StringComparison.InvariantCultureIgnoreCase);
        base.OnPreRender(e);
    }
</script>

<%---------------------------------------------------------------
MONETA
----------------------------------------------------------------%>
<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <Tabs>

    <%---------------------------------------------------------------
            Existing Cards
    ----------------------------------------------------------------%>
    <ui:Panel runat="server" ID="tabRecentCards" Caption="<%$ Metadata:value(.Tab_ExistingPayCards) %>">
        <%---------------------------------------------------------------
        Moneybookers
        ----------------------------------------------------------------%>
        <form id="formMonetaPayCard" onsubmit="return false">

            <ui:InputField ID="fldExistingPayCard" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".WithdrawTo").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>
                    <ul id="paycards-selector">
            
                    </ul>
                    <%: Html.Hidden("existingPayCardID", "", new 
                    { 
                        @id = "hExistingPayCardID",
                        @validator = ClientValidators.Create().Required(this.GetMetadata(".ExistingCard_Empty")) 
                    }) %>
                </ControlPart>
            </ui:InputField>

            <script id="pay-card-template" type="text/html">
            <#
                var d=arguments[0];

                for(var i=0; i < d.length; i++)     
                {        
            #>
                <li data-bank="<#= d[i].BankName #>">
                    <input type="radio" name="existingPayCard" value="<#= d[i].ID.htmlEncode() #>" id="payCard_<#= d[i].ID.htmlEncode() #>"/>
                    <label for="payCard_<#= d[i].ID.htmlEncode() #>" dir="ltr">
                        <#= d[i].DisplayNumber.htmlEncode() #>
                    </label>
                </li>

            <#  }  #>
            </script>   


            <center>
                <%: Html.Button(this.GetMetadata(".Button_Back"), new { @type = "button", @onclick = string.Format("$(this).toggleLoadingSpin(true);self.location='{0}';return false;", this.Url.RouteUrl("Withdraw", new { @action = "Index" }).SafeJavascriptStringEncode()) })%>
                <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnWithdrawWithMonetaPayCard" })%>
            </center>
        </form>

    </ui:Panel>

    <%---------------------------------------------------------------
            Register Card
    ----------------------------------------------------------------%>
    <ui:Panel runat="server" ID="tabRegister" Caption="<%$ Metadata:value(.Tab_RegisterPayCard) %>">
        <form id="formRegisterMonetaPayCard" method="post" action="<%= this.Url.RouteUrl("Deposit", new { @action = "RegisterPayCard", @vendorID=this.Model.VendorID }).SafeHtmlEncode() %>" enctype="application/x-www-form-urlencoded">
            <%---------------------------------------------------------------
                    Register a card
            ----------------------------------------------------------------%>

            <%: Html.Hidden( "bankName", this.GetBankName()) %>
            <ui:InputField ID="fldRegisterPayCard" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".AccountID").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>
                    <%: Html.TextBox("identityNumber", "", new 
                        { 
                            @maxlength = GetAccountIDMaxLength(),
                            @dir = "ltr",
                            @validator = ClientValidators.Create().Required(this.GetMetadata(".Account_Empty"))
                            .Custom("validateAccountID")
                        } 
                        )%>
                </ControlPart>
            </ui:InputField>
            <script type="text/javascript">
                $(function () {
                    $('#fldRegisterPayCard input[name="identityNumber"]').allowNumberOnly();
                });
                function validateAccountID() {
                    var value = this;

                    var bankName = '<%= this.GetBankName() %>';
                    switch (bankName) {
                        case 'MONETA':
                            {
                                var REGEX = /^(\d{1,10})$/g;
                                var ret = REGEX.exec(value);
                                if (ret == null || ret.length == 0)
                                    return false;
                                return true;
                            }

                        case 'YANDEX':
                            {
                                var REGEX = /^(41001)(\d{7,10})$/g;
                                var ret = REGEX.exec(value);
                                if (ret == null || ret.length == 0)
                                    return '<%= this.GetMetadata(".Account_InvalidYandexID").SafeJavascriptStringEncode() %>';
                                return true;
                            }

                        case 'WEBMONEY':
                            {
                                var REGEX = /^(\d{1,12})$/g;
                                var ret = REGEX.exec(value);
                                if (ret == null || ret.length == 0)
                                    return false;
                                return true;
                            }
                    }
                    return true;
                }
            </script>

            <%-------------------------
            Web Money Purse
            ------------------------%>
            <ui:InputField ID="fldRegisterCardName" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".CardName").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>
                    <%: Html.TextBox("cardName", "", new 
                        { 
                            @maxlength = 13,
                            @dir = "ltr",
                            @validator = ClientValidators.Create().Required(this.GetMetadata(".CardName_Empty"))
                            .Custom("validateWebMoneyPurse")
                        } 
                        )%>
                </ControlPart>
            </ui:InputField>
            <script type="text/javascript">
                function validateWebMoneyPurse() {
                    var value = this;

                    var bankName = '<%= this.GetBankName() %>';
                    switch (bankName) {
                        case 'MONETA': return true; 

                        case 'YANDEX': return true; 

                        case 'WEBMONEY':
                            {
                                var REGEX = /^(R|Z|E|r|z|e)(\d{12,12})$/g;
                                var ret = REGEX.exec(value);
                                if (ret == null || ret.length == 0)
                                    return '<%= this.GetMetadata(".Invalid_Purse").SafeJavascriptStringEncode() %>';
                                return true;
                            }
                    }
                    return true;
                }
            </script>

            <center>
                <%: Html.Button(this.GetMetadata(".Button_Back"), new { @type = "button", @onclick = string.Format("$(this).toggleLoadingSpin(true);self.location='{0}';return false;", this.Url.RouteUrl("Withdraw", new { @action = "Index" }).SafeJavascriptStringEncode()) })%>
                <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnRegisterPayCard" })%>
            </center>
            </form>
    </ui:Panel>

</Tabs>
</ui:TabbedContent>

<script type="text/javascript">
$(function () {
    $('#formMonetaPayCard').initializeForm();
    $('#formRegisterMonetaPayCard').initializeForm();

    __populatePayCards( <% Html.RenderAction("GetPayCards", new { vendorID = this.Model.VendorID });  %> );

    $('#btnWithdrawWithMonetaPayCard').click(function (e) {
        e.preventDefault();

        if (!isWithdrawInputFormValid() )
            return;

        $('#btnWithdrawWithMonetaPayCard').toggleLoadingSpin(true);
        tryToSubmitWithdrawInputForm($('#fldExistingPayCard input[name="existingPayCardID"]').val()
        , function () { $('#btnWithdrawWithMonetaPayCard').toggleLoadingSpin(false); });
    });


    $('#btnRegisterPayCard').click(function (e) {
        e.preventDefault();

        if (!isWithdrawInputFormValid() || !$('#formRegisterMonetaPayCard').valid())
            return;

        $(this).toggleLoadingSpin(true);

        var options = {
            dataType: "json",
            type: 'POST',
            success: function (json) {
                // <%-- the card is successfully registered, now prepare the transaction --%>
                if (!json.success) {
                    $('#btnRegisterPayCard').toggleLoadingSpin(false);
                    showWithdrawError(json.error);
                    return;
                }

                __loadRecentPayCards(json.payCardID);
                // <%-- post the prepare form --%>   
                tryToSubmitWithdrawInputForm(json.payCardID, function () {
                    $('#btnRegisterPayCard').toggleLoadingSpin(false);
                });
            },
            error: function (xhr, textStatus, errorThrown) {
                $('#btnRegisterPayCard').toggleLoadingSpin(false);
            }
        };
        $('#formRegisterMonetaPayCard').ajaxForm(options);
        $('#formRegisterMonetaPayCard').submit();
    });
});
    

function __loadRecentPayCards(payCardID) {
    $('#paycards-selector').data('payCardID', payCardID);
    var url = '<%= this.Url.RouteUrl( "Withdraw", new { @action="GetPayCards", @vendorID=this.Model.VendorID }).SafeJavascriptStringEncode() %>';
    jQuery.getJSON(url, null, __populatePayCards);
}

function __populatePayCards(json) {
    if (!json.success) {
        showWithdrawError(json.error);
        return;
    }

    // <%-- delete payCards not belongs to this method --%>
    for( var i = json.payCards.length - 1; i >= 0; i--){
        if( json.payCards[i].BankName != '<%= this.GetBankName() %>' ){
            json.payCards.splice( i, 1);
        }
    }

    $('#hExistingPayCardID').val('');
    $('#paycards-selector').html($('#pay-card-template').parseTemplate(json.payCards));
    $('#paycards-selector input[name="existingPayCard"]').click(function () {
        $('#hExistingPayCardID').val($(this).val());
        InputFields.fields['fldExistingPayCard'].validator.element($('#hExistingPayCardID'));
    });

    // <%-- if more than one pay card, hide the registration tab --%>
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

        if( $('#paycards-selector :checked').length == 0 )
            $('#paycards-selector input:first').trigger('click');
    } else { // <%-- hide the recent cards tab and select register tab --%>
        $('#tabbedPayCards').selectTab('tabRegister');
        $('#tabbedPayCards').showTab('tabRegister', true);
        $('#tabbedPayCards').showTab('tabRecentCards', false);
    }
};
</script>