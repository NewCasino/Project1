<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.Common.Components.MoneyMatrixCreditCardPrepareViewModel>" %>

<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
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

    protected override void OnPreRender(EventArgs e)
    {
        List<PayCardInfoRec> payCards = GetPayCards();

        var registerCardTab = tabbedPayCards.Tabs[1];
        var existingCardTab = tabbedPayCards.Tabs[0];
        registerCardTab.Attributes["Selected"] = bool.TrueString;

        if (payCards != null && payCards.Count > 0)
        {
            existingCardTab.Visible = true;
            existingCardTab.Attributes["Selected"] = bool.TrueString;
            registerCardTab.Attributes["Selected"] = bool.FalseString;

            if ((payCards != null && payCards.Count >= Settings.Payments_Card_CountLimit) || Model.Type == TransactionType.Withdraw)
            {
                registerCardTab.Visible = false;
            }
        }
    }
</script>

<script src="<%= GetSdkUrl() %>"></script>
<script src="<%= GetMonitoringUrl() %>"></script>
<script src="<%= Url.Content("/js/jquery/jquery.creditCardValidator.js") %>"></script>

<script>
    var CdePaymentFormForRegisterCard;
    var CdePaymentFormForExistingPayCard;
</script>
<ui:TabbedContent ID="tabbedPayCards" runat="server">
    <tabs>      
         <%---------------------------------------------------------------
            Recent cards
         ----------------------------------------------------------------%>
        <ui:Panel runat="server" ID="tabRecentCards" Visible="False" Caption="<%$ Metadata:value(.Tab_ExistingPayCards) %>">
            <form id="formRecentCards" onsubmit="return false">       
                <% if (GetPayCards() != null && GetPayCards().Count > 0)
                { %>
                 <ui:InputField ID="fldExistingPayCard" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
                     <LabelPart>
                          <%= this.GetMetadata(".Select").SafeHtmlEncode() %>
                     </LabelPart>
	                <ControlPart>
	                   <span hidden class="error" name="hdnSdkLoadError"><%= this.GetMetadata(".Sdk_Load_Error")%></span>
        <ul id="paycards-selector">
          <% var checkedAttr = "checked";
              foreach (PayCardInfoRec paycard in GetPayCards())
              {
                  var cardType = string.Empty;
                  Model.BrandCardTypeMatching.TryGetValue(paycard.BrandType, out cardType); %>
            <li>
                <input type="radio" name="existingPayCard" <%= checkedAttr %> value="<%= paycard.ID.ToString() %>" id="payCard_<%= paycard.ID.ToString() %>" data-cardtoken="<%= paycard.DisplayNumber.HtmlEncodeSpecialCharactors() %>"/>
                <label for="payCard_<%= paycard.ID.ToString() %>" dir="ltr" data-cardtype="<%= cardType %>" data-pan="<%= paycard.DisplayName %>" >
                    <%= paycard.DisplayName.SafeHtmlEncode() %> (<%= paycard.ExpiryDate.ToString("MM/yyyy") %> <%= paycard.OwnerName %>)
                </label>
            </li>
        <% checkedAttr = "unchecked";
            } %>
        </ul>
        <%: Html.Hidden("existingPayCardID", "", new
            {
                @id = "hExistingPayCardID",
                @validator = ClientValidators.Create().Required(this.GetMetadata(".ExistingCard_Empty"))
            }) %>
        </ControlPart>
    </ui:InputField>
                <br />
                  <% if (Model.Type == TransactionType.Deposit)
           { %>
                <ui:InputField ID="fldCVC2" runat="server">
                <LabelPart><%= this.GetMetadata(".CardSecurityCode_Label").SafeHtmlEncode() %></LabelPart>
                <ControlPart>
                <div id="dvCvv2Container"></div>
                  <%: Html.Hidden("cardSecurityCode", "", new
                    {
                        @id = "hdnCardSecurityCode2", 
                        @validator = ClientValidators.Create().Custom("isValidCvvForExistingCard")
                    }) %>
                </ControlPart>
                </ui:InputField>
                   <% } %> 
                <center>
                    <%: Html.Button(this.GetMetadata(".Button_Continue"), new {@id = "btnDepositWithExistingCard", @class = "ContinueButton button"}) %>
                    <span hidden class ="error" id="submitExistingCardFormError"></span>
                </center>
          <% } %> 
            </form>
           
             <script language="javascript" type="text/javascript">
                 $(document).ready(function() {
                     $('#formRecentCards').initializeForm();
                     <% if (Model.Type == TransactionType.Deposit)
                        { %>
                            initExistingCardForm();
                     <% } else {%> 
                     initWithdrawCardForm();
                     <% } %> 
            });
    </script>
        </ui:Panel>
