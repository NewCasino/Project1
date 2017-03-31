<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script language="C#" type="text/C#" runat="server">
    private bool ShowExtraFields
    {
        get
        {
            return false;
        }
    }
    
    private List<SelectListItem> GetMonthList()
    {
        List<SelectListItem> list = new List<SelectListItem>();
        list.Add(new SelectListItem() { Text = this.GetMetadata(".Month"), Value = "", Selected = true });

        for (int i = 1; i <= 12; i++)
        {
            list.Add(new SelectListItem() { Text = string.Format("{0:00}", i), Value = string.Format("{0:00}", i) });
        }

        return list;
    }

    private List<SelectListItem> GetExpiryYears()
    {
        List<SelectListItem> list = new List<SelectListItem>();
        list.Add(new SelectListItem() { Text = this.GetMetadata(".Year"), Value = "", Selected = true });

        int startYear = DateTime.Now.Year;
        for (int i = 0; i < 20; i++)
        {
            list.Add(new SelectListItem() { Text = (startYear + i).ToString(), Value = (startYear + i).ToString() });
        }

        return list;
    }

    private List<SelectListItem> GetValidFromYears()
    {
        List<SelectListItem> list = new List<SelectListItem>();
        list.Add(new SelectListItem() { Text = this.GetMetadata(".Year"), Value = "", Selected = true });

        int startYear = DateTime.Now.Year;
        for (int i = -20; i <= 0; i++)
        {
            list.Add(new SelectListItem() { Text = (startYear + i).ToString(), Value = (startYear + i).ToString() });
        }

        return list;
    }



</script>



