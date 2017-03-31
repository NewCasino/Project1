<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrix.CMS.Models.MobileShared.Deposit.Prepare.PrepareMoneyMatrixViewModel>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>

<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="CM.Web.UI" %>
<%@ Import Namespace="Finance" %>


<script runat="Server">
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
            if (string.Equals(this.Model.PaymentMethod.UniqueName, "PT_Maestro", StringComparison.InvariantCultureIgnoreCase)
                && (
                    !string.IsNullOrEmpty(this.GetMetadata(".IsHiddenIssueNumber")) && !string.Equals("No", this.GetMetadata(".IsHiddenIssueNumber"), StringComparison.InvariantCultureIgnoreCase))
                )
            {
                return true;
            }
            else
            {
                bool bolRlt = string.Equals(this.Model.PaymentMethod.UniqueName, "PT_MasterCard", StringComparison.InvariantCultureIgnoreCase) ||
                              string.Equals(this.Model.PaymentMethod.UniqueName, "PT_Switch", StringComparison.InvariantCultureIgnoreCase) ||
                              string.Equals(this.Model.PaymentMethod.UniqueName, "PT_Maestro", StringComparison.InvariantCultureIgnoreCase);
                if (bolRlt)
                {
                    string[] arrCartPT = this.GetMetadata(".HideIssueNumber").Split(new string[] { "," }, StringSplitOptions.RemoveEmptyEntries);
                    foreach (string pt in arrCartPT)
                    {
                        if (string.Compare(pt, this.Model.PaymentMethod.UniqueName, true) == 0)
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


<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>


<asp:content contentplaceholderid="cphMain" runat="Server">

<div id="DepositPrepareBox" class="UserBox CenterBox DepositBox DepositOptionsList DepositStep3 DepositPrepareBox StyleV2" data-step="3">
        <div class="BoxContent DepositContent" id="DepositContent">
        <% if (!Settings.MobileV2.IsV2DepositProcessEnabled)
            { %>
    <% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 4, CurrentStep = 1 }); %>
        <% } %>
<form action="<%= this.Url.RouteUrl("Deposit", new { @action = "PrepareTransaction", @paymentMethodName = Model.PaymentMethod.UniqueName }).SafeHtmlEncode() %>" method="post" id="formPrepareMoneyMatrix" class="GeneralForm DepositForm DepositPrepare">
    
<% Html.RenderPartial("/Components/MultiFormState", Model.StateVars); %>

            <fieldset>
            <legend class="Hidden">
            <%= this.GetMetadata(".CreditCard").SafeHtmlEncode() %>
            </legend>
                <%: Html.Hidden( "payCardID", string.Empty, new { @id = "hCreditCardPayCardID" }) %>

<% Html.RenderPartial("/Components/GenericTabSelector", new GenericTabSelectorViewModel(new List<GenericTabData>
{
new GenericTabData
{
Name = this.GetMetadata(".Tab_RecentPayCards"),
Attributes = new Dictionary<string, string>() { {"id", "#tabExistingCard"} }
},
new GenericTabData
{
Name = this.GetMetadata(".Tab_RegisterPayCard"),
Attributes = new Dictionary<string, string>() { {"id", "#tabRegisterCard"} }
}
})
    {
        ComponentId = "cardActionSelector"
    }); %>

                <%-- Existing Card --%>
            <div class="TabContent" id="tabExistingCard">

<ul class="FormList">

    <%--------------------------
        Existing Card List
      --------------------------%>
    <li class="FormItem">
        <ul class="ExistingPayCards">
            <% foreach (PayCardInfoRec card in Model.PayCards)
                { %>
            <li>
                <input name="PaymentTrustPayCardID" class="FormRadio" type="radio" id="btnPayCard_<%: card.ID %>" value="<%: card.ID %>" data-name="<%= card.DisplayName.SafeHtmlEncode() %>" data-cardtoken="<%=card.DisplayNumber.SafeHtmlEncode() %>" />
                <label for="btnPayCard_<%: card.ID %>"><%= card.DisplayName.SafeHtmlEncode() %></label>
            </li>
            <% } %>
        </ul>
    </li>


    <%--------------------------
        Security Key for existing card
      --------------------------%>
    <li class="FormItem">
    <label class="FormLabel" for="depositSecurityKey">
        <%= this.GetMetadata(".CardSecurityCode_Label").SafeHtmlEncode()%>
        </label>
       <div id="dvCvv2Container"></div>
<script>
    $(function () {
        new CMS.views.RestrictedInput('#fldCVC2 input[id="cardSecurityCode"]', CMS.views.RestrictedInput.digits);
    });
</script>
    </li>

    <li id="maxRegisteredCardsMsg" class="FormItem Hidden">
        <label class=""><%= this.GetMetadata(".MaxRegisteredCardsExceeded_Text") %></label>
    </li>
</ul>


                </div>

                <%-- Register Card --%>
                <div class="TabContent Hidden" id="tabRegisterCard">

<ul class="FormList">

    <%------------------------
        Card Number
    -------------------------%>    
    <li class="FormItem">
    <label class="FormLabel" for="depositCardNumber">
        <%= this.GetMetadata(".CardNumber_Label").SafeHtmlEncode()%>
        </label>
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
                <input type="hidden" name="MonitoringSessionId" id="hdnMonitoringSessionId" />
        <span class="FormStatus">Status</span>
    <span class="FormHelp"></span>

      
    </li>
    
    
    <%------------------------
        Card Holder Name
    -------------------------%>   
    <li class="FormItem">
    <label class="FormLabel" for="depositHolderName">
        <%= this.GetMetadata(".CardHolderName_Label").SafeHtmlEncode()%>
        </label>
        <%: Html.TextBox("ownerName", string.Empty, new Dictionary<string, object>()  
            { 
                { "class", "FormInput" },
                { "id", "depositHolderName" },
                { "maxlength", "30" },
                { "autocomplete", "off" },
                { "dir", "ltr" },
                { "required", "required" },
{ "disabled", "disabled" },
{ "placeholder", this.GetMetadata(".CardHolderName_Label") },
                { "data-validator", ClientValidators.Create().RequiredIf( "PreparePT.isRegisteringNewCard", this.GetMetadata(".CardHolderName_Empty")) }
            }) %>
        <span class="FormStatus">Status</span>
    <span class="FormHelp"></span>
    </li>

    <%------------------------
        Valid From
    -------------------------%> 
    <% if (ShowExtraFields)
        {  %> 
    <li class="FormItem">
    <label class="FormLabel" for="ddlValidFromMonth">
        <%= this.GetMetadata(".ValidFrom_Label").SafeHtmlEncode()%>
        </label>
        <ol class="CompositeInput DateInput Cols-2">
    <li class="Col">
                <%: Html.DropDownList("validFromMonth", GetMonthList(), new
                {
                    @id = "ddlValidFromMonth",
                    @class = "FormInput"
                } 
                )%>
            </li>
            <li class="Col">
                <%: Html.DropDownList("validFromYear", GetValidFromYears(), new
                {
                    @id = "ddlValidFromYear",
                    @class = "FormInput"
                } 
                )%>
            </li>
    </ol>
        <%: Html.Hidden("validFrom","", new Dictionary<string, object>() 
            {
{ "class", "FormInput" },
                { "id", "hCardValidFrom" },
{ "disabled", "disabled" },
{ "autocomplete", "off" },
            } ) %>
        <span class="FormStatus">Status</span>
    <span class="FormHelp"></span>
        <script>
            //<![CDATA[
            $(function () {
                var fun = function () {
                    var month = $('#ddlValidFromMonth').val();
                    var year = $('#ddlValidFromYear').val();
                    var value = '';
                    if (month.length > 0 && year.length > 0)
                        value = year + '-' + month + '-01';
                    $('#hCardValidFrom').val(value);
                };
                $('#ddlValidFromMonth').change(fun);
                $('#ddlValidFromYear').change(fun);
            });
            //]]>
        </script>
    </li>
    <% } // ShowExtraFields %>


    <%------------------------
        Expiry Date
    -------------------------%>   
    <li class="FormItem">
    <label class="FormLabel" for="ddlExpiryMonth">
        <%= this.GetMetadata(".CardExpiryDate_Label").SafeHtmlEncode()%>
        </label>
        <ol class="CompositeInput DateInput Cols-2">
    <li class="Col">
                <%: Html.DropDownList("expiryMonth", GetMonthList(), new
                {
                    @id="ddlExpiryMonth",
                    @class = "FormInput"
                } 
                )%>
            </li>
            <li class="Col">
                <%: Html.DropDownList("expiryYear", GetExpiryYears(), new
                {
                    @id = "ddlExpiryYear",
                    @class = "FormInput"
                } 
                )%>
            </li>
    </ol>
        <%: Html.Hidden("expiryDate","", new Dictionary<string, object>() 
            {
{ "class", "FormInput" },
                { "id", "hCardExpiryDate" },
{ "disabled", "disabled" },
{ "autocomplete", "off" },
{ "data-validator", ClientValidators.Create().RequiredIf("PreparePT.isRegisteringNewCard", this.GetMetadata(".CardExpiryDate_Empty")) } 
            } ) %>
        <span class="FormStatus">Status</span>
    <span class="FormHelp"></span>
        <script>
            $(function () {
                var fun = function () {
                    var month = $('#ddlExpiryMonth').val();
                    var year = $('#ddlExpiryYear').val();
                    var value = '';
                    if (month.length > 0 && year.length > 0)
                        value = year + '-' + month + '-01';
                    $('#hCardExpiryDate').val(value);
                };
                $('#ddlExpiryMonth').change(fun);
                $('#ddlExpiryYear').change(fun);
            });
        </script>
    </li>


    <%------------------------
        Card Issue Number
    -------------------------%>   
    <% if (ShowExtraFields)
        {  %>
    <li class="FormItem">
    <label class="FormLabel" for="depositIssueNumber">
        <%= this.GetMetadata(".CardIssueNumber_Label").SafeHtmlEncode()%>
        </label>
        <%: Html.TextBox("issueNumber", string.Empty, new Dictionary<string, object>()  
            { 
                { "class", "FormInput" },
                { "id", "depositIssueNumber" },
                { "maxlength", "16" },
                { "autocomplete", "off" },
                { "dir", "ltr" },
{ "disabled", "disabled" },
{ "placeholder", this.GetMetadata(".CardIssueNumber_Label") },
            }) %>
        <span class="FormStatus">Status</span>
    <span class="FormHelp"></span>
    </li>
    <% } %>

    <%--------------------------
        Security Key for new card
      --------------------------%>
    <li class="FormItem">
    <label class="FormLabel" for="depositNewSecurityKey">
        <%= this.GetMetadata(".CardSecurityCode_Label").SafeHtmlEncode()%>
        </label>
       <div id="dvCvvContainer"></div>
                    <input type="hidden" id="cardSecurityCode" name="cardSecurityCode" />
        <span class="FormStatus">Status</span>
<span class="FormHelp"></span>

    </li>

</ul>

                </div>
            </fieldset>

            <% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel()); %>

