<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>

<script language="C#" type="text/C#" runat="server">

    private string _sdkUrl;
    private string _monitoringUrl;

    public IEnumerable<KeyValuePair<string, IEnumerable<string>>> ToHeaders(NameValueCollection collection)
    {
        return ToArray(collection.AllKeys, x => new KeyValuePair<string, IEnumerable<string>>(x, collection.GetValues(x)));
    }

    public TResult[] ToArray<TSource, TResult>(IEnumerable<TSource> source, Func<TSource, TResult> selector)
    {
        return source.Select(selector).ToArray();
    }

    public string FindHeader(IEnumerable<KeyValuePair<string, IEnumerable<string>>> headers, string name, bool tryToSplitAndGetFirstValueForNonStandardHeaders = true)
    {
        var header = headers
            .Where(x => x.Key.Equals(name, StringComparison.InvariantCultureIgnoreCase))
            .Select(x => x.Value.FirstOrDefault())
            .FirstOrDefault();

        // standard headers are grouped in value collection but others are pushed into collection as single string with comma-separated values
        if (!string.IsNullOrWhiteSpace(header) && tryToSplitAndGetFirstValueForNonStandardHeaders)
        {
            return header.Split(',').Where(x => !string.IsNullOrWhiteSpace(x)).Select(x => x.Trim()).FirstOrDefault();
        }

        return header;
    }

    private string GetSdkUrl()
    {
        return string.IsNullOrEmpty(_sdkUrl) ? _sdkUrl = GamMatrixClient.GetSdkUrl(Request.UserAgent, FindHeader(ToHeaders(Request.Headers), "X-Real-IP") ?? Request.UserHostAddress) : _sdkUrl;
    }

    private string GetMonitoringUrl()
    {
        return string.IsNullOrEmpty(_monitoringUrl) ? _monitoringUrl = GamMatrixClient.GetMonitoringUrl(Request.UserAgent, FindHeader(ToHeaders(Request.Headers), "X-Real-IP") ?? Request.UserHostAddress) : _monitoringUrl;
    }    

    private bool ShowExtraFields
    {
        get
        {
            if (string.Equals(this.Model.UniqueName, "PT_Maestro", StringComparison.InvariantCultureIgnoreCase)
                && (
                    !string.IsNullOrEmpty(this.GetMetadata(".IsHiddenIssueNumber")) && !string.Equals("No", this.GetMetadata(".IsHiddenIssueNumber"), StringComparison.InvariantCultureIgnoreCase))
                )
            {
                return true;
            }
            else
            {
                bool bolRlt = string.Equals(this.Model.UniqueName, "PT_MasterCard", StringComparison.InvariantCultureIgnoreCase) ||
                              string.Equals(this.Model.UniqueName, "PT_Switch", StringComparison.InvariantCultureIgnoreCase) ||
                              string.Equals(this.Model.UniqueName, "PT_Maestro", StringComparison.InvariantCultureIgnoreCase);
                if (bolRlt)
                {
                    string[] arrCartPT = this.GetMetadata(".HideIssueNumber").Split(new string[] { "," }, StringSplitOptions.RemoveEmptyEntries);
                    foreach (string pt in arrCartPT)
                    {
                        if (string.Compare(pt, this.Model.UniqueName, true) == 0)
                        {
                            bolRlt = false;
                            break;
                        }
                    }
                }
                return bolRlt;
            }
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


<script src="<%= GetMonitoringUrl() %>"></script>

<ui:TabbedContent ID="tabbedPayCards" runat="server">
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
                        <input type="hidden" id="hdnCardToken" />
                    <ul id="paycards-selector">
            
                    </ul>
                    <%-- <#= d[i].IsBelongsToPaymentMethod ? '' : 'disabled="disabled"' #> --%>
                    <script id="pay-card-template" type="text/html">
                    <#
                        var d=arguments[0];

                        for(var i=0; i < d.length; i++)
                        {
                            if (d[i].IsDummy == true){
                                continue;
                            }

                            var cardTypeValidateResult = $('<input value="'+ d[i].DisplayNumber +'"/>').validateCreditCard();
                            var cardType = cardTypeValidateResult.card_type ? cardTypeValidateResult.card_type.name : '';
                    #>
                        <li>
                            <input type="radio" name="existingPayCard" value="<#= d[i].ID.htmlEncode() #>" id="payCard_<#= d[i].ID.htmlEncode() #>" data-cardtoken="<#= d[i].RecordDisplayNumber.htmlEncode() #>"/>
                            <label for="payCard_<#= d[i].ID.htmlEncode() #>" dir="ltr" data-cardtype="<#= cardType.htmlEncode() #>">
                                <#= d[i].DisplayNumber.htmlEncode() #> (<#= d[i].ExpiryDate.htmlEncode() #> <#= d[i].OwnerName.htmlEncode() #>)
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
                <label><%= this.GetMetadata(".CardSecurityCode_Label").SafeHtmlEncode()%></label>
                <div id="dvCvv2Container"></div>
                <script language="javascript" type="text/javascript">
                    //<![CDATA[
                    $(document).ready(function () {
                        $('#fldCVC2 input[id="cardSecurityCode"]').allowNumberOnly();
                    });
                    //]]>
                </script>

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
                <div id="dvCardNumberWrapper">
                    <div class="card-type"></div>
                    <div id="dvCardNumberContainer"></div>
                </div>
                <input type="hidden" id="identityNumber" name="identityNumber" />
                <input type="hidden" id="displayNumber" name="displayNumber" />
                <input type="hidden" id="cardType" name="cardType" />
                <input type="hidden" name="cardName" id="hdnCardName" />
                <input type="hidden" name="IssuerCompany" id="hdnIssuerCompany" />
                <input type="hidden" name="IssuerCountry" id="hdnIssuerCountry" />
            </ControlPart>
            </ui:InputField>

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
                <div id="dvCvvContainer"></div>
                    <input type="hidden" id="cardSecurityCode" name="cardSecurityCode" />
            </ControlPart>
            </ui:InputField>
            
            <div class="floatGuideBox cardSecurityNumberGuide" id="cardSecurityCodeGuide" >
                <%=this.GetMetadata(".CardSecurityCode_Guide").HtmlEncodeSpecialCharactors() %>
            </div> 
        <center>
            <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @id = "btnRegisterCardAndDeposit", @class="ContinueButton button" })%>
        </center>

        </form>
    </ui:Panel>
    </tabs>
</ui:TabbedContent>

<script src="<%= GetSdkUrl() %>"></script>
<script src="<%= Url.Content("/js/jquery/jquery.creditCardValidator.js") %>"></script>

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
            $('#hdnCardToken').val($(this).attr('data-cardtoken'));
            InputFields.fields['fldExistingPayCard'].validator.element($('#hExistingPayCardID'));
        });

        // <%-- if more than one pay card, select the first one tab and first pay card --%>
        var realPayCardsLength = 0;

        for (var i = 0; i < json.payCards.length; i++) {
            if (json.payCards[i].IsDummy == false) {
                realPayCardsLength++;
            }
        }

        if (realPayCardsLength > 0) {
            $('#tabbedPayCards').showTab('tabRecentCards', true);
            $('#tabbedPayCards').selectTab('tabRecentCards');
            // <%-- if more than 3 cards, hide the registration tab --%>
            if (realPayCardsLength >= <%=Settings.Payments_Card_CountLimit.ToString() %>) {
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
        $('#formPrepareDeposit')
            .append($('<input type="hidden" name="MonitoringSessionId" id="hdnMonitoringSessionId"/>'));

        <% if (!string.IsNullOrEmpty(Request["payCardID"]))
   { %>
        $('#paycards-selector').data('payCardID', '<%= Request["payCardID"] %>');
        <% } %>
    
        __populatePayCards( <% Html.RenderAction("GetPayCards", new { vendorID = this.Model.VendorID, paymentMethodName = this.Model.UniqueName });  %> );

        $('#btnDepositWithExistingCard_Fake').click(function (e) {
            e.preventDefault();

            // <%-- Validate the formRecentCards Form --%>
            if (!isDepositInputFormValid() || !$('#formRecentCards').valid())
                return false;
            $(this).toggleLoadingSpin(true);
            tryToSubmitDepositInputForm($('#hExistingPayCardID').val()
                , function () { $('#btnDepositWithExistingCard').toggleLoadingSpin(false); }
            );
        });
    });
    //]]>
