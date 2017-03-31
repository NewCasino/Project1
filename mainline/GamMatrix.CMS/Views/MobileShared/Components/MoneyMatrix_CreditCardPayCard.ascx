<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.Common.Components.MoneyMatrixCreditCardPrepareViewModel>" %>

<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="CM.Web.UI" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GamMatrix.CMS.Models.Common.Components" %>


<script runat="server">

    private string _sdkUrl;
    private string _monitoringUrl;

    private string GetSdkUrl()
    {
        return string.IsNullOrEmpty(_sdkUrl) ? _sdkUrl = GamMatrixClient.GetSdkUrl(Request.UserAgent, HttpContext.Current.Request.GetRealUserAddress()) : _sdkUrl;
    }

    private string GetMonitoringUrl()
    {
        return string.IsNullOrEmpty(_monitoringUrl) ? _monitoringUrl = GamMatrixClient.GetMonitoringUrl(Request.UserAgent, HttpContext.Current.Request.GetRealUserAddress()) : _monitoringUrl;
    }

    private List<SelectListItem> GetList(int minValue, int maxValue, string defaultText)
    {
        var list = new List<SelectListItem>();
        list.Add(new SelectListItem() { Text = defaultText, Value = "", Selected = true });

        for (int i = minValue; i <= maxValue; i++)
        {
            list.Add(new SelectListItem() { Text = string.Format("{0:00}", i), Value = string.Format("{0:00}", i) });
        }

        return list;
    }

    private List<PayCardInfoRec> GetPayCards()
    {
        List<PayCardInfoRec> payCards = GamMatrixClient.GetMoneyMatrixPayCards().Where(p => !p.IsDummy).ToList();

        var brandTypes = Model.BrandTypes;
        var acceptableCardBins = Model.AcceptableCardBins;

        if (brandTypes == null && acceptableCardBins == null)
        {
            return new List<PayCardInfoRec>();
        }

        if (brandTypes != null)
        {
            payCards = payCards.Where(p => brandTypes.Any(b => b.Equals(p.BrandType, StringComparison.InvariantCultureIgnoreCase))).ToList();
        }

        if (acceptableCardBins != null)
        {
            payCards = payCards.Where(p => acceptableCardBins.Any(b => p.DisplayName.StartsWith(b))).ToList();
        }

        return payCards;
    }

    private List<string> GetAcceptableCardTypes()
    {
        var brandTypes = Model.BrandTypes;

        var acceptableCardTypes = new List<string>();

        if (brandTypes != null && brandTypes.Count != 0)
        {
            var brandCradTypeMatching = Model.BrandCardTypeMatching;

            acceptableCardTypes = brandCradTypeMatching.Where(x => brandTypes.Contains(x.Key)).Select(x => x.Value).ToList();
        }

        return acceptableCardTypes;
    }

     private List<string> GetAcceptableCardSubtypes()
    {
       var acceptableCardSubtypes = new List<string>();  
        
       var cardBins = Model.AcceptableCardBins;

       if (cardBins != null)
       {
           var binCardSubtypeMatching = Model.BinCardSubtypeMatching;

           acceptableCardSubtypes = binCardSubtypeMatching.Where(x => cardBins.Contains(x.Key)).Select(x => x.Value).ToList();
       }

        return acceptableCardSubtypes;
    }

</script>

<script src="<%= GetSdkUrl() %>"></script>
<script src="<%= GetMonitoringUrl() %>"></script>
<script src="<%= Url.Content("/js/jquery/jquery.creditCardValidator.js") %>"></script>
<script src="<%= Url.Content("/js/jquery/jquery.form.js") %>"></script>
<script>
    var CdePaymentFormForRegisterCard;
    var CdePaymentFormForExistingPayCard;
    var IsRegisterCardTab;
</script>