<%---------------------------------------------------------------
    Register a card
 ----------------------------------------------------------------%>
<ui:Panel runat="server" ID="tabRegister" Visible="True" Caption="<%$ Metadata:value(.Tab_RegisterPayCard) %>">
  <form id="formRegisterPayCard" onsubmit="return false" method="post" action="<%= this.Url.RouteUrl("Deposit", new {@action = "RegisterPayCard", @vendorID = VendorID.MoneyMatrix}).SafeHtmlEncode() %>" enctype="application/x-www-form-urlencoded">
       <% if (Model.Type == TransactionType.Deposit || (GetPayCards() != null && GetPayCards().Count < Settings.Payments_Card_CountLimit))
      { %>
     <%------------------------
        Card Number
      -------------------------%>    
    <ui:InputField ID="fldCardNumber" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
        <LabelPart>
           <%= this.GetMetadata(".CardNumber_Label").SafeHtmlEncode() %>
        </LabelPart>
        <ControlPart>  
         <span hidden class="error" name="hdnSdkLoadError"><%= this.GetMetadata(".Sdk_Load_Error")%></span> 
        <div id="dvCardNumberWrapper">
            <div class="card-type"></div>
            <div id="dvCardNumberContainer"></div>
        </div>
        <input type="hidden" id="identityNumber" name="identityNumber" />
        <%: Html.Hidden("CardType", null,
                new
                {
                    @id = "hdnCardType",
                    @validator = ClientValidators.Create().Custom("isValidCardType")
                }) %>
            <%: Html.Hidden("CardSubType", null,
                new
                {
                    @id = "hdnCardSubType"
                }) %>
        <%: Html.Hidden("CardNumberValidator", null,
         new
         {
             @id = "hdnCardNumberValidator",
             @validator = ClientValidators.Create().Custom("isValidCardNumber")
         }) %>
      </ControlPart>
    </ui:InputField>

    <%------------------------
        Card Holder Name
      -------------------------%>    
    <ui:InputField ID="fldCardHolderName" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
    <LabelPart><%= this.GetMetadata(".CardHolderName_Label").SafeHtmlEncode() %></LabelPart>
    <ControlPart>
            <%: Html.TextBox("ownerName", "", new
                {
                    @id = "hdnCardHolderName",
                    @maxlength = 30,
                    @validator = ClientValidators.Create().Custom("isValidCardHolderName")
                }) %>
    </ControlPart>
    </ui:InputField>
    
    <%------------------------
      Expiry Date
    -------------------------%>    
          <ui:InputField ID="fldCardExpiryDate" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
          <LabelPart><%= this.GetMetadata(".CardExpiryDate_Label").SafeHtmlEncode() %></LabelPart>
          <ControlPart>
                  <table cellpadding="0" cellspacing="0" border="0">
                      <tr>
                          <td>
                          <%: Html.DropDownList("expiryMonth", GetList(1, 12, this.GetMetadata(".Month")), new
                              {
                                  @id = "ddlExpiryMonth"
                              }) %>
                          </td>
                          <td>&#160;</td>
                          <td>
                          <%: Html.DropDownList("expiryYear", GetList(DateTime.Now.Year, DateTime.Now.Year + 20, this.GetMetadata(".Year")), new
                              {
                                  @id = "ddlExpiryYear"
                              }) %>
                          <%: Html.Hidden("expiryDate", "", new
                              {
                                  @id = "hdnExpiryDate",
                                  @validator = ClientValidators.Create().Custom("isValidCardExpiryDate")
                              }) %>
                          </td>
                      </tr>
                  </table>
          </ControlPart>
          </ui:InputField>
    
     <%------------------------
        CVC 
      -------------------------%>    
            <ui:InputField ID="fldCVC" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
            <LabelPart><%= this.GetMetadata(".CardSecurityCode_Label").SafeHtmlEncode() %></LabelPart>
            <ControlPart>
                <div id="dvCvvContainer"></div>
                <%: Html.Hidden("cardSecurityCode", "", new
                    {
                        @id = "hdnCardSecurityCode", 
                        @validator = ClientValidators.Create().Custom("isValidCardSecurityCode")
                    }) %>
                  </ControlPart>
            </ui:InputField>
            
            <div class="floatGuideBox cardSecurityNumberGuide" id="cardSecurityCodeGuide" >
                <%= this.GetMetadata(".CardSecurityCode_Guide").HtmlEncodeSpecialCharactors() %>
            </div> 
        <center>
            <%: Html.Button(this.GetMetadata(".Button_Continue"), new {@id = "btnRegisterCardAndDeposit", @class = "ContinueButton button"}) %>
            <span hidden class ="error" id="submitRegisterCardForm"></span>
        </center>
      <% } %>
 </form>
          