<ui:tabbedcontent id="tabbedPayCards" runat="server">
    <tabs>


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
                            <input type="radio" name="existingPayCard" value="<#= d[i].ID.htmlEncode() #>" id="payCard_<#= d[i].ID.htmlEncode() #>"/>
                            <label for="payCard_<#= d[i].ID.htmlEncode() #>" dir="ltr">
                                <#= d[i].DisplayNumber.htmlEncode() #> (<#= d[i].ExpiryDate.htmlEncode() #> <#= d[i].CardName #>)
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
                    CVC
                -------------------------%>    
                <ui:InputField ID="fldCVC2" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	                <LabelPart><%= this.GetMetadata(".CardSecurityCode_Label").SafeHtmlEncode()%></LabelPart>
	                <ControlPart>
                        <%: Html.TextBox("cardSecurityCode", "", new 
                        { 
                            @maxlength = 4,
                            @validator = ClientValidators.Create()
                            .Required(this.GetMetadata(".CardSecurityCode_Empty"))
                            .Custom("validateCardSecurityCode") 
                        } 
                        )%>
	                </ControlPart>
                </ui:InputField>
                <script language="javascript" type="text/javascript">
                    //<![CDATA[
                    $(document).ready(function () {
                        $('#fldCVC2 input[id="cardSecurityCode"]').allowNumberOnly();
                    });
                    //]]>
                </script>

                <table style="width: 100%;">
                    <tr>
                        <td><%=this.GetMetadata(".TC_Link")%></td>
                        <td>
                           <div style="margin-left:auto; margin-right:0;">
                             <%: Html.Button(this.GetMetadata(".Button_Continue"), new{ @id = "btnDepositWithExistingCard", @class="ContinueButton button",})%>
                            </div>
                        </td>
                    </tr>
                    <tr>
                        <td style="width: 55%;">&nbsp;</td>
                        <td>
                           <div style="float: right; padding-right: 40px;">
                               <%=this.GetMetadata(".EWallet_Link")%>
                            </div>
                        </td>
                    </tr>
                </table>

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
                        @maxlength = 16,
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
                    var ret = /^(\d{9,16})$/.exec(value);
                    if (ret == null || ret.length == 0)
                        return '<%= this.GetMetadata(".CardNumber_Invalid").SafeJavascriptStringEncode() %>';
                    return true;
                }
                //]]>
            </script>


            <%------------------------
                Card Holder Name
              -------------------------%>    
            <ui:InputField ID="fldCardHolderName" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".CardHolderName_Label").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>
                    <%: Html.TextBox("ownerName", "", new 
                    { 
                        @maxlength = 30,
                        @validator = ClientValidators.Create().Required(this.GetMetadata(".CardHolderName_Empty")) 
                    } 
                    )%>
	            </ControlPart>
            </ui:InputField>


            <%------------------------
                Valid From
              -------------------------%> 
            <% if (this.ShowExtraFields)
               {  %>           
            <ui:InputField ID="fldCardValidFrom" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".ValidFrom_Label").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>
                    <table cellpadding="0" cellspacing="0" border="0">
                        <tr>
                            <td>
                            <%: Html.DropDownList("validFromMonth", GetMonthList(), new
                            {
                                @id = "ddlValidFromMonth",
                            } 
                            )%>
                            </td>
                            <td>&#160;</td>
                            <td>
                            <%: Html.DropDownList("validFromYear", GetValidFromYears(), new
                            {
                                @id = "ddlValidFromYear",
                            } 
                            )%>
                            <%: Html.Hidden("validFrom","") %>
                            </td>
                        </tr>
                    </table>
	            </ControlPart>
            </ui:InputField>
            <script language="javascript" type="text/javascript">
                //<![CDATA[
                $(document).ready(function () {
                    var fun = function () {
                        var month = $('#ddlValidFromMonth').val();
                        var year = $('#ddlValidFromYear').val();
                        var value = '';
                        if (month.length > 0 && year.length > 0)
                            value = year + '-' + month + '-01';
                        $('#fldCardValidFrom input[name="validFrom"]').val(value);
                        if (value.length > 0)
                            InputFields.fields['fldCardValidFrom'].validator.element($('#fldCardValidFrom input[name="validFrom"]'));
                        else {
                            var _field = $('#fldCardValidFrom');
                            _field.removeClass("incorrect").removeClass("correct");
                            _field.find("label.error").hide();
                            _field.siblings(".bubbletip[elementid='" + _field.attr("id") + "']").hide();
                        }
                    };
                    $('#ddlValidFromMonth').change(fun);
                    $('#ddlValidFromYear').change(fun);
                });
                //]]>
            </script>
            <% } %>

            <%------------------------
                Expiry Date
              -------------------------%>    
            <ui:InputField ID="fldCardExpiryDate" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".CardExpiryDate_Label").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>
                    <table cellpadding="0" cellspacing="0" border="0">
                        <tr>
                            <td>
                            <%: Html.DropDownList("expiryMonth", GetMonthList(), new
                            {
                                @id="ddlExpiryMonth"
                            } 
                            )%>
                            </td>
                            <td>&#160;</td>
                            <td>
                            <%: Html.DropDownList("expiryYear", GetExpiryYears(), new
                            {
                                @id = "ddlExpiryYear"
                            } 
                            )%>
                            <%: Html.Hidden("expiryDate","", new 
                                {
                                    @validator = ClientValidators.Create().Required(this.GetMetadata(".CardExpiryDate_Empty")) 
                                } ) %>
                            </td>
                        </tr>
                    </table>
	            </ControlPart>
            </ui:InputField>
            <script language="javascript" type="text/javascript">
                //<![CDATA[
                $(document).ready(function () {
                    var fun = function () {
                        $(document).unbind("click");
                        var month = $('#ddlExpiryMonth').val();
                        var year = $('#ddlExpiryYear').val();
                        var value = '';
                        if (month.length > 0 && year.length > 0)
                            value = year + '-' + month + '-01';
                        $('#fldCardExpiryDate input[name="expiryDate"]').val(value);
                        //if (value.length > 0)
                        InputFields.fields['fldCardExpiryDate'].validator.element($('#fldCardExpiryDate input[name="expiryDate"]'));
                    };

                    $('#fldCardExpiryDate input[name="expiryDate"]').click(fun);                    

                    var isExpiryDateTriggered = false;
                    $(document).bind("VALID_CARD_EXPIRY_DATE", fun);
                    $('#ddlExpiryMonth').click(function (e) {
                        e.preventDefault();
                        isExpiryDateTriggered = true;
                        $(document).click(fun);
                        return false;
                    });
                    $('#ddlExpiryYear').click(function (e) {
                        e.preventDefault();
                        isExpiryDateTriggered = true;
                        $(document).click(fun);
                        return false;
                    });

                    $('#ddlExpiryMonth').change(function (e) {
                        e.preventDefault();
                        if (!isExpiryDateTriggered)
                            fun();
                    });
                    $('#ddlExpiryYear').change(function (e) {
                        e.preventDefault();
                        if (!isExpiryDateTriggered)
                            fun();
                    });
                });
                //]]>
            </script>



            <%------------------------
                Card Issue Number
              -------------------------%>    
            <% if (this.ShowExtraFields)
               {  %>
            <ui:InputField ID="fldCardIssueNumber" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".CardIssueNumber_Label").SafeHtmlEncode()%> <%= this.GetMetadata(".Text_Optional").SafeHtmlEncode() %></LabelPart>
	            <ControlPart>
                    <%: Html.TextBox("issueNumber", "", new 
                    { 
                        @maxlength = 16
                    } 
                    )%>
	            </ControlPart>
            </ui:InputField>
            <div class="floatGuideBox cardIssueNumberGuide" id="cardIssueNumberGuide" >
                <%=this.GetMetadata(".CardIssueNumber_Guide").HtmlEncodeSpecialCharactors() %>
            </div>
            <script type="text/javascript">//<![CDATA[
                $("#issueNumber").focus(function () {
                    $("#cardIssueNumberGuide").slideDown();
                });
                $("#issueNumber").focusout(function () {
                    $("#cardIssueNumberGuide").slideUp();
                });
                
                $(document).ready(function () { $("#cardIssueNumberGuide").hide();});
                //]]>
            </script>
            <% } %>

            <%------------------------
                CVC 
              -------------------------%>    
            <ui:InputField ID="fldCVC" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	            <LabelPart><%= this.GetMetadata(".CardSecurityCode_Label").SafeHtmlEncode()%></LabelPart>
	            <ControlPart>
                    <%: Html.TextBox("cardSecurityCode", "", new 
                    { 
                        @maxlength = 4,
                        @validator = ClientValidators.Create()
                        .Required(this.GetMetadata(".CardSecurityCode_Empty"))
                        .Custom("validateCardSecurityCode") 
                    } 
                    )%>
	            </ControlPart>
            </ui:InputField>
            
            <div class="floatGuideBox cardSecurityNumberGuide" id="cardSecurityCodeGuide" >
                <%=this.GetMetadata(".CardSecurityCode_Guide").HtmlEncodeSpecialCharactors() %>
            </div> 
            <script type="text/javascript">
                //<![CDATA[
                $(document).ready(function () {
                    $('#fldCVC input[id="cardSecurityCode"]').allowNumberOnly();
                    $("#cardSecurityCodeGuide").hide();
                });

                $("#formRegisterPayCard #cardSecurityCode").focus(function () {
                    $("#cardSecurityCodeGuide").slideDown();
                });
                $("#formRegisterPayCard #cardSecurityCode").focusout(function () {
                    $("#cardSecurityCodeGuide").slideUp();
                });
                //]]>
            </script>

                <table style="width: 100%;">
                    <tr>
                        <td><%=this.GetMetadata(".TC_Link")%></td>
                        <td>
                           <div style="margin-left:auto; margin-right:0;">
                               
                               <%: Html.Button(this.GetMetadata(".Button_Continue"), new
                                        {
                                            @id = "btnRegisterCardAndDeposit", @class="ContinueButton button"
                                        }) %>
                            </div>
                        </td>
                    </tr>
                    <tr>
                        <td style="width: 55%;">&nbsp;</td>
                        <td>
                           <div style="float: right; padding-right: 40px;">
                               <%=this.GetMetadata(".EWallet_Link")%>
                            </div>
                        </td>
                    </tr>

                </table>

        </form>


        <%-- if (string.Equals(this.Model.UniqueName, "PT_MasterCard", StringComparison.OrdinalIgnoreCase))
           { %>
                <%: Html.WarningMessage(this.GetMetadata(".Message_IntercashCard"), true, new { @id = "warningIntercashCard" })%>
        <% } --%>
        </ui:Panel>





    </tabs>
