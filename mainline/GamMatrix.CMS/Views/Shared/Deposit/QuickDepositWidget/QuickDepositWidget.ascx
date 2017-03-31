<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="CM.State" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="System.Globalization" %>

<script type="text/scripC#" runat="server">
    private string ID { get; set; }
    private bool IsRealMoney { get; set; }
    private string CasinoWalletCurrency { get; set; }
    private long GammingAccountId { get; set; }
    private List<PayCardInfoRec> PayCards { get; set; }
    private string _sdkUrl;

    private string GetSdkUrl()
    {
        if(!this.GetEnabledPaymentMethods().Any(pm => pm.IsMoneyMatrixPaymentMethod()))
        {
            return string.Empty;
        }
        if (GamMatrixClient.GetPayCards(true).Where(p => p.ActiveStatus == ActiveStatus.Active && p.IsMoneyMatrixCreditCard()).ToList().Count < 0)
        {
            return string.Empty;
        }

        return string.IsNullOrEmpty(_sdkUrl) ? _sdkUrl = GamMatrixClient.GetSdkUrl(Request.UserAgent, HttpContext.Current.Request.GetRealUserAddress()) : _sdkUrl;
    }

    private string GetLimitationScript()
    {
        StringBuilder sb = new StringBuilder();
        sb.AppendFormat(CultureInfo.InvariantCulture, "var __paycard_limit = [];");

        foreach (var payCard in PayCards)
        {
            var paymentMethod = payCard.GetPaymentMethod();
            Range range = paymentMethod.GetDepositLimitation(CasinoWalletCurrency);
            decimal minAmount = MoneyHelper.TransformCurrency(range.Currency
                , CasinoWalletCurrency
                , range.MinAmount
                );
            decimal maxAmount = MoneyHelper.TransformCurrency(range.Currency
                , CasinoWalletCurrency
                , range.MaxAmount
                );
            MoneyHelper.SmoothCeilingAndFloor(ref minAmount, ref maxAmount);
            sb.AppendFormat(CultureInfo.InvariantCulture, "__paycard_limit['{0}'] = {{ MinAmount:{1}, MaxAmount:{2} }};"
                , payCard.ID
                , minAmount
                , maxAmount
                );
        }

        return sb.ToString();
    }

    protected override void OnPreRender(EventArgs e)
    {
        base.OnPreRender(e);

        this.ID = string.Format(CultureInfo.InvariantCulture, "_{0}", Guid.NewGuid().ToString("N").Truncate(6));
        this.IsRealMoney = (bool)this.ViewData["RealMoney"];

        if (!Profile.IsAuthenticated || !Settings.Casino_EnableQuickDeposit || !IsRealMoney)
        {
            this.Visible = false;
            return;
        }

        var list = GamMatrixClient.GetUserGammingAccounts(CustomProfile.Current.UserID, false);
        var account = list.FirstOrDefault(a => a.Record.ActiveStatus == ActiveStatus.Active && a.IsBalanceAvailable && a.Record.VendorID == VendorID.CasinoWallet);
        if (account == null)
        {
            this.Visible = false;
            return;
        }

        CasinoWalletCurrency = account.BalanceCurrency;
        GammingAccountId = account.ID;

        PayCards = new List<PayCardInfoRec>();

        var paymentMethods = this.GetEnabledPaymentMethods();
        var payCards = GamMatrixClient.GetPayCards(true).Where(p => p.ActiveStatus == ActiveStatus.Active).ToList();

        if (paymentMethods.Any(pm => pm.VendorID == VendorID.PaymentTrust || pm.VendorID == VendorID.Neteller))
        {
            var gmPayCards = payCards.Where(p => !p.IsDummy && ((p.VendorID == VendorID.PaymentTrust && paymentMethods.Contains(p.GetPaymentMethod())) ||
                                                                (p.VendorID == VendorID.Neteller && paymentMethods.Contains(p.GetPaymentMethod())))).ToList();
            if (gmPayCards.Count > 0)
            {
                PayCards.AddRange(gmPayCards);
            }
        }

        if (paymentMethods.Any(pm => pm.VendorID == VendorID.Moneybookers))
        {
            var moneyBookersCards = payCards.Where(p => p.VendorID == VendorID.Moneybookers).ToList();
            if (moneyBookersCards.Count > 0)
            {
                PayCards.Add(moneyBookersCards.Last());
            }
        }

        if (paymentMethods.Any(pm => pm.IsMoneyMatrixPaymentMethod()))
        {
            var moneyMatrixCards = payCards.Where(p => (p.IsMoneyMatrixCreditCard() && paymentMethods.Contains(p.GetPaymentMethod())) ||
                                                       (p.IsMoneyMatrixApmPayCard("Neteller") && paymentMethods.Contains(p.GetPaymentMethod())) ||
                                                       (p.IsMoneyMatrixApmPayCard("Skrill") && paymentMethods.Contains(p.GetPaymentMethod()))).ToList();

            if (moneyMatrixCards.Count > 0)
            {
                PayCards.AddRange(moneyMatrixCards);
            }
        }

        PayCards = PayCards.OrderBy(p => p.LastSuccessDepositDate).ToList();
    }

    protected List<PaymentMethod> GetEnabledPaymentMethods()
    {
        var paymentMethods = PaymentMethodManager.GetPaymentMethods();

        var query = paymentMethods.Where(p => p.IsAvailable && p.SupportDeposit && p.IsVendorEnabled());

        if (Profile.IsAuthenticated)
        {
            if (Profile.UserCountryID > 0)
                query = query.Where(p => p.SupportedCountries.Exists(Profile.UserCountryID));

            if (!string.IsNullOrWhiteSpace(Profile.UserCurrency))
                query = query.Where(p => p.SupportedCurrencies.Exists(Profile.UserCurrency));

            query = query.Where(p => !Profile.IsInRole(p.DenyAccessRoleNames));
        }

        return query.ToList();
    }