</script>
<%if( Settings.SafeParseBoolString( this.GetMetadata(".Support_Pop_Enabled"),false)) { %>
    <div id="_support_pop_" style="display:none;">
        <%=this.GetMetadata(".Support_Pop_Html") %>
    </div>
    <script type="text/javascript">
        window.showSupportPop = function(){
            $("#welcomePop").modal({ autoResize: true, maxHeight: 540,maxWidth: 400, containerCss: { border: "2px solid #050506", borderRadius: ".2em", backgroundColor: "#1d2127" } });
        }
    </script>
    <%} %>
<script>
    function initExistingCardForm() {
        var paymentForm = new CDE.PaymentForm({
                'card-security-code': {
                    selector: '#dvCvv2Container',
                    css: {
                        'font-size': '14px',
                        'height': '21px',
                        'line-height': '21px',
                        'font-family': 'Arial',
                        'color': '#333',
                        'background-color': 'white',
                        'text-align': 'center',
                        'vertical-align': 'middle',
                        'direction': 'ltr',
                        'border': '1px solid #FFF',
                        'border-radius': '4px'
                    },
                    placeholder: '<%= this.GetMetadata(".CardSecurityCode_Placeholder") %>'
                }
            }
        );

        var $btn = $('#btnDepositWithExistingCard');

        $btn.click(function (e) {
            e.preventDefault();

            if (!isDepositInputFormValid() || !$('#formRecentCards').valid())
                return false;
            if (typeof MMM != 'undefined') {
                $('#hdnMonitoringSessionId').val(MMM.getSession());
            }
            $btn.toggleLoadingSpin(true);

            var cardToken = $('#hdnCardToken').val();

            paymentForm.submitCvv({ CardToken: cardToken }).then(
                function (data) {
                    if (data.Success == true) {
                        $('#identityNumber').val(cardToken);

                        tryToSubmitDepositInputForm($('#hExistingPayCardID').val()
                            , function() {
                                $btn.toggleLoadingSpin(false);
                            }
                        );
                    } else {
                        alert('Error');
                    }
                },
                function (data) {
                    var message = data.detail ? data.detail : data.ResponseMessage;

                    alert(message);
                    $btn.toggleLoadingSpin(false);
                    $btn.prop('disabled', false);
                }
            );
        });
    }

    function initDepositForm(formSelector) {
        // initialize the sensitive fields
        var paymentForm = new CDE.PaymentForm({
                'card-number': {
                    selector: '#dvCardNumberContainer',
                    css: {
                        'font-size': '14px',
                        'height': '21px',
                        'line-height': '21px',
                        'font-family': 'Arial',
                        'color': '#333',
                        'background-color': 'white',
                        'text-align': 'left',
                        'vertical-align': 'middle',
                        'direction': 'ltr',
                        'border': '1px solid #FFF',
                        'border-radius': '4px',
                        'padding': '0 0 0 35px'
                    },
                    placeholder: '<%= this.GetMetadata(".CardNumber_Placeholder") %>',
                    format: true
                },
                'card-security-code': {
                    selector: '#dvCvvContainer',
                    css: {
                        'font-size': '14px',
                        'height': '21px',
                        'line-height': '21px',
                        'font-family': 'Arial',
                        'color': '#333',
                        'background-color': 'white',
                        'text-align': 'center',
                        'vertical-align': 'middle',
                        'direction': 'ltr',
                        'border': '1px solid #FFF',
                        'border-radius': '4px'
                    },
                    placeholder: '<%= this.GetMetadata(".CardSecurityCode_Placeholder") %>'
                }
            }
        );

        // hook the status change and reflect on UI
        paymentForm.fields['card-number'].on('status', function (evt, data) {
            $('#dvCardNumberWrapper .card-type').attr('data-cardtype', data.type);
            // $('#cardType').val(data.type);

            if (data.valid)
                $('#dvCardNumberContainer').addClass('valid');
            else
                $('#dvCardNumberContainer').removeClass('valid');
        }).on('field_focus', function () {
            $('#dvCardNumberContainer').addClass('focus');
        }).on('field_blur', function () {
            $('#dvCardNumberContainer').removeClass('focus');
        });

        paymentForm.fields['card-security-code'].on('status', function (evt, data) {

        }).on('field_focus', function () {
            $('#dvCvvContainer').addClass('focus');
        }).on('field_blur', function () {
            $('#dvCvvContainer').removeClass('focus');
        });

        var $btn = $('#btnRegisterCardAndDeposit');

        // when the fields are loaded, enable the submit button
        paymentForm.on('load', function () {
            $btn.prop('disabled', false);
        });

        paymentForm.on('error', function (e, data) {
          $btn.prop('disabled', true);
          alert(data.ResponseMessage);
        });

        // submit
        $btn.on('click', function (e) {
            e.preventDefault();
        
            if (!isDepositInputFormValid() || !$('#formRegisterPayCard').valid() || !validCardExpiryDate() || !validCardValidFrom())
                return false;
            if (typeof MMM != 'undefined') {
                $('#hdnMonitoringSessionId').val(MMM.getSession());
            }

            $btn.toggleLoadingSpin(true);

            if (!paymentForm.fields['card-number'].valid) {
                alert('Please input correct credit card number');
                $btn.toggleLoadingSpin(false);
                return false;
            }

            if (!paymentForm.fields['card-security-code'].valid) {
                alert('Please input correct security number');
                $btn.toggleLoadingSpin(false);
                return false;
            }

            $btn.prop('disabled', true);

            paymentForm.submit().then(
                function (data) {
                    if (data.Success == true) {
                        $('#identityNumber').val(data.Data.CardToken);
                        $('#displayNumber').val(data.Data.DisplayText);
                        $('#cardType').val(data.Data.CardType);
                        $('#hdnIssuerCompany').val(data.Data.IssuerCompany);
                        $('#hdnIssuerCountry').val(data.Data.IssuerCountry);
                        $('#hdnCardName').val(data.Data.CardName);
                        
                        $btn.prop('disabled', false);

                        var options = {
                            dataType: "json",
                            type: 'POST',
                            success: function (json) {
                                if (!json.success) {
                                    $btn.toggleLoadingSpin(false);
                                    showDepositError(json.error);
                                    return;
                                }

                                $('#fldCVC2 input[name="cardSecurityCode"]').val($('#fldCVC input[name="cardSecurityCode"]').val());
                                __loadRecentPayCards(json.payCardID);
                    
                                tryToSubmitDepositInputForm(json.payCardID, function () {
                                    $('#btnRegisterCardAndDeposit').toggleLoadingSpin(false);
                                });
                            },
                            error: function (xhr, textStatus, errorThrown) {
                                $btn.toggleLoadingSpin(false);
                                $btn.prop('disabled', false);
                            }
                        };
                        $(formSelector).ajaxForm(options);
                        $(formSelector).submit();

                        // $(formSelector).submit();
                    } else {
                        alert('Error');
                        $btn.toggleLoadingSpin(false);
                        $btn.prop('disabled', false);
                    }
                },
                function (data) {
                    alert(data.ResponseMessage);
                    $btn.toggleLoadingSpin(false);
                    $btn.prop('disabled', false);
                }
            );
        });
    }

    if (!window.CDE || !window.CDE.PaymentForm) {
        if(window.showSupportPop){
            window.showSupportPop();
        }else{
            alert('Secure fields cannot be loaded');
        }
    }

    initDepositForm('#formRegisterPayCard');
    initExistingCardForm();