</form>
    </div>
</div>

    <script src="<%= GetMonitoringUrl() %>"></script>
    <script src="<%= GetSdkUrl() %>"></script>
<script src="<%= Url.Content("/js/jquery/jquery.creditCardValidator.js") %>"></script>
    <script src="<%= Url.Content("/js/jquery/jquery.form.js") %>"></script>


<script>
    //<![CDATA[
    function PreparePT() {
        //card actions
        var cardActionSelector = new GenericTabSelector('#cardActionSelector'),
    currentAction = $('#tabExistingCard');

        function selectAction(data) {
            if (currentAction) {
                currentAction.addClass('Hidden');
                $('input, select', currentAction).attr('disabled', true);
            }

            currentAction = $(data.id);

            currentAction.removeClass('Hidden');
            $('input, select', currentAction).attr('disabled', false);

            if (data.id == '#tabExistingCard') {
                $(':radio:first', '#tabExistingCard').click();
            }
            else {
                $('#hCreditCardPayCardID').val('');
            }
        }

        function removeItem(id) {
            $('[data-id="' + id + '"]', '#cardActionSelector').hide();
            $('#cardActionSelector').removeClass('Cols-2').addClass('Cols-1');
            $(id).hide();
        }

        $(':radio', '#tabExistingCard').click(function (e) {
            $('#hCreditCardPayCardID').val($(this).val());
        });

        var count = $(':radio', '#tabExistingCard').length;
        if (count >= <%= Settings.Payments_Card_CountLimit %>) {
            removeItem('#tabRegisterCard');
        $('#maxRegisteredCardsMsg').removeClass('Hidden');
    }
    else if (count == 0) {
        removeItem('#tabExistingCard');
/*setTimeout(function(){
$('[data-id="#tabRegisterCard"]', '#cardActionSelector').find('a').click();
},1000);*/
        $('#maxRegisteredCardsMsg').addClass('Hidden');
    }
        
    function markOptional(inputSelector, state) {
        $.each(inputSelector.closest('.FormItem').find('.FormLabel'), function (i, label) {
            label = $(label);
            if (state) {
                if (!label.find('.FormLabelOptional').length)
                    label.append('<span class="FormLabelOptional"> <%= this.GetMetadata(".FieldOptional").SafeJavascriptStringEncode() %></span>');
            } else 
                $('.FormLabelOptional', label).remove();
        });
    }

    cardActionSelector.evt.bind('select', selectAction);
var count = $(':radio', '#tabExistingCard').length,
    tabIndex = count != 0 ? 0: 1;

    selectAction(cardActionSelector.select(tabIndex));
    markOptional($('#depositIssueNumber, #ddlValidFromMonth'), true);
    };

    PreparePT.validateCardSecurityCode = function () {
        var value = this;
        if (value.length > 0) {
            var ret = /^(\d{3,3})$/.exec(value);
            if (ret == null || ret.length == 0)
                return '<%= this.GetMetadata(".CardSecurityCode_Invalid").SafeJavascriptStringEncode() %>';
        }
        return true;
    }

    PreparePT.isRegisteringNewCard = function () {
        return $('#hCreditCardPayCardID').val() == '';
    }
    PreparePT.isExistingCard = function () {
        return !PreparePT.isRegisteringNewCard();
    }

    var btnSubmit,
        depositForm,
        inited = false;
    $(function () {

        btnSubmit = $("button[type='submit']");
        depositForm = $("#formPrepareMoneyMatrix");
        CMS.mobile360.Generic.input();
        new PreparePT();

        var allCards = $("input[name='PaymentTrustPayCardID']");
        $.each(allCards,function(){
            var $this = $(this);
            var label = $this.next();
            var cardTypeValidateResult = $('<input value="'+ $this.data("name") +'"/>').validateCreditCard();
            var cardType = cardTypeValidateResult.card_type ? cardTypeValidateResult.card_type.name : '';
            label.attr("data-cardtype",cardType);
        });

        //$("#selectAccount").change(function(){
        //    $("#creditAccountID").val($(this).val());
        //});
        if (!window.CDE || !window.CDE.PaymentForm) {
            btnSubmit.click(function(e) {
                e.preventDefault();
            });
            alert('Secure fields cannot be loaded');
        }

        try
        {
            initDepositForm();
            initExistingCardForm();
        }
        catch(ex){

            if(console.log)
                console.log(ex);
        }
    });
    //]]>
