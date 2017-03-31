<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>

<script language="C#" runat="server" type="text/C#">
    private PayCardInfoRec GetPayCard()
    {
        switch (this.Model.UniqueName)
        {
            case "Envoy_WebMoney": break;
            case "Envoy_Moneta": break;
            case "Envoy_InstaDebit": break;
            case "Envoy_SpeedCard": break;
            default: throw new NotSupportedException(this.Model.UniqueName);
        }
        var payCards = GamMatrixClient.GetPayCards(VendorID.Envoy);
        return payCards
            .Where( p => string.Equals( p.BankName, this.Model.SubCode, StringComparison.OrdinalIgnoreCase) )
            .OrderByDescending(p => p.LastSuccessDepositDate)
            .First(p => !p.IsDummy);
    }
</script>
<%---------------------------------------------------------------
Envoy One-Click Service
----------------------------------------------------------------%>
<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <Tabs>
        <ui:Panel runat="server" ID="tabRecentCards" Caption="<%$ Metadata:value(.Tab_ExistingPayCards) %>">

<form id="formEnvoyOneClickPayCard" onsubmit="return false">
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
        <%: Html.Button(this.GetMetadata(".Button_Back"), new { @id="btnWithdrawBack", @type = "button", @onclick=string.Format( "self.location='{0}';return false;", this.Url.RouteUrl( "Withdraw", new { @action = "Index" } ).SafeJavascriptStringEncode()) })%>
        <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnWithdrawWithEnvoyOneClickPayCard" })%>
    </center>
</form>
        </ui:Panel>


        <%---------------------------------------------------------------
                Register WebMoney Account
        ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabRegisterWebMoney" Caption="<%$ Metadata:value(.Tab_RegisterPayCard) %>">
            <form id="formRegisterWebMoneyPayCard" method="post" action="<%= this.Url.RouteUrl("Withdraw", new { @action = "RegisterEnvoyOnClickPayCard", @vendorID=this.Model.VendorID, @paymentMethodName = this.Model.UniqueName }).SafeHtmlEncode() %>" enctype="application/x-www-form-urlencoded">
            <%---------------------------------------------------------------
                    Register a card
            ----------------------------------------------------------------%>
            <ui:InputField ID="fldRegisterWebMoneyPayCard" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".PurseNumber").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>
                    <%: Html.TextBox("identityNumber", "", new 
                        { 
                            @maxlength = 30,
                            @dir = "ltr",
                            @validator = ClientValidators.Create().Required(this.GetMetadata(".PurseNumber_Empty"))
                        } 
                        )%>
                </ControlPart>
            </ui:InputField>

            

            <center>
                <%: Html.Button(this.GetMetadata(".Button_Back"), new { @type = "button", @onclick = string.Format("$(this).toggleLoadingSpin(true);self.location='{0}';return false;", this.Url.RouteUrl("Withdraw", new { @action = "Index" }).SafeJavascriptStringEncode()) })%>
                <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnRegisterWebMoneyPayCard" })%>
            </center>
            </form>
        </ui:Panel>

    </Tabs>
</ui:TabbedContent>


<script language="javascript" type="text/javascript">
    $(document).ready(function () {
        $('#formEnvoyOneClickPayCard').initializeForm();
        $('#formRegisterWebMoneyPayCard').initializeForm();

        __populatePayCards( <% Html.RenderAction("GetPayCards", new { vendorID = this.Model.VendorID, paymentMethodName = this.Model.UniqueName });  %> );

        $('#btnWithdrawWithEnvoyOneClickPayCard').click(function (e) {
            e.preventDefault();

            if (!isWithdrawInputFormValid())
                return;

            $('#btnWithdrawWithEnvoyOneClickPayCard').toggleLoadingSpin(true);
            tryToSubmitWithdrawInputForm($('#hExistingPayCardID').val(), function () { $('#btnWithdrawWithEnvoyOneClickPayCard').toggleLoadingSpin(false); });
        });

        $('#btnRegisterWebMoneyPayCard').click(function (e) {
            e.preventDefault();

            if (!isWithdrawInputFormValid() || !$('#formRegisterWebMoneyPayCard').valid())
                return;

            $(this).toggleLoadingSpin(true);

            var options = {
                dataType: "json",
                type: 'POST',
                success: function (json) {
                    // <%-- the card is successfully registered, now prepare the transaction --%>
                    if (!json.success) {
                        $('#btnRegisterWebMoneyPayCard').toggleLoadingSpin(false);
                        showWithdrawError(json.error);
                        return;
                    }

                    __loadRecentPayCards(json.payCardID);
                    // <%-- post the prepare form --%>   
                    tryToSubmitWithdrawInputForm(json.payCardID, function () {
                        $('#btnRegisterWebMoneyPayCard').toggleLoadingSpin(false);
                    });
                },
                error: function (xhr, textStatus, errorThrown) {
                    $('#btnRegisterWebMoneyPayCard').toggleLoadingSpin(false);
                }
            };
            $('#formRegisterWebMoneyPayCard').ajaxForm(options);
            $('#formRegisterWebMoneyPayCard').submit();
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

    // <%-- Recent card tab --%>
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
        }
        if( $('#paycards-selector :checked').length == 0 )
            $('#paycards-selector input:first').trigger('click');
    } else { // <%-- hide the recent cards tab and select register tab --%>
        $('#tabbedPayCards').showTab('tabRecentCards', false);
    }

    $('#tabbedPayCards').showTab('tabRegisterWebMoney', false);
<% if( string.Equals( this.Model.UniqueName, "Envoy_WebMoney", StringComparison.OrdinalIgnoreCase) )
   { %>
        $('#tabbedPayCards').showTab('tabRegisterWebMoney', true);
        if( json.payCards.length == 0 )
            $('#tabbedPayCards').selectTab('tabRegisterWebMoney');
<% } %>

            
        
};
    
</script>

