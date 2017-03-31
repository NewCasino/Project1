<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<p>
    <%: Html.WarningMessage( this.GetMetadata(".WarningMessage") ) %>
</p>

<%---------------------------------------------------------------
TLNakit
----------------------------------------------------------------%>
<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <tabs>

    <%---------------------------------------------------------------
            Existing Cards
    ----------------------------------------------------------------%>
    <ui:Panel runat="server" ID="tabRecentCards" Caption="<%$ Metadata:value(.Tab_ExistingPayCards) %>">
        <%---------------------------------------------------------------
        TLNakit
        ----------------------------------------------------------------%>
        <form id="formTLNakitPayCard" onsubmit="return false">

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
                <li>
                    <input type="radio" name="existingPayCard" value="<#= d[i].ID.htmlEncode() #>" id="payCard_<#= d[i].ID.htmlEncode() #>"/>
                    <label for="payCard_<#= d[i].ID.htmlEncode() #>" dir="ltr">
                        <#= d[i].DisplayNumber.htmlEncode() #>
                    </label>
                </li>

            <#  }  #>
            </script>   


            <center>
                <%: Html.Button(this.GetMetadata(".Button_Back"), new { @type = "button", @onclick = string.Format("$(this).toggleLoadingSpin(true);self.location='{0}';return false;", this.Url.RouteUrl("Withdraw", new { @action = "Index" }).SafeJavascriptStringEncode()) })%>
                <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnWithdrawWithTLNakitPayCard" })%>
            </center>
        </form>

    </ui:Panel>

    <%---------------------------------------------------------------
            Register Card
    ----------------------------------------------------------------%>
    <ui:Panel runat="server" ID="tabRegister" Caption="<%$ Metadata:value(.Tab_RegisterPayCard) %>">
        <form id="formRegisterTLNakitPayCard" method="post" action="<%= this.Url.RouteUrl("Deposit", new { @action = "RegisterPayCard", @vendorID=this.Model.VendorID }).SafeHtmlEncode() %>" enctype="application/x-www-form-urlencoded">
            <%---------------------------------------------------------------
                    Register a card
            ----------------------------------------------------------------%>
            <ui:InputField ID="fldRegisterPayCard" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".TLNakitUsername_Label").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>
                    <%: Html.TextBox("identityNumber", "", new 
                        { 
                            @maxlength = 50,
                            @dir = "ltr",
                            @validator = ClientValidators.Create().Required(this.GetMetadata(".TLNakitUsername_Empty"))
                        } 
                        )%>
                </ControlPart>
            </ui:InputField>

            <center>
                <%: Html.Button(this.GetMetadata(".Button_Back"), new { @type = "button", @onclick = string.Format("$(this).toggleLoadingSpin(true);self.location='{0}';return false;", this.Url.RouteUrl("Withdraw", new { @action = "Index" }).SafeJavascriptStringEncode()) })%>
                <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnRegisterPayCard" })%>
            </center>
            </form>
    </ui:Panel>

</tabs>
</ui:TabbedContent>

<script type="text/javascript">
    function __customValidateAmount(amount) {
        if ((amount % 1.00) > 0.00)
            return '<%= this.GetMetadata(".InvalidAmount").SafeJavascriptStringEncode() %>';
    return true;
}

$(function () {
    $('#formPrepareWithdraw #ddlCurrency option[value!="TRY"]').remove();

    $('#formTLNakitPayCard').initializeForm();
    $('#formRegisterTLNakitPayCard').initializeForm();

    __populatePayCards( <% Html.RenderAction("GetPayCards", new { vendorID = this.Model.VendorID });  %>);

    $('#btnWithdrawWithTLNakitPayCard').click(function (e) {
        e.preventDefault();

        if (!isWithdrawInputFormValid())
            return;

        $('#btnWithdrawWithTLNakitPayCard').toggleLoadingSpin(true);
        tryToSubmitWithdrawInputForm($('#fldExistingPayCard input[name="existingPayCardID"]').val()
        , function () { $('#btnWithdrawWithTLNakitPayCard').toggleLoadingSpin(false); });
    });


    $('#btnRegisterPayCard').click(function (e) {
        e.preventDefault();

        if (!isWithdrawInputFormValid() || !$('#formRegisterTLNakitPayCard').valid())
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
        $('#formRegisterTLNakitPayCard').ajaxForm(options);
        $('#formRegisterTLNakitPayCard').submit();
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
    $('#hExistingPayCardID').val('');
    $('#paycards-selector').html($('#pay-card-template').parseTemplate(json.payCards));
    $('#paycards-selector input[name="existingPayCard"]').click(function () {
        $('#hExistingPayCardID').val($(this).val());
        InputFields.fields['fldExistingPayCard'].validator.element($('#hExistingPayCardID'));
    });

    // <%-- if more than one pay card, hide the registration tab --%>
    if (json.payCards.length > 0) {
        $('ul.tabs > li.tab[forid="tabRegister"] span', $('#tabbedPayCards')).html('<%= this.GetMetadata(".Tab_WithdrawToAnotherAccount_Label").Trim() %>');
        $('#tabbedPayCards').showTab('tabRegister', true);
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
        }

        if ($('#paycards-selector :checked').length == 0)
            $('#paycards-selector input:first').trigger('click');
    } else { // <%-- hide the recent cards tab and select register tab --%>
        $('ul.tabs > li.tab[forid="tabRegister"] span', $('#tabbedPayCards')).html('<%= this.GetMetadata(".Tab_RegisterPayCard").Trim() %>');
        $('#tabbedPayCards').selectTab('tabRegister');
        $('#tabbedPayCards').showTab('tabRegister', true);
        $('#tabbedPayCards').showTab('tabRecentCards', false);
    }
};
</script>