</script>
<style type="text/css">
    #dvCardNumberWrapper{ position: relative;}
    #dvCardNumberWrapper .card-type{width:33px;height:19px;display:block;position:absolute;left:2px;top:2px;background:url(//cdn.everymatrix.com/images/icon/credit-cards.png) no-repeat -3px -35px;background-size: cover; }
    #dvCardNumberWrapper .card-type[data-cardtype='visa'] { background-position: -3px -63px; }
    #dvCardNumberWrapper .card-type[data-cardtype='visa_electron'] { background-position: -3px -91px; }
    #dvCardNumberWrapper .card-type[data-cardtype='mastercard'] { background-position: -3px -119px; }
    #dvCardNumberWrapper .card-type[data-cardtype='maestro'] { background-position: -3px -147px; }
    #dvCardNumberWrapper .card-type[data-cardtype='discover'] { background-position: -3px -175px; }
    #dvCardNumberWrapper .card-type[data-cardtype='amex'] { background-position: -3px -200px; }
    #dvCardNumberWrapper .card-type[data-cardtype='jcb'] { background-position: -3px -222px; }
    #dvCardNumberWrapper .card-type[data-cardtype='diners_club_carte_blanche'] { background-position: -3px -243px; }
    #dvCardNumberWrapper .card-type[data-cardtype='diners_club_international'] { background-position: -3px -243px; }
    #dvCardNumberWrapper .card-type[data-cardtype='laser'] { background-position: -3px -378px; }
    iframe#Pan, iframe#Cvv{height:29px;}

    #paycards-selector li label{padding-left:30px;background:url(//cdn.everymatrix.com/images/icon/credit-cards.png) no-repeat -3px -35px;background-size: 32px; }
    #paycards-selector li label[data-cardtype='visa'] { background-position: -3px -59px; }
    #paycards-selector li label[data-cardtype='visa_electron'] { background-position: -3px -87px; }
    #paycards-selector li label[data-cardtype='mastercard'] { background-position: -3px -115px; }
    #paycards-selector li label[data-cardtype='maestro'] { background-position: -3px -142px; }
    #paycards-selector li label[data-cardtype='discover'] { background-position: -3px -169px; }
    #paycards-selector li label[data-cardtype='amex'] { background-position: -3px -193px; }
    #paycards-selector li label[data-cardtype='jcb'] { background-position: -3px -214px; }
    #paycards-selector li label[data-cardtype='diners_club_carte_blanche'] { background-position: -3px -234px; }
    #paycards-selector li label[data-cardtype='diners_club_international'] { background-position: -3px -234px; }
    #paycards-selector li label[data-cardtype='laser'] { background-position: -3px -256px; }
</style>
