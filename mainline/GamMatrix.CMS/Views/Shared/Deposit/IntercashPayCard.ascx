<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>


<script language="C#" type="text/C#" runat="server">


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
                    <script id="pay-card-template" type="text/html">
                    <#
                        var d=arguments[0];

                        for(var i=0; i < d.length; i++)     
                        {        
                            if( d[i].IsDummy ) continue;
                    #>
                        <li>
                            <input type="radio" name="existingPayCard" value="<#= d[i].ID.htmlEncode() #>" id="payCard_<#= d[i].ID.htmlEncode() #>"/>
                            <label for="payCard_<#= d[i].ID.htmlEncode() #>" dir="ltr">
                                <#= d[i].DisplayNumber.htmlEncode() #> 
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

                <br />
                <%------------------------
                    Secret Access Code
                -------------------------%>    
                <ui:InputField ID="fldSecretAccessCode2" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	                <LabelPart><%= this.GetMetadata(".CardSecurityCode_Label").SafeHtmlEncode()%></LabelPart>
	                <ControlPart>
                        <%: Html.TextBox("cardSecurityCode", "", new 
                        { 
                            @maxlength = 23,
                            @validator = ClientValidators.Create().Required(this.GetMetadata(".CardSecurityCode_Empty"))
                        } 
                        )%>
	                </ControlPart>
                </ui:InputField>

                <center>
                    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id="btnDepositWithExistingCard", @class="ContinueButton button" })%>
                </center>
            </form>

        </ui:Panel>


        <%---------------------------------------------------------------
            Register a card
         ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabRegister" Selected="true" Caption="<%$ Metadata:value(.Tabs_RegisterPayCard) %>">

        
        <form id="formRegisterPayCard" onsubmit="return false" method="post" action="<%= this.Url.RouteUrl("Deposit", new { @action = "RegisterPayCard", @vendorID=this.Model.VendorID }).SafeHtmlEncode() %>" enctype="application/x-www-form-urlencoded">

            <%------------------------
                Card Number
              -------------------------%>    
            <ui:InputField ID="fldCardNumber" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".CardNumber_Label").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>
                    <%: Html.TextBox("identityNumber", "", new 
                    { 
                        @maxlength = 23,
                        @dir = "ltr",
                        @validator = ClientValidators.Create()
                            .Required(this.GetMetadata(".CardNumber_Empty")) 
                            .Custom("validateCardNumber")
                    } 
                    )%>
	            </ControlPart>
            </ui:InputField>
            <script language="javascript" type="text/javascript">
            //<![CDATA[
                $(document).ready(function () {
                    $('#fldCardNumber input[id="identityNumber"]').allowNumberOnly();
                });
                function validateCardNumber() {
                    var value = this;
                    var ret = /^(\d{9,23})$/.exec(value);
                    if (ret == null || ret.length == 0)
                        return '<%= this.GetMetadata(".CardNumber_Invalid").SafeJavascriptStringEncode() %>';
                    return true;
                }
            //]]>
            </script>


            <%------------------------
                Secret Access Code
            -------------------------%>    
            <ui:InputField ID="fldSecretAccessCode" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".CardSecurityCode_Label").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>
                    <%: Html.TextBox("cardSecurityCode", "", new 
                    { 
                        @maxlength = 23,
                        @validator = ClientValidators.Create().Required(this.GetMetadata(".CardSecurityCode_Empty"))
                    } 
                    )%>
	            </ControlPart>
            </ui:InputField>

        <center>
            <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id = "btnRegisterCardAndDeposit", @class="ContinueButton button" })%>
        </center>

        </form>

        </ui:Panel>





    </Tabs>
</ui:TabbedContent>



<script language="javascript" type="text/javascript">
//<![CDATA[
function __populatePayCards(json) {
    if (!json.success) {
        showDepositError(json.error);
        return;
    }
    $('#hExistingPayCardID').val('');
    $('#paycards-selector').html($('#pay-card-template').parseTemplate(json.payCards));
    $('#paycards-selector input[name="existingPayCard"]').click(function () {
        $('#hExistingPayCardID').val($(this).val());
        InputFields.fields['fldExistingPayCard'].validator.element($('#hExistingPayCardID'));
    });

    // <%-- if more than one pay card, select the first one tab and first pay card --%>
    var cardCount = $('#paycards-selector > li').length;
    if (cardCount > 0) {
        $('#tabbedPayCards').showTab('tabRecentCards', true);
        $('#tabbedPayCards').selectTab('tabRecentCards');
        // <%-- if more than 3 cards, hide the registration tab, note, there is one dummy card --%>
        if (cardCount >= <%=Settings.Payments_Card_CountLimit.ToString() %> ) {
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
    var url = '<%= this.Url.RouteUrl( "Deposit", new { @action="GetPayCards", @vendorID=this.Model.VendorID, @paymentMethodName = this.Model.UniqueName }).SafeJavascriptStringEncode() %>';
    jQuery.getJSON(url, null, __populatePayCards);
}

$(document).ready(function () {

    $('#formRegisterPayCard').initializeForm();
    $('#formRecentCards').initializeForm();
    
<% if( !string.IsNullOrEmpty(Request["payCardID"]) )
   { %>
   $('#paycards-selector').data('payCardID', '<%= Request["payCardID"] %>');
<% } %>
    
    __populatePayCards( <% Html.RenderAction("GetPayCards", new { vendorID = this.Model.VendorID, paymentMethodName = this.Model.UniqueName });  %> );

    $('#btnDepositWithExistingCard').click(function (e) {
        e.preventDefault();

        // <%-- Validate the formRecentCards Form --%>
        if (!isDepositInputFormValid() || !$('#formRecentCards').valid())
            return false;
        $(this).toggleLoadingSpin(true);
        tryToSubmitDepositInputForm($('#hExistingPayCardID').val()
            , function () { $('#btnDepositWithExistingCard').toggleLoadingSpin(false); }
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

                $('#fldSecretAccessCode2 input[name="cardSecurityCode"]').val($('#fldSecretAccessCode input[name="cardSecurityCode"]').val());
                __loadRecentPayCards(json.payCardID);
                // <%-- post the prepare form --%>   
                tryToSubmitDepositInputForm(json.payCardID, function () {
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

    // <%-- bind event to DEPOSIT_TRANSACTION_PREPARED --%>
    $(document).bind('DEPOSIT_TRANSACTION_PREPARED', function (e, sid) {
        var url = '<%= this.Url.RouteUrl( "Deposit", new { @action = "SaveSecurityKey" }).SafeJavascriptStringEncode() %>';
        var data = { sid: sid, securityKey: $('#fldSecretAccessCode2 input[name="cardSecurityCode"]').val() };
        jQuery.getJSON(url, data, function (json) {
            if (!json.success) {
                showDepositError(json.error);
                return;
            }
        });
    });
});
//]]>
</script>