</script>

<script src="<%= GetSdkUrl() %>"></script>
<script>
    var CdePaymentFormForExistingPayCard;
</script>
<script src="<%= Url.Content("/js/jquery/jquery.creditCardValidator.js") %>"></script>

<div id="quickDepositWidth<%=ID %>">
    <% using (Html.BeginRouteForm("Deposit", new { @action = "ProcessQuickDepositTransaction", @_sid = Profile.SessionID }, FormMethod.Post, new { @method = "post", @id = "formQuickDeposit" }))
       { %>

    <%------------------------------------------
    IovationBlackbox
 -------------------------------------------%>
  <%if (Settings.IovationDeviceTrack_Enabled){ %>
        <% Html.RenderPartial("/Components/IovationTrack", this.ViewData);  %>
        <%} %>
    <span class="QuickDepositCurrencyAmount">
        <span class="QuickDepositCurrency"><%=CasinoWalletCurrency %></span>
        <%: Html.TextBox("amount", "", new {
            @placeholder = this.GetMetadata(".Amount_PlaceHolder"),
            @maxlength = 10,
            @id = "txtQuickDepositAmount",
            @class = "DepositAmountInput"
        }) %>
    </span>
    <% if (PayCards.Any())
       { %>
    <div id="quickDepositPaymentMethod">
        <iframe id="id_coveriframe" class="coveriframe"></iframe>
        <div class="quick-deposit-available-methods">
            <% foreach (var payCard in PayCards)
                {
                    var paymentMethod = payCard.GetPaymentMethod();
                    if (paymentMethod == null)
                        continue;

                    var displayName = payCard.DisplayName;
                    if (displayName.Length > 12 && payCard.VendorID == VendorID.Neteller)
                        displayName = displayName.Substring(0, 9) + "...";
                    if (payCard.VendorID == VendorID.MoneyMatrix)
                    {
                        if(payCard.IsMoneyMatrixCreditCard())
                        {
                            displayName = displayName.Replace("******", "...");
                        }
                        else
                        {
                            displayName = displayName.Substring(0, 9) + "...";
                        }
                    }
            %>

            <%-- Need to use GetMoneyMatrixMethodUniqueNameQuickDeposit instead of GetMoneyMatrixMethodUniqueName after MM CC separate cachiers will be added --%>
            <%-- or need to extend GetMoneyMatrixMethodUniqueName with separate methods like in GetMoneyMatrixMethodUniqueNameQuickDeposit --%>
            <div class="quick-deposit-item" data-vendorid="<%= payCard.VendorID.ToString() %>" 
                data-cardname="<%= payCard.DisplayName %>" data-paycardid="<%= payCard.ID %>" data-paymentmethodname="<%= paymentMethod.UniqueName.SafeHtmlEncode() == "MoneyMatrix" ? 
                    payCard.GetMoneyMatrixMethodUniqueName() : paymentMethod.UniqueName.SafeHtmlEncode() %>"
                data-cardtoken="<%= payCard.DisplayNumber.HtmlEncodeSpecialCharactors() %>">
            <div class="quick-deposit-logo <%= paymentMethod.UniqueName.Replace(" ", "").ToLowerInvariant().SafeHtmlEncode() == "moneymatrix" ? 
                    payCard.GetMoneyMatrixMethodUniqueName().ToLowerInvariant() : paymentMethod.UniqueName.Replace(" ", "").ToLowerInvariant().SafeHtmlEncode()%>"></div>
            <div class="quick-deposit-info"><%= payCard.VendorID == VendorID.Moneybookers ? "" : displayName.SafeHtmlEncode() %></div>
            </div>
            <% } %>
        </div>
        <div class="quick-deposit-selected-method">
            <div class="quick-deposit-menu"></div>
            <div style="clear: both;"></div>
        </div>
    </div>
    <%: Html.TextBox("cvc", "", new {
        @placeholder = this.GetMetadata(".CVC_PlaceHolder"),
        @maxlength = 4,
        @id = "txtQuickDepositCVC",
        @class = "quickDepositCVC"
    }) %>
    <%: Html.TextBox("secureID", "", new {
        @placeholder = this.GetMetadata(".SecurityKey_PlaceHolder"),
        @maxlength = 6,
        @id = "txtQuickDepositSecurityKey",
        @class = "quickDepositSecurityKey"
    }) %>
    
    <%-------MoneyMatrix------------------------%>
    <div id="txtQuickDepositMmCcCvv"></div>

    <%: Html.TextBox("NetellerSecret", "", new {
        @placeholder = this.GetMetadata(".NetellerSecret_PlaceHolder"),
        @maxlength = 6,
        @id = "txtQuickDepositMmNetellerSecret",
        @class = "quickDepositMmNetellerSecret"
    }) %>
    <%-------MoneyMatrix------------------------%>

    <% } %>
    <%: Html.Hidden("vendorID") %>
    <%: Html.Hidden("paymentMethodName") %>
    <%: Html.Hidden("payCardID") %>
    <%: Html.Hidden("gammingAccountID", GammingAccountId) %>
    <%: Html.Hidden("currency", CasinoWalletCurrency) %>
    <%: Html.Hidden("securityKey") %>
    <%: Html.Hidden("payCardNickAlias") %>
    <%: Html.Hidden("cardToken") %>
    <%: Html.Button(this.GetMetadata(".Button_QuickDeposit"), new { 
        @id = "btnQuickDeposit", 
        @style = "float: left;",
        @type = "button"
    })%>
    <% } %>