<script language="javascript" type="text/javascript">
    $(document).ready(function() {
        $('#formRegisterPayCard').initializeForm();
        initRegisterCardForm();
    });
    </script>
</ui:Panel> 
</tabs>
</ui:TabbedContent>

<script language="javascript" type="text/javascript">
    var securityFieldCss = { 'font-size': '15px', 'height': '1.4em', 'line-height': '1.4em', 'font-family': 'Arial', 'color': '#666', 'background-color': '#dbe0e6', 'background-image': 'none', 'text-align': 'center', 'vertical-align': 'middle', 'direction': 'ltr', 'border': '1px solid #FFF', 'border-radius': '0', 'padding': '7px 5px 7px 35px', 'width': '478px', 'min-width': '80px', 'max-width': '500px', 'padding-left': '2%' };

    function tryToSubmitTransaction(payCardId, btn) {
       
        <% if (Model.Type == TransactionType.Withdraw)
        { %>
        tryToSubmitWithdrawInputForm(payCardId, function () {
            btn.toggleLoadingSpin(false);
        });
        <% } else { %>
        tryToSubmitDepositInputForm(payCardId, function() {
            btn.toggleLoadingSpin(false);
        });
        <% } %>
    }

    function isValidInputForm() {
        <% if (Model.Type == TransactionType.Deposit)
              { %>
           return isDepositInputFormValid();
            <% } 
            else { %>
           return isWithdrawInputFormValid();
            <% } %>
    }

    function initCardForm(isRegisterCardTab) {
        if (hasSdkLoadError()) {
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

    function initWithdrawCardForm() {
        var formRecentCards = $('#formRecentCards');
        var $btn = $('#btnDepositWithExistingCard');

        $btn.click(function(e) {
            e.preventDefault();

            var payCard = $('#paycards-selector input[name="existingPayCard"]:checked');
            $('#hExistingPayCardID').val(payCard.val());

            formRecentCards.data("validator").settings.ignore = ":hidden:not('#hExistingPayCardID')";

            if (!isValidInputForm() || !formRecentCards.valid()) {
                formRecentCards.trigger('submit');
                return;
            }

            $btn.toggleLoadingSpin(true);

            tryToSubmitWithdrawInputForm($('#hExistingPayCardID').val(), function () {
                $btn.toggleLoadingSpin(false);
            });
        });

    }

    function initExistingCardForm() {
        var paymentForm = initCardForm(false);
  
       var formRecentCards = $('#formRecentCards');

        var $btn = $('#btnDepositWithExistingCard');
                                                 
        $btn.click(function (e) {
            e.preventDefault();

            var payCard = $('#paycards-selector input[name="existingPayCard"]:checked');
            $('#hExistingPayCardID').val(payCard.val());

            var cardToken = payCard.attr('data-cardtoken');

            formRecentCards.data("validator").settings.ignore = ":hidden:not('#hExistingPayCardID, #hdnCardSecurityCode2')";

           if (!isValidInputForm() || !formRecentCards.valid()) {
                formRecentCards.trigger('submit');
                return;
            }

           $btn.toggleLoadingSpin(true);

            paymentForm.submitCvv({CardToken : cardToken}).then(
                function(data) {
                    if (data.Success == true) {
                        $('#identityNumber').val(cardToken);

                        tryToSubmitTransaction($('#hExistingPayCardID').val(), $btn);
                    } else {
                        showSubmitErrorMesage('Error', $('#submitExistingCardFormError'));
                        $btn.toggleLoadingSpin(false);
                        $btn.prop('disabled', false);
                    }
                },
                    function (data) {
                        showSubmitErrorMesage(data.ResponseMessage, $('#submitExistingCardFormError'));
                        $btn.toggleLoadingSpin(false);
                        $btn.prop('disabled', false);
                    }
            );
        });
    }

    function initRegisterCardForm() {

        var formSelector = '#formRegisterPayCard';
        // initialize the sensitive fields
        var paymentForm = initCardForm(true);

        if (paymentForm == undefined) {
            return;
        }

        var isLoading = true;
        paymentForm.fields['card-number'].on('status', function(evt, data) {
            
            if (!isLoading) {
                $('#hdnCardType').val(data.type);
                $('#hdnCardSubType').val(data.subtype);
                InputFields.fields['fldCardNumber'].validator.element($('#hdnCardNumberValidator'));
            }

            isLoading = false;
            $('#dvCardNumberWrapper .card-type').attr('data-cardtype', data.type);
        });

        var $btn = $('#btnRegisterCardAndDeposit');

        $btn.on('click', function(e) {
            e.preventDefault();

            var isInputFormValid = isValidInputForm();
 
            $(formSelector).data("validator").settings.ignore = ":hidden:not('#hdnExpiryDate, #hdnCardType, #hdnCardNumberValidator, #hdnCardSecurityCode, #hdnCardHolderName')"; 

            if (!isInputFormValid || !$(formSelector).valid()) {
                $(formSelector).trigger('submit');
                $btn.toggleLoadingSpin(false);
                return;
            }
      
            $btn.toggleLoadingSpin(true);
            $btn.prop('disabled', true);

            paymentForm.submit().then(
               function (data) {
                   if (data.Success == true) {
                       $('#identityNumber').val(data.Data.CardToken);

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

                               tryToSubmitTransaction(json.payCardID, $btn);
                           },
                           error: function (xhr, textStatus, errorThrown) {
                               alert("error");
                               $btn.toggleLoadingSpin(false);
                           }
                       };
                       $(formSelector).ajaxForm(options);
                       $(formSelector).submit();
                   } else {
                       showSubmitErrorMesage("Error", $('#submitRegisterCardForm'));
                       $btn.toggleLoadingSpin(false);
                       $btn.prop('disabled', false);
                   }
               },
               function (data) {
                   showSubmitErrorMesage(data.ResponseMessage, $('#submitRegisterCardForm'));
                   $btn.toggleLoadingSpin(false);
                   $btn.prop('disabled', false);
               }
           );
        });
    }