<div id="paymentTypeForm">
<fieldset>
    <% Html.RenderPartial("/Components/GenericTabSelector", new GenericTabSelectorViewModel(
                                        new List<GenericTabData>
                                        {
               new GenericTabData
               {
                   Name = this.GetMetadata(".Tab_ExistingPayCards"),
                   Attributes = new Dictionary<string, string>()
                   {
                       {"id", "#tabRecentCards"}
                   }
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

    <%---------------------------------------------------------------
            Recent cards
         ----------------------------------------------------------------%>
    <div class="TabContent " id="tabRecentCards">
        <ul class="FormList">
            <li class="FormItem">
                <span hidden class="error" name="hdnSdkLoadError"><%= this.GetMetadata(".Sdk_Load_Error")%></span>
                <ul class="ExistingPayCards">
                    <% if (GetPayCards() != null && GetPayCards().Count > 0)
                        { %>
                    <% var checkedAttr = "checked";
                        foreach (PayCardInfoRec paycard in GetPayCards())
                        {
                            var cardType = string.Empty;
                            Model.BrandCardTypeMatching.TryGetValue(paycard.BrandType, out cardType); %>
                    <li>
                        <input type="radio" class="FormRadio" name="existingPayCard" <%= checkedAttr %> value="<%= paycard.ID.ToString() %>" id="payCard_<%= paycard.ID.ToString() %>" data-cardtoken="<%= paycard.DisplayNumber.HtmlEncodeSpecialCharactors() %>" />
                        <label for="payCard_<%= paycard.ID.ToString() %>" dir="ltr" data-cardtype="<%= cardType %>" data-pan="<%= paycard.DisplayName %>">
                            <%= paycard.DisplayName.SafeHtmlEncode() %> 
                        </label>
                    </li>
                    <% checkedAttr = "unchecked";
                        } %>
                    <% } %>
                </ul>
                <%: Html.Hidden("payCardID", "", new Dictionary<string, object>
                {
                    { "id", "hExistingPayCardID" },
                    { "data-validator", ClientValidators.Create().RequiredIf("PrepareTabs.IsRecentCardTab", this.GetMetadata(".ExistingCard_Empty")) }
                }) %>
                <span class="FormStatus">Status</span>
                <span class="FormHelp"></span>
            </li>
            <li class="FormItem">
                <label class="FormLabel" for="depositSecurityKey">
                    <%= this.GetMetadata(".CardSecurityCode_Label").SafeHtmlEncode()%>
                </label>
                <div id="dvCvv2Container"></div>
                <%: Html.Hidden("cardSecurityCodeExist", "", new Dictionary<string, object>
                {
                    { "id", "depositSecurityKey" },
                    { "dir", "ltr" },
                    { "class", "FormInput"},
                    { "data-validator", ClientValidators.Create().Custom("isValidCvvForExistingCard") }
                }) %>
                <span class="FormStatus">Status</span>
                <span class="FormHelp"></span>
            </li>
        </ul>
    </div>

    <%---------------------------------------------------------------
    Register a card
 ----------------------------------------------------------------%>
    <div class="TabContent Hidden" id="tabRegisterCard">
        <ul class="FormList">
            <span hidden class="error" name="hdnSdkLoadError"><%= this.GetMetadata(".Sdk_Load_Error")%></span>
            <%---------------------------------------------------------------
         Card number
        ----------------------------------------------------------------%>
            <li class="FormItem">
                <label class="FormLabel" for="depositCardNumber"><%= this.GetMetadata(".CardNumber_Label").SafeHtmlEncode() %></label>
                <div id="dvCardNumberWrapper">
                    <div class="card-type"></div>
                    <div id="dvCardNumberContainer"></div>
                </div>
                <input type="hidden" id="identityNumber" name="identityNumber" />
                <%: Html.Hidden("CardNumberValidator", null, new Dictionary<string, object>
               {
                 { "id", "hdnCardNumberValidator"},
                 { "dir", "ltr" },
                 {"class", "FormInput"},
                 {"autocomplete", "off"},
                 { "data-validator", ClientValidators.Create().Custom("isValidCardNumber")}
                }) %>
                <span class="FormStatus">Status</span>
                <span class="FormHelp"></span>
            </li>

            <li class="FormItem">
                <label class="FormLabel" for="hdnCardType"></label>
                <%: Html.Hidden("CardType", null, new Dictionary<string, object>
                {
                   { "id", "hdnCardType"},
                   { "dir", "ltr" },
                   { "class", "FormInput"},
                   {"autocomplete", "off"},
                   { "data-validator", ClientValidators.Create().Custom("isValidCardType")}
                }) %>
                <span class="FormStatus">Status</span>
                <span class="FormHelp"></span>
            </li>
                <%: Html.Hidden("CardSubType", null, new Dictionary<string, object>
                {
                   { "id", "hdnCardSubType"}
                }) %>

            <%---------------------------------------------------------------
         Card holder name
        ----------------------------------------------------------------%>
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
                { "placeholder", this.GetMetadata(".CardHolderName_Label") },
                { "data-validator", ClientValidators.Create().Custom("isValidCardHolderName") }
            }) %>
                <span class="FormStatus">Status</span>
                <span class="FormHelp"></span>
            </li>

            <%---------------------------------------------------------------
        Expiration date
        ----------------------------------------------------------------%>
            <li class="FormItem">
                <label class="FormLabel" for="ddlExpiryMonth">
                    <%= this.GetMetadata(".CardExpiryDate_Label").SafeHtmlEncode()%>
                </label>
                <ol class="CompositeInput DateInput Cols-2">
                    <li class="Col">
                        <%: Html.DropDownList("expiryMonth", GetList(1, 12, this.GetMetadata(".Month")), new
                              {
                                  @id = "ddlExpiryMonth",
                                  @class = "FormInput"
                              })%>
                    </li>
                    <li class="Col">
                        <%: Html.DropDownList("expiryYear", GetList(DateTime.Now.Year, DateTime.Now.Year + 20, this.GetMetadata(".Year")), new
                              {
                                  @id = "ddlExpiryYear",
                                  @class = "FormInput"
                              }) %>
                    </li>
                </ol>
                <%: Html.Hidden("expiryDate", "", new Dictionary<string, object>
                         {
                            { "id", "hdnExpiryDate" },
                            { "data-validator", ClientValidators.Create().Custom("isValidCardExpiryDate")   }
                         }) %>
                <span class="FormStatus">Status</span>
                <span class="FormHelp"></span>
            </li>

            <%---------------------------------------------------------------
       Card security code
        ----------------------------------------------------------------%>
            <li class="FormItem">
                <label class="FormLabel" for="hdnCardSecurityCode">
                    <%= this.GetMetadata(".CardSecurityCode_Label").SafeHtmlEncode()%>
                </label>
                <div id="dvCvvContainer"></div>
                <input hidden/>
                <%: Html.Hidden("cardSecurityCode", "", new Dictionary<string, object>
                    {
                      { "id", "hdnCardSecurityCode"},
                      { "dir", "ltr" },
                      { "class", "FormInput"},
                      {"autocomplete", "off"},
                      {"data-validator", ClientValidators.Create().Custom("isValidCardSecurityCode")}
                    }) %>
                <span class="FormStatus">Status</span>
                <span class="FormHelp"></span>
            </li>
        </ul>
    </div>
    <span hidden class="error" id="submitRegisterCardForm"></span>
</fieldset>
    </div>

<script language="javascript" type="text/javascript">
    $(document).ready(function () {
        new PrepareTabs();

        var depositForm = $("#formPrepareMoneyMatrix");
        var $btn = $("button[type='submit']");
        initExistingCardForm($btn, depositForm);
        initRegisterCardForm($btn, depositForm);
    });
</script>

<script language="javascript" type="text/javascript">
    
        function PrepareTabs() {
            //card actions
            var cardActionSelector = new GenericTabSelector('#cardActionSelector'),
                currentAction = $('#tabRecentCards');

            function selectAction(data) {
                if (currentAction) {
                    currentAction.addClass('Hidden');
                    $('input, select', currentAction).attr('disabled', true);
                }

                currentAction = $(data.id);

                currentAction.removeClass('Hidden');
                $('input, select', currentAction).attr('disabled', false);
            }

            function removeTab(id) {
                $('[data-id="' + id + '"]', '#cardActionSelector').hide();
                $('#cardActionSelector').removeClass('Cols-2').addClass('Cols-1');
                $(id).hide();
            }

            <% if (GetPayCards() != null && GetPayCards().Count >= Settings.Payments_Card_CountLimit)
            { %>
                removeTab('#tabRegisterCard');
            <% } else if (GetPayCards() == null || (GetPayCards() != null && GetPayCards().Count == 0))
             { %>
                removeTab('#tabRecentCards');
            <% } %>

            cardActionSelector.evt.bind('select', selectAction);

            var tabIndex = <%= (GetPayCards() != null && GetPayCards().Count != 0) ? 0 : 1%>
            selectAction(cardActionSelector.select(tabIndex));
        }

        PrepareTabs.IsRegisterCardTab = function() {
            return $('[data-id="#tabRegisterCard"]').hasClass('ActiveTab');
        }

        PrepareTabs.IsRecentCardTab = function () {
            return $('[data-id="#tabRecentCards"]').hasClass('ActiveTab');
        }

        var securityFieldCss = { 'font-size': '14px', 'height': '1.4em', 'line-height': '1.4em', 'font-family': 'Arial', 'color': '#666', 'background-color': '#dbe0e6', 'background-image': 'none', 'text-align': 'center', 'vertical-align': 'middle', 'direction': 'ltr', 'border': '1px solid #FFF', 'border-radius': '0', 'padding': '5px 7px 5px 35px', 'width': '91%' };

    function initCardForm(isRegisterCardTab) {
        if (hasSdkLoadError()) {
            $btn.prop('disabled', true);
            return;
        } else {

            if (isRegisterCardTab) {
                var securityCardNumberCss = securityFieldCss;
                securityCardNumberCss["text-align"] = "left";

                window.CdePaymentFormForRegisterCard = new CDE.PaymentForm({
                    'card-number': {
                        selector: '#dvCardNumberContainer',
                        css: securityCardNumberCss,
                        placeholder: '<%= this.GetMetadata(".CardNumber_Placeholder") %>',
                        format: true
                    },
                    'card-security-code': {
                        selector: '#dvCvvContainer',
                        css: securityFieldCss,
                        placeholder: '<%= this.GetMetadata(".CardSecurityCode_Placeholder") %>'
                    }
                });

                return window.CdePaymentFormForRegisterCard;
            } else {
                window.CdePaymentFormForExistingPayCard = new CDE.PaymentForm({
                    'card-security-code': {
                        selector: '#dvCvv2Container',
                        css: securityFieldCss,
                        placeholder: '<%= this.GetMetadata(".CardSecurityCode_Placeholder") %>'
                    }
                });

                return window.CdePaymentFormForExistingPayCard;
            }
        }
    }

    function initExistingCardForm($btn, depositForm) {
        var paymentForm = initCardForm(false);

        $btn.click(function (e) {
            e.preventDefault();

            if ($('#cardActionSelector li.ActiveTab').data('id') !== '#tabRecentCards')
                return;

            var payCard = $('.ExistingPayCards input[name="existingPayCard"]:checked')
            $('#hExistingPayCardID').val(payCard.val());

            if (!depositForm.valid()) {
                return;
            }

            var cardToken = payCard.attr('data-cardtoken');

            paymentForm.submitCvv({ CardToken: cardToken }).then(
                function (data) {
                    if (data.Success == true) {
                        $('#identityNumber').val(cardToken);

                        depositForm.submit();
                    } else {
                        showSubmitErrorMesage('Error', $('#submitRegisterCardForm'));
                        $btn.prop('disabled', false);
                    }
                },
                function (data) {
                    showSubmitErrorMesage(data.ResponseMessage, $('#submitRegisterCardForm'));
                    $btn.prop('disabled', false);
                }
            );
        });
    }

    function initRegisterCardForm($btn, depositForm) {
        // initialize the sensitive fields
        var paymentForm = initCardForm(true);

        if (paymentForm == undefined) {
            return;
        }

        var isLoading = true;
        paymentForm.fields['card-number'].on('status', function (evt, data) {

            if (!isLoading) {
                $('#hdnCardType').val(data.type);
                $('#hdnCardSubType').val(data.subtype);
            }

            isLoading = false;
            $('#dvCardNumberWrapper .card-type').attr('data-cardtype', data.type);
        });

        $btn.on('click', function (e) {
            e.preventDefault();

            if ($('#cardActionSelector li.ActiveTab').data('id') === '#tabRecentCards')
                return;

            if (!depositForm.valid()) {
                return;
            }

            $btn.prop('disabled', true);

            paymentForm.submit().then(
                function (data) {
                    if (data.Success == true) {
                        $('#identityNumber').val(data.Data.CardToken);

                        $btn.prop('disabled', false);

                        depositForm.submit();
                    } else {
                        showSubmitErrorMesage("Error", $('#submitRegisterCardForm'));
                        $btn.prop('disabled', false);
                    }
                },
                function (data) {
                    showSubmitErrorMesage(data.ResponseMessage, $('#submitRegisterCardForm'));
                    $btn.prop('disabled', false);
                }
            );
        });
    }
</script>

<ui:MinifiedJavascriptControl runat="server" ID="script" AppendToPageEnd="true" Enabled="true">
    <script type="text/javascript">

        function isValidCardNumber() {
            if (PrepareTabs.IsRecentCardTab()) {
                return true;
            }

                if (!window.CdePaymentFormForRegisterCard.fields['card-number'].valid) {
                return '<%= this.GetMetadata(".CardNumber_Invalid")%>';
            }

            return true;
        }

        function hasSdkLoadError() {
            if (!window.CDE || !window.CDE.PaymentForm) {
                var hdnSdkLoadError = $('span[name="hdnSdkLoadError"]');
                hdnSdkLoadError.removeAttr("hidden");
                return true;
            }

            return false;
        }

        function isValidCardSecurityCode() {
            if (PrepareTabs.IsRecentCardTab()) {
                return true;
            }

            if (!window.CdePaymentFormForRegisterCard.fields['card-security-code'].valid) {
                return '<%= this.GetMetadata(".CardSecurityCode_Invalid")%>';
            }

            return true;
        }

        function isValidCvvForExistingCard() {
            if (PrepareTabs.IsRegisterCardTab()) {
                return true;
            }

            if (!window.CdePaymentFormForExistingPayCard.fields['card-security-code'].valid) {
                return '<%= this.GetMetadata(".CardSecurityCode_Invalid")%>';
            }

            return true;
        }

        function showSubmitErrorMesage(responseMsg, errorSpan) {
            errorSpan.text(responseMsg);
            errorSpan.removeAttr("hidden");
        }

        function isValidCardType() {
            var validCardType = false;
            var creditCardType = this.valueOf();
            var creditCardSubtype = $('#hdnCardSubType').val();

            var cardTypes = new Array();

            <% if (GetAcceptableCardTypes().Count != 0)
             {
               foreach (var cardType in GetAcceptableCardTypes())
               { %>
                 cardTypes.push('<%= cardType %>');

                 validCardType = $.inArray(creditCardType, cardTypes) >= 0 || creditCardType.length == 0 || creditCardType == "unknown";
            <% } } %>

            <% if (GetAcceptableCardSubtypes().Count != 0)
             {
               foreach (var cardType in GetAcceptableCardSubtypes())
               { %>
                    cardTypes.push('<%= cardType %>');

                    validCardType = $.inArray(creditCardSubtype, cardTypes) >= 0 || creditCardSubtype.length == 0;
            <% }}%>

            return validCardType || '<%= this.GetMetadata(".CardSchema_NotSupported") %>';
        }

        function isValidCardExpiryDate() {
            if (PrepareTabs.IsRecentCardTab()) {
                return true;
            }
            var expiryDate = $('input[name="expiryDate"]');

            var date = new Date();
            var currentYear = date.getFullYear();
            var currentMonth = date.getMonth() + 1;

            var expiryMonth = $('#ddlExpiryMonth').val();
            var expiryYear = $('#ddlExpiryYear').val();
            var value = '';
            if (expiryMonth.length > 0 && expiryYear.length > 0)
                value = expiryYear + '-' + expiryMonth + '-01';
            expiryDate.val(value);

            if (value.length == 0 || (expiryMonth < currentMonth && expiryYear == currentYear)) {
                return '<%= this.GetMetadata(".CardExpiryDate_Invalid") %>';
            }

            return true;
        }

        function isValidCardHolderName() {
            if (PrepareTabs.IsRecentCardTab()) {
                return true;
            }

             var fullName = this;
             if (fullName.length == 0) {
                 return '<%= this.GetMetadata(".CardHolderName_Empty") %>';
             }

            var names = fullName.match(/\S+/g);

            if (names.length < 2 || !/^[A-Za-z '.-]+$/.test(fullName)) {
                return '<%= this.GetMetadata(".CardHolderName_Empty") %>';
            }

            return true;
        }

    </script>
</ui:MinifiedJavascriptControl>

<style type="text/css">
    #dvCardNumberWrapper {
        position: relative;
    }

    span[name='hdnSdkLoadError'] {
        color: red;
    }

    .error {
         color: red;
    }
    
    #dvCardNumberWrapper .card-type {
        width: 33px;
        height: 19px;
        display: block;
        position: absolute;
        left: 2px;
        top: 5px;
        background: url(//cdn.everymatrix.com/images/icon/credit-cards.png) no-repeat -3px -35px;
        background-size: cover;
    }

    #cardActionSelector + .TabContent .FormItem ul > li input[type=radio]+label:after {
           left: -28px;
           top: -1px;
        }

    #cardActionSelector + .TabContent .FormItem ul > li label {
         margin-left: 30px;
         position: relative;
    }

    .FormCheckLabel, .SquareForm .FormRadio + label, input.FormCheck ~ .FormLabel, input[type=radio] + label {
      padding: 0.3em
    }

    #tabExistingCard .ExistingPayCards li label {
         line-height: 13px;
         background-color: transparent;
       
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