</script>

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

            //var $btn = $('#btnDepositWithExistingCard');

            btnSubmit.click(function (e) {
                e.preventDefault();
                if( !depositForm.valid()  )
                    return;

                if($('#cardActionSelector li.ActiveTab').data('id') !== '#tabExistingCard')
                    return;

                var regCardLi = $("input[name='PaymentTrustPayCardID']:checked");
                var cardToken = regCardLi.data("cardtoken"); //$('#hdnCardToken').val();

                paymentForm.submitCvv({ CardToken: cardToken }).then(
                    function (data) {
                        if (data.Success == true) {
                            $('#identityNumber').val(cardToken);
                            if (typeof MMM != 'undefined') {
                                $('#hdnMonitoringSessionId').val(MMM.getSession());
                            }

                            //tryToSubmitDepositInputForm($('#hExistingPayCardID').val()
                            //    , function() {
                            //        $btn.toggleLoadingSpin(false);
                            //    }
                            //);

                            depositForm.submit();
                        } else {
                            alert('Error');
                        }
                    },
                    function (data) {
                        var message = data.detail ? data.detail : data.ResponseMessage;

                        alert(message);
                        //$btn.toggleLoadingSpin(false);
                        //$btn.prop('disabled', false);
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
                    placeholder: '<%= this.GetMetadata(".CardSecurityCode_Placeholder") %>',
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
                btnSubmit.prop('disabled', false);
            });

            paymentForm.on('error', function (e, data) {
              $btn.prop('disabled', true);
              alert(data.ResponseMessage);
            });

            // submit
            btnSubmit.on('click', function (e) {
                e.preventDefault();
        
                if( !depositForm.valid()  )
                    return;

                if($('#cardActionSelector li.ActiveTab').data('id') === '#tabExistingCard')
                    return;


                if (!paymentForm.fields['card-number'].valid) {
                    alert('Please input correct credit card number');
                    return false;
                }

                if (!paymentForm.fields['card-security-code'].valid) {
                    alert('Please input correct security number');
                    return false;
                }

                btnSubmit.prop('disabled', true);

                paymentForm.submit().then(
                    function (data) {
                        if (data.Success == true) {
                            $('#identityNumber').val(data.Data.CardToken);
                            $('#displayNumber').val(data.Data.DisplayText);
                            $('#cardType').val(data.Data.CardType);
                            $('#hdnIssuerCompany').val(data.Data.IssuerCompany);
                            $('#hdnIssuerCountry').val(data.Data.IssuerCountry);
                            $('#hdnCardName').val(data.Data.CardName);
                            if (typeof MMM != 'undefined') {
                                $('#hdnMonitoringSessionId').val(MMM.getSession());
                            }

                            btnSubmit.prop('disabled', false);

                            //$("#formPrepareMoneyMatrix").ajaxSubmit({
                            //    dataType: "json",
                            //    type: 'POST',
                            //    url:'/Deposit/RegisterMoneyMatrixPayCard',
                            //    success: function (json) {
                            //        if (!json.success) {
                            //            alert(json.error);
                            //            return;
                            //        }

                            //        //$('#fldCVC2 input[name="cardSecurityCode"]').val($('#fldCVC input[name="cardSecurityCode"]').val());
                    
                            //        $("#hCreditCardPayCardID").val(json.payCardID);
                            //        depositForm.submit();
                            //    },
                            //    error: function (xhr, textStatus, errorThrown) {
                            //        alert(errorThrown + "error");
                            //        btnSubmit.prop('disabled', false);
                            //    }
                            //});

                            depositForm.submit();
                            

                            // $(formSelector).submit();
                        } else {
                            alert('Error');
                            btnSubmit.prop('disabled', false);
                        }
                    },
                    function (data) {
                        alert(data.ResponseMessage);
                        btnSubmit.prop('disabled', false);
                    }
                );
            });
        }

      
</script>
<style type="text/css">
    #dvCardNumberWrapper {
        position: relative;
    }

        #dvCardNumberWrapper .card-type {
            width: 33px;
            height: 19px;
            display: block;
            position: absolute;
            left: 2px;
            top: 2px;
            background: url(//cdn.everymatrix.com/images/icon/credit-cards.png) no-repeat -3px -35px;
            background-size: cover;
        }

            #dvCardNumberWrapper .card-type[data-cardtype='visa'] {
                background-position: -3px -63px;
            }

            #dvCardNumberWrapper .card-type[data-cardtype='visa_electron'] {
                background-position: -3px -91px;
            }

            #dvCardNumberWrapper .card-type[data-cardtype='mastercard'] {
                background-position: -3px -119px;
            }

            #dvCardNumberWrapper .card-type[data-cardtype='maestro'] {
                background-position: -3px -147px;
            }

            #dvCardNumberWrapper .card-type[data-cardtype='discover'] {
                background-position: -3px -175px;
            }

            #dvCardNumberWrapper .card-type[data-cardtype='amex'] {
                background-position: -3px -200px;
            }

            #dvCardNumberWrapper .card-type[data-cardtype='jcb'] {
                background-position: -3px -222px;
            }

            #dvCardNumberWrapper .card-type[data-cardtype='diners_club_carte_blanche'] {
                background-position: -3px -243px;
            }

            #dvCardNumberWrapper .card-type[data-cardtype='diners_club_international'] {
                background-position: -3px -243px;
            }

            #dvCardNumberWrapper .card-type[data-cardtype='laser'] {
                background-position: -3px -378px;
            }

    iframe#Pan, iframe#Cvv {
        height: 29px;
    }

    .ExistingPayCards li label {
        padding-left: 30px;
        background: url(//cdn.everymatrix.com/images/icon/credit-cards.png) no-repeat -3px -35px;
        background-size: 32px;
    }

        .ExistingPayCards li label[data-cardtype='visa'] {
            background-position: -3px -59px;
        }

        .ExistingPayCards li label[data-cardtype='visa_electron'] {
            background-position: -3px -87px;
        }

        .ExistingPayCards li label[data-cardtype='mastercard'] {
            background-position: -3px -115px;
        }

        .ExistingPayCards li label[data-cardtype='maestro'] {
            background-position: -3px -142px;
        }

        .ExistingPayCards li label[data-cardtype='discover'] {
            background-position: -3px -169px;
        }

        .ExistingPayCards li label[data-cardtype='amex'] {
            background-position: -3px -193px;
        }

        .ExistingPayCards li label[data-cardtype='jcb'] {
            background-position: -3px -214px;
        }

        .ExistingPayCards li label[data-cardtype='diners_club_carte_blanche'] {
            background-position: -3px -234px;
        }

        .ExistingPayCards li label[data-cardtype='diners_club_international'] {
            background-position: -3px -234px;
        }

        .ExistingPayCards li label[data-cardtype='laser'] {
            background-position: -3px -256px;
        }
</style>
</asp:content>