</script>

<ui:MinifiedJavascriptControl runat="server" ID="script" AppendToPageEnd="true" Enabled="true">
    <script type="text/javascript">
    
        function isValidCardNumber() {
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
            if (!window.CdePaymentFormForRegisterCard.fields['card-security-code'].valid) {
                return '<%= this.GetMetadata(".CardSecurityCode_Invalid")%>';
            }

            return true;
        }

         function isValidCvvForExistingCard() {
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
            var expiryDate = $('#fldCardExpiryDate input[name="expiryDate"]');

            var date = new Date();
            var currentYear =  date.getFullYear();
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

    .error {
        color: #DE1B18;
        width: 100%;
        font-size: 14px;
        margin-top: 7px;
    }

        #dvCardNumberWrapper .card-type {
            width: 33px;
            height: 19px;
            display: block;
            position: absolute;
            left: 3px;
            top: 9px;
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

            #dvCardNumberWrapper .card-type[data-cardtype='dankort'] {
                background-position: -3px -378px;
            }

    iframe#Pan, iframe#Cvv {
        height: 35px;
    }
   
    #paycards-selector li label {
        padding-left: 30px;
        background: url(//cdn.everymatrix.com/images/icon/credit-cards.png) no-repeat -3px -35px;
        background-size: 32px;
    }

        #paycards-selector li label[data-cardtype='visa'] {
            background-position: -3px -59px;
        }

        #paycards-selector li label[data-cardtype='visa_electron'] {
            background-position: -3px -87px;
        }

        #paycards-selector li label[data-cardtype='mastercard'] {
            background-position: -3px -115px;
        }

        #paycards-selector li label[data-cardtype='maestro'] {
            background-position: -3px -142px;
        }

        #paycards-selector li label[data-cardtype='discover'] {
            background-position: -3px -169px;
        }

        #paycards-selector li label[data-cardtype='amex'] {
            background-position: -3px -193px;
        }

        #paycards-selector li label[data-cardtype='jcb'] {
            background-position: -3px -214px;
        }

        #paycards-selector li label[data-cardtype='diners_club_carte_blanche'] {
            background-position: -3px -234px;
        }

        #paycards-selector li label[data-cardtype='diners_club_international'] {
            background-position: -3px -234px;
        }

        #paycards-selector li label[data-cardtype='laser'] {
            background-position: -3px -256px;
        }

        #paycards-selector li label[data-cardtype='dankort'] {
            background-position: -3px -256px;
        }

</style>