</div>

<ui:MinifiedJavascriptControl ID="scriptQuickDeposit" runat="server" Enabled="true">
    <script type="text/javascript">
        
        function formatAmount(num) {
            num = num.toString().replace(/\$|\,/g, '');
            if (isNaN(num)) num = '0';
            sign = (num == (num = Math.abs(num)));
            num = Math.floor(num * 100 + 0.50000000001);
            cents = num % 100;
            num = Math.floor(num / 100).toString();
            if (cents < 10) cents = '0' + cents;
            for (var i = 0; i < Math.floor((num.length - (1 + i)) / 3) ; i++)
                num = num.substring(0, num.length - (4 * i + 3)) + ',' + num.substring(num.length - (4 * i + 3));
            return num + '.' + cents;
        }

        <%= GetLimitationScript() %>

        function isQuickDepositInputFormValid() {
            var __min_limit = 0.00;
            var __max_limit = 0.00;

            var payCardID = $('#formQuickDeposit input[name="payCardID"]').val();
            var limit = __paycard_limit[payCardID];
            if (limit != null) {
                __min_limit = limit.MinAmount;
                __max_limit = limit.MaxAmount;
            }

            var amount = $('#txtQuickDepositAmount').val();
            amount = amount.replace(/\$|\,/g, '');
            amount = parseFloat(amount, 10);
            if (isNaN(amount) || amount <= 0) {
                alert('<%= this.GetMetadata(".CurrencyAmount_Empty").SafeJavascriptStringEncode() %>');
                return false;
            }

            <% if (PayCards.Any())
               { %>
            if ((__min_limit > 0.00 && amount < __min_limit) ||
            (__max_limit > 0.00 && amount > __max_limit)) {
                alert('<%= this.GetMetadata(".CurrencyAmount_OutsideRange").SafeJavascriptStringEncode() %>');
                return false;
            }

            var vendorID = $('#formQuickDeposit input[name="vendorID"]').val();
            var paymentMethodName = $('#formQuickDeposit input[name="paymentMethodName"]').val();

            if (vendorID == '<%= VendorID.PaymentTrust.ToString() %>') {
                var cvc = $('#txtQuickDepositCVC').val();
                if (cvc == '') {
                    alert('<%= this.GetMetadata(".CardSecurityCode_Empty").SafeJavascriptStringEncode() %>');
                    return false;
                }
                if (cvc.length < 3) {
                    alert('<%= this.GetMetadata(".CardSecurityCode_Invalid").SafeJavascriptStringEncode() %>');
                    return false;
                }
            }

            if (vendorID == '<%= VendorID.Neteller.ToString() %>') {
                var secureID = $('#txtQuickDepositSecurityKey').val();
                if (secureID == '') {
                    alert('<%= this.GetMetadata(".SecurityKey_Empty").SafeJavascriptStringEncode() %>');
                    return false;
                }
                if (secureID.length < 6) {
                    alert('<%= this.GetMetadata(".SecurityKey_Invalid").SafeJavascriptStringEncode() %>');
                    return false;
                }
            }

            // MoneyMatrix
            if (vendorID === '<%= VendorID.MoneyMatrix.ToString() %>') {
                if (paymentMethodName === "MoneyMatrix_Neteller") {
                    var secureID = $('#txtQuickDepositMmNetellerSecret').val();
                    if (secureID == '') {
                        alert('<%= this.GetMetadata(".MmNetellerSecret_Empty").SafeJavascriptStringEncode() %>');
                        return false;
                    }
                    if (secureID.length < 6) {
                        alert('<%= this.GetMetadata(".MmNetellerSecret_Invalid").SafeJavascriptStringEncode() %>');
                        return false;
                    }
                }

                if (paymentMethodName === "MoneyMatrix_Visa" ||
                    paymentMethodName === "MoneyMatrix_MasterCard" ||
                    paymentMethodName === "MoneyMatrix_Dankort" ||
                    paymentMethodName === "MoneyMatrix") {
                    if (isValidCvvForExistingCard() !== true) {
                        return false;
                    }
                }
            }
            <% } %>

            return true;
        }

        <% if (PayCards.Any())
           { %>
        function onSelectionChanged(selectedNewItem) {
            var paymentMethodName = selectedNewItem.data('paymentmethodname');
            var vendorID = selectedNewItem.data('vendorid');
            var payCardID = selectedNewItem.data('paycardid');
            var cardAlias = selectedNewItem.data('cardname');
            var cardToken = selectedNewItem.data('cardtoken');

            $('#formQuickDeposit input[name="vendorID"]').val(vendorID);
            $('#formQuickDeposit input[name="paymentMethodName"]').val(paymentMethodName);
            $('#formQuickDeposit input[name="payCardID"]').val(payCardID);
            $('#formQuickDeposit input[name="payCardNickAlias"]').val(cardAlias);
            $('#formQuickDeposit input[name="cardToken"]').val(cardToken);

            var amount = $('#txtQuickDepositAmount').val();
            amount = formatAmount(amount);
            if ((amount && amount.toString() == "NaN") || amount <= 0)
                return;

            onVendorIDChanged();
        }

        function onVendorIDChanged() {
            var vendorID = $('#formQuickDeposit input[name="vendorID"]').val();
            var paymentMethodName = $('#formQuickDeposit input[name="paymentMethodName"]').val();

            if (vendorID == '<%=VendorID.PaymentTrust.ToString()%>') {
                $('#txtQuickDepositCVC').show();
                $('#txtQuickDepositSecurityKey').hide();
                // MoneyMatrix
                $('#txtQuickDepositMmCcCvv').hide();
                $('#txtQuickDepositMmNetellerSecret').hide();
            }
            else if (vendorID == '<%=VendorID.Neteller.ToString()%>') {
                $('#txtQuickDepositCVC').hide();
                $('#txtQuickDepositSecurityKey').show();
                // MoneyMatrix
                $('#txtQuickDepositMmCcCvv').hide();
                $('#txtQuickDepositMmNetellerSecret').hide();
            }
            else if (vendorID === '<%=VendorID.MoneyMatrix.ToString()%>') {
                $('#txtQuickDepositCVC').hide();
                $('#txtQuickDepositMmCcCvv').hide();
                $('#txtQuickDepositSecurityKey').hide();
                if (paymentMethodName === "MoneyMatrix_Visa" || paymentMethodName === "MoneyMatrix_MasterCard" ||
                    paymentMethodName === "MoneyMatrix_Dankort" || paymentMethodName === "MoneyMatrix") {
                    if (!hasSdkLoadError()) {
                        window.CdePaymentFormForExistingPayCard = new CDE.PaymentForm({
                            'card-security-code': {
                                selector: '#txtQuickDepositMmCcCvv',
                                css: {
                                    'font-size': '14px',
                                    'font-family': 'Arial',
                                    'text-align': 'center',
                                    'vertical-align': 'middle',
                                    'display': 'none',
                                    'position': 'relative',
                                    'float': 'left',
                                    'width': '65px',
                                    'margin-right': '5px',
                                    'padding': '6px',
                                    'border-radius': '0',
                                    'background-color': '#e7e3db',
                                    'color': '#555',
                                    'height': '14px',
                                    'margin-top': '0'
                                },
                                placeholder: '<%= this.GetMetadata(".MmCVC_PlaceHolder") %>'
                            }
                        });

                        $('#txtQuickDepositMmCcCvv').show();

                    } else {
                        $('#txtQuickDepositMmCcCvv').hide();
                    }
                }
                else if (paymentMethodName === "MoneyMatrix_Neteller") {
                    $('#txtQuickDepositMmCcCvv').hide();
                    $('#txtQuickDepositMmNetellerSecret').show();
                } else {
                    $('#txtQuickDepositMmNetellerSecret').hide();
                    $('#txtQuickDepositMmCcCvv').hide();
                }
            }
            else {
                $('#txtQuickDepositCVC').hide();
                $('#txtQuickDepositSecurityKey').hide();
                // MoneyMatrix
                $('#txtQuickDepositMmCcCvv').hide();
                $('#txtQuickDepositMmNetellerSecret').hide();
            }
        }

        var g_QuickDepositFormCallback = null;
        function tryToSubmitQuickDepositForm(callback) {
            if (!$('#formQuickDeposit').valid()) {
                if (callback !== null) callback();
                return false;
            }

            g_QuickDepositFormCallback = callback;
            var options = {
                dataType: "json",
                type: 'POST',
                success: function (json) {
                    if (g_QuickDepositFormCallback !== null)
                        g_QuickDepositFormCallback();

                    if (!json.success) {
                        if (json.error === "OUTRANGE") {
                            json.error = "<%=this.GetMetadata(".CurrencyAmount_OutsideRange").SafeJavascriptStringEncode() %>";
                        }
                        alert(json.error);
                        return;
                    }

                    if (json.status == 'success') {
                        reloadGameBalance();
                        alert('<%= this.GetMetadata(".Success_Message").SafeJavascriptStringEncode() %>');
                        return;
                    }

                    $('iframe#ifrQuickDepositWindow').remove();
                    $('<iframe style="border:0px;width:800px;height:600px;display:none" frameborder="0" scrolling="no" allowTransparency="true" id="ifrQuickDepositWindow" class="CasinoHallDialog"></iframe>').appendTo(self.document.body);
                    var $iframe = $('#ifrQuickDepositWindow', self.document.body).eq(0);
                    $iframe.modalex($iframe.width(), $iframe.height(), true, self.document.body);
                    $iframe.attr('src', '/Deposit/QuickDepositFormRedirect?sid=' + json.sid);
                    $iframe.parents('#simplemodal-container').addClass('simplemodal-quickdeposit');
                },
                error: function (xhr, textStatus, errorThrown) {
                    if (g_QuickDepositFormCallback !== null)
                        g_QuickDepositFormCallback();
                    alert(errorThrown);
                }
            };
            $('#formQuickDeposit').ajaxForm(options);
            $('#formQuickDeposit').submit();
            return true;
        }

        $(document).bind('QUICK_DEPOSIT_SUCESSED', function (e) {
            window.setTimeout(function () {
                reloadGameBalance();
                $('.simplemodal-quickdeposit a.simplemodal-close').trigger('click');
                alert('<%= this.GetMetadata(".Success_Message").SafeJavascriptStringEncode() %>');
            }, 100);
        });

        $(document).bind('QUICK_DEPOSIT_CANCELED', function (e) {
            window.setTimeout(function () {
                $('.simplemodal-quickdeposit a.simplemodal-close').trigger('click');
                alert('<%= this.GetMetadata(".Cancel_Message").SafeJavascriptStringEncode() %>');
            }, 100);
        });

        $(document).bind('QUICK_DEPOSIT_FAILED', function (e) {
            window.setTimeout(function () {
                $('.simplemodal-quickdeposit a.simplemodal-close').trigger('click');
                alert('<%= this.GetMetadata(".Transaction_Uncompleted").SafeJavascriptStringEncode() %>');
            }, 100);
        });
        <% } %>

        function initQuickDepositWidget() {
            var newElement = $('#quickDepositWidth<%=ID %>').clone();
            $('#quickDepositWidth<%=ID %>').remove();
            $('.CBQuickDeposit').append($(newElement).html());

            $('#txtQuickDepositAmount').change(function () {
                $(this).val(formatAmount($(this).val()));
            });

            <% if (PayCards.Any())
               { %>
            $('#txtQuickDepositAmount').keyup(function () {
                var amount = $(this).val();
                amount = formatAmount(amount);
                if ((amount && amount.toString() == "NaN") || amount <= 0) {
                    $('#quickDepositPaymentMethod').hide();
                    $('#txtQuickDepositCVC').hide();
                    $('#txtQuickDepositSecurityKey').hide();
                    // MoneyMatrix
                    $('#txtQuickDepositMmCcCvv').hide();
                    $('#txtQuickDepositMmNetellerSecret').hide();
                }
                else {
                    $('#quickDepositPaymentMethod').show();

                    onVendorIDChanged();
                }
            });

            $('#txtQuickDepositCVC').allowNumberOnly();

            $('#txtQuickDepositCVC').change(function () {
                $('#formQuickDeposit input[name="securityKey"]').val($(this).val());
            });

            $('#txtQuickDepositSecurityKey').change(function () {
                $('#formQuickDeposit input[name="securityKey"]').val($(this).val());
            });

            // MoneyMatrix
            $('#txtQuickDepositMmNetellerSecret').change(function () {
                $('#formQuickDeposit input[name="securityKey"]').val($(this).val());
            });

            $('.quick-deposit-selected-method').click(function () {
                var target_ifr = $("#id_coveriframe"),
                    target_ifr_body = $("#id_coveriframe").contents().find("body"),
                    target_pop = $("#quickDepositPaymentMethod .quick-deposit-available-methods");

                $('#quickDepositPaymentMethod').toggleClass('opened');
                if (!target_ifr_body.hasClass("iframe_blankstyle"))
                    target_ifr_body.addClass("iframe_blankstyle");
                target_ifr.css({ width: target_pop.width() + "px", height: target_pop.height() + "px" });
            });

            $('#btnQuickDeposit').click(function (e) {
                e.preventDefault();

                if (!isQuickDepositInputFormValid())
                    return false;

                $(this).toggleLoadingSpin(true);

                //---------------Tokenize MM CVV---------------
                var paymentMethodName = $('#formQuickDeposit input[name="paymentMethodName"]').val();

                if (paymentMethodName === "MoneyMatrix_Visa" ||
                    paymentMethodName === "MoneyMatrix_MasterCard" ||
                    paymentMethodName === "MoneyMatrix_Dankort" ||
                    paymentMethodName === "MoneyMatrix") {
                    var cardToken = $('#formQuickDeposit input[name="cardToken"]').val();

                    window.CdePaymentFormForExistingPayCard.submitCvv({ CardToken: cardToken })
                        .then(
                            function(data) {
                                if (data.Success !== true) {
                                    alert('Error: ' + data.ResponseMessage);
                                    $(this).toggleLoadingSpin(false);
                                    $(this).prop('disabled', true);
                                }
                            }
                        );
                }
                //---------------Tokenize MM CVV---------------

                tryToSubmitQuickDepositForm(function () {
                    $('#btnQuickDeposit').toggleLoadingSpin(false);
                });
            });

            var items = $('#quickDepositPaymentMethod .quick-deposit-available-methods .quick-deposit-item');

            items.each(function (index, item) {
                var jItem = $(item);

                if (index == 0) {
                    jItem.addClass('first');
                }

                if (index == items.length - 1) {
                    jItem.addClass('selected');
                    var selectedNewItem = jItem.clone();

                    onSelectionChanged(selectedNewItem);

                    $('#quickDepositPaymentMethod .quick-deposit-selected-method .quick-deposit-item').remove();
                    $('#quickDepositPaymentMethod .quick-deposit-selected-method').prepend(selectedNewItem);
                }

                jItem.click(function () {
                    var element = $(this);

                    if (element.hasClass('selected')) {
                        return;
                    }

                    $('#quickDepositPaymentMethod .quick-deposit-available-methods .quick-deposit-item.selected').removeClass('selected');
                    element.addClass('selected');

                    var selectedNewItem = element.clone();

                    onSelectionChanged(selectedNewItem);

                    $('#quickDepositPaymentMethod .quick-deposit-selected-method .quick-deposit-item').remove();
                    $('#quickDepositPaymentMethod .quick-deposit-selected-method').prepend(selectedNewItem);

                    $('#quickDepositPaymentMethod').toggleClass('opened');
                });
            });
            <% }
               else
               { %>

            $('#formQuickDeposit').attr('target', '_blank');
            $('#btnQuickDeposit').click(function (e) {
                e.preventDefault();

                if (!isQuickDepositInputFormValid())
                    return false;

                var amount = $('#txtQuickDepositAmount').val();
                amount = formatAmount(amount);
                window.open('/Deposit?depositAmount=' + amount);
            });
            <% } %>
        }

        $(function () {
            setTimeout(function () {
                initQuickDepositWidget();
            }, 100);
        });

        function reloadGameBalance() {
            try
            {
                for (var i = 0; i < $('iframe').length; i++) {
                    try {
                        var targetOrigin = '<%=this.GetMetadata("/Deposit/_Prepare_aspx.TargetOriginForPostMessage").SafeJavascriptStringEncode().DefaultIfNullOrWhiteSpace("") %>';
                        if (targetOrigin.trim() == '') {
                            targetOrigin = $('iframe')[i].src;
                            targetOrigin = targetOrigin.toString().toLowerCase();
                            if (targetOrigin.indexOf('/loader/start/') < 0)
                                continue;

                            targetOrigin = targetOrigin.substring(0, targetOrigin.indexOf('/loader/start/'));
                        }
                        var amount = formatAmount($('#txtQuickDepositAmount').val());
                        $('iframe')[i].contentWindow.postMessage('{"user_id":<%=CM.State.CustomProfile.Current.UserID %>, "message_type": "deposit_result", "success": true, "message": "<%=this.GetMetadata(".Success_Message").Replace("\n", "") %>", "amount":"' + amount + '", "currency": "<%=CasinoWalletCurrency%>"}', targetOrigin);
                    }
                    catch (err) { }
                }
            }
            catch (err) { }
        }

        function isValidCvvForExistingCard() {
            if (!window.CdePaymentFormForExistingPayCard.fields['card-security-code'].valid) {
                return alert('<%= this.GetMetadata(".MmCardSecurityCode_Invalid")%>');
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

    </script>
</ui:MinifiedJavascriptControl>

<style type="text/css">
    #txtQuickDepositMmNetellerSecret {
        display:none;
        position:relative;
        float:left;
        width:65px;
        margin-right:5px;
        padding: 0;
        background-color:#e7e3db;
        color:#555;height:28px;
        font-size:14px;
        margin-top:0
    }
    /*need to add thease styles to _import.css for each operator with correct images*/
    .quick-deposit-logo.moneymatrix_visa{background:url("https://static.gammatrix-dev.net/JetbullV3/img/payment-methods.png") 5px 5px no-repeat; height: 19px}
    .quick-deposit-logo.moneymatrix{background:url("https://static.gammatrix-dev.net/JetbullV3/img/payment-methods.png") 5px 5px no-repeat; height: 19px}
    .quick-deposit-logo.moneymatrix_mastercard{ background: url("https://static.gammatrix-dev.net/JetbullV3/img/payment-methods.png") 5px 5px no-repeat; height: 19px}
    .quick-deposit-logo.moneymatrix_dankort{background:url("https://static.gammatrix-dev.net/JetbullV3/img/payment-methods.png") 0 -23px no-repeat; height: 19px}
    .quick-deposit-logo.moneymatrix_neteller{background:url("https://static.gammatrix-dev.net/JetbullV3/img/payment-methods.png") -140px 4px no-repeat;height:19px;margin-top:2px}
    .quick-deposit-logo.moneymatrix_skrill{background:url("https://static.gammatrix-dev.net/JetbullV3/img/payment-methods.png") -140px -12px no-repeat;height:19px}
    
    /*need to add thease styles to _import.css for each operator with correct images*/
    #quickDepositPaymentMethod.opened
    .quick-deposit-logo.moneymatrix_visa{background:url("https://static.gammatrix-dev.net/JetbullV3/img/payment-methods.png") 5px 5px no-repeat; height: 19px}
    .quick-deposit-logo.moneymatrix{background:url("https://static.gammatrix-dev.net/JetbullV3/img/payment-methods.png") 5px 5px no-repeat; height: 19px}
    .quick-deposit-logo.moneymatrix_mastercard{ background: url("https://static.gammatrix-dev.net/JetbullV3/img/payment-methods.png") 5px 5px no-repeat; height: 19px}
    .quick-deposit-logo.moneymatrix_dankort{background:url("https://static.gammatrix-dev.net/JetbullV3/img/payment-methods.png") 0 -23px no-repeat; height: 19px}
    .quick-deposit-logo.moneymatrix_neteller{background:url("https://static.gammatrix-dev.net/JetbullV3/img/payment-methods.png") -140px 4px no-repeat;height:19px;margin-top:2px}
    .quick-deposit-logo.moneymatrix_skrill{background:url("https://static.gammatrix-dev.net/JetbullV3/img/payment-methods.png") -140px -12px no-repeat;height:19px}

    #txtQuickDepositMmCcCvv {
        display:none;
        position:relative;
        float:left;
        width:65px;
        margin-right:5px;
        padding: 6px;
        border: 0;
        height:14px;
        font-size:14px;
        margin-top: 0;
        padding-top: 0;
        padding-left: 0;
    }

    #Cvv {
        height: 28px;
        width: 72px;
    }
</style>