</ui:tabbedcontent>



<script language="javascript" type="text/javascript">
    //<![CDATA[
    function validateCardSecurityCode() {
        var value = this;
        if(<%= (!( string.Equals(this.Model.UniqueName, "PT_Maestro", StringComparison.InvariantCultureIgnoreCase) || string.Equals(this.Model.UniqueName, "PT_MasterCard", StringComparison.InvariantCultureIgnoreCase) )).ToString().ToLowerInvariant() %>)
        {
            var ret = /^(\d{3,4})$/.exec(value);
        if (ret == null || ret.length == 0)
            return '<%= this.GetMetadata(".CardSecurityCode_Invalid").SafeJavascriptStringEncode() %>';
    }
    return true;
    }

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
        if (json.payCards.length > 0) {
            $('#tabbedPayCards').showTab('tabRecentCards', true);
            $('#tabbedPayCards').selectTab('tabRecentCards');

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

        function validCardValidFrom()
        {
            var _field = $("#formRegisterPayCard #fldCardValidFrom");
            if(_field.length==0)
                return true;

            var month = _field.find('#ddlValidFromMonth').val();
            var year = _field.find('#ddlValidFromYear').val();
    
            if ((month.length == 0 && year.length > 0) || (month.length > 0 && year.length == 0))
                return InputFields.fields['fldCardValidFrom'].validator.element($('#fldCardValidFrom input[name="validFrom"]'));
            else
            {
                _field.removeClass("incorrect");
                _field.find("label.error").hide();
                _field.siblings(".bubbletip[elementid='" + _field.attr("id") + "']").hide();
            }
            return true;
        }
        function validCardExpiryDate()
        {
            var $_tag = $('#fldCardExpiryDate input[name="expiryDate"]');
            $_tag.trigger('click');
            return InputFields.fields['fldCardExpiryDate'].validator.element($_tag);
        }

        $(document).ready(function () {
            $('#formRegisterPayCard').initializeForm();
            $('#formRecentCards').initializeForm();
    
<% if (!string.IsNullOrEmpty(Request["payCardID"]))
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

            $('#btnRegisterCardAndDeposit').click(function(e) {
                e.preventDefault();

                if (!isDepositInputFormValid() || !$('#formRegisterPayCard').valid() || !validCardExpiryDate() || !validCardValidFrom())
                    return false;

                $(this).toggleLoadingSpin(true);

                var options = {
                    dataType: "json",
                    type: 'POST',
                    success: function(json) {
                        // <%-- the card is successfully registered, now prepare the transaction --%>
                        if (!json.success) {
                            $('#btnRegisterCardAndDeposit').toggleLoadingSpin(false);
                            showDepositError(json.error);
                            return;
                        }

                        $('#fldCVC2 input[name="cardSecurityCode"]').val($('#fldCVC input[name="cardSecurityCode"]').val());
                        __loadRecentPayCards(json.payCardID);
                        // <%-- post the prepare form --%>   
                        tryToSubmitDepositInputForm(json.payCardID, function() {
                            $('#btnRegisterCardAndDeposit').toggleLoadingSpin(false);
                        });
                    },
                    error: function(xhr, textStatus, errorThrown) {
                        $('#btnRegisterCardAndDeposit').toggleLoadingSpin(false);
                    }
                };
                $('#formRegisterPayCard').ajaxForm(options);
                $('#formRegisterPayCard').submit();
            });

    // <%-- bind event to DEPOSIT_TRANSACTION_PREPARED --%>
            $(document).bind('DEPOSIT_TRANSACTION_PREPARED', function(e, sid) {
                var url = '<%= this.Url.RouteUrl( "Deposit", new { @action = "SaveSecurityKey" }).SafeJavascriptStringEncode() %>';
                var data = { sid: sid, securityKey: $('#fldCVC2 input[name="cardSecurityCode"]').val() };
                jQuery.getJSON(url, data, function(json) {
                    if (!json.success) {
                        showDepositError(json.error);
                        return;
                    }
                });
            });

            $('.tcLink').click(function() {

                //window.open(URL,name,specs,replace)
                window.open('http://cdn.everymatrix.com/EMTC.html', '_blank', 'height=500,width=600,menubar=no,scrollbars=no');
                return false;

            });

        });
        //]]>
</script>
