<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Components.AmountSelectorViewModel>" %>
<%@ Import Namespace="CM.Web.UI" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="System.Globalization" %>

<script runat="server">

    public bool IsAmountVisible = true; 
    protected override void OnInit(EventArgs e)
    {
        try
        {
            if (this.Model != null && this.Model.PaymentDetails != null && this.Model.PaymentDetails.VendorID == VendorID.Envoy && !this.Model.PaymentDetails.UniqueName.Equals("FundSend", StringComparison.InvariantCultureIgnoreCase))
            {
                IsAmountVisible = false;
               // fldAmount.Visible = false;
            }
        }
        catch (Exception ex) {
            Logger.Exception(ex);
        }
        base.OnInit(e);
    
    }
</script>

<ul class="AmountFields">
	<li class="FormItem fldCurrency" id="fldCurrency">
		<label class="FormLabel" for="selectCurrency"><%= this.GetMetadata(".Currency_Label").SafeHtmlEncode()%></label>
		<select id="selectCurrency" class="FormInput" <%= this.Model.IsCurrencyChangable ? "" : "disabled=\"disabled\""%> data-rates="<%= Model.GetCurrencyRatesJson().SafeHtmlEncode()%>">
		<% foreach (CurrencyData currency in this.Model.SupportedCurrencies)
		{
		%>
			<option value="<%= currency.Code.SafeHtmlEncode() %>" data-limits="<%= this.Model.GetLimitsPerCurrencyJson(currency).SafeHtmlEncode() %>"><%= currency.GetDisplayName().SafeHtmlEncode() %></option>
		<%
		} 
		%>
		</select>
		<%: Html.Hidden("currency", string.Empty, new { @class = "Hidden", autocomplete = "off" })%>
	</li>
	<li class="FormItem fldAmount" id="fldAmount" >
		<div class="AmountBox">
			<label class="FormLabel" for="selectAmount"><%= this.GetMetadata(".Amount_Label").SafeHtmlEncode()%></label>
			<div class="AmountContainer">
				<a class="Button AmountInfo DecreaseAmount" id="decreaseAmount" href="#" >
					<strong class="ButtonText">-</strong>
				</a>
				<a class="Button AmountInfo IncreaseAmount" id="increaseAmount" href="#">
					<strong class="ButtonText">+</strong>
				</a>
				<%: Html.TextBox("amount", "", new Dictionary<string, object>()  
				{ 
					{ "class", "FormInput" },
					{ "id", "selectAmount" },
					{ "autocomplete", "off" },
					{ "placeholder", this.GetMetadata(".Amount_Choose") },
					{ "required", "required" },
					{ "type", "number" },
					{ "data-validator", ClientValidators.Create().Custom("AmountSelector.validateAmount") },
					{ "data-debit", this.Model.IsDebitSource.ToString().ToLowerInvariant() },
					{ "data-increment", this.GetMetadata(".Amount_Increment").SafeHtmlEncode() }
				}) %>
			</div>
			<% if (this.Model.IsDebitSource)
				{ %>
			<span class="DebitValueMessage Hidden"><%= this.GetMetadata(".Debit_Message") %><span class="DebitValueCurrency"></span> <span id="debitAmount" class="DebitValueAmount">0</span></span>
			<% } %>
			<span class="FormStatus">Status</span>
		</div>
		<span class="FormHelp"></span>
		<div class="AmountText">
			<span class="MinAmount Hidden"><span>Min</span> <span class="AmountValue"><%= this.GetMetadata(".Min").SafeHtmlEncode() %></span></span>		
			<span class="MaxAmount Hidden"><span>Max</span> <span class="AmountValue"><%= this.GetMetadata(".Max").SafeHtmlEncode() %></span></span>
		</div>
	</li>
    <% if (Settings.MobileV2.IsV2DepositProcessEnabled) { %>

    <li class="FormItem DepositExtraButtons" id="DepositExtraButtons">
        <ul class="Container Cols-3">
    <%  int index = 0;
        foreach (var quickAmountValuePath in Metadata.GetChildrenPaths("Metadata/Settings/V2/AmountSelector_QuickAmountValues"))
        {
           index++;
           string quickValue = this.GetMetadata(string.Format("{0}.Value", quickAmountValuePath)).SafeHtmlEncode();
           if (string.IsNullOrWhiteSpace(quickValue))
               continue;
           %>
            <li class="Container Col DepositExtraItem">
                <a class="Button DepositButtons ExtraBTN<%= index %>" id="ExtraBTN<%= index %>" href="#">
                    <span class="ButtonIcon icon-plus"></span>
			        <span class="ButtonText"><%= quickValue %></span>
		        </a>
            </li>
    <% } %>

        </ul>
    </li>
    <% }  %>

</ul>

<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="true" AppendToPageEnd="true">
<script type="text/javascript">

	function AmountSelector() {
		var gamingAccount, lockedCurrency;

		var currField = $('#fldCurrency'),
			currInput = $('#currency'),
			currSelect = $('#selectCurrency'),
			amtField = $('#fldAmount'),
			amtInput = $('#selectAmount');

		var	currencyRates = currSelect.data('rates'),
			isDebitValue = amtInput.data('debit'),
			amountIncrement = amtInput.data('increment');

		var amount = new CMS.views.AmountInput(amtInput);

		function lockCurrency(currency) {
			lockedCurrency = currency;

			setCurrency(lockedCurrency)
			currSelect.prop('disabled', true);
		}

		function updateGamingAccount(accountData) {
			gamingAccount = accountData;
			if (isDebitValue)
				AmountSelector.account = gamingAccount.Amount;

			var currency = lockedCurrency || gamingAccount.Currency || '';
			if (currency == currInput.val())
				return;

			if (!lockedCurrency)
				setCurrency(currency);

			setAmount(amount.val());
		}

		function allSourceAmount() {
			setAmount(isDebitValue ? gamingAccount.Amount : 0);
		}

		$('#increaseAmount').click(function () {
			setAmount(Math.floor(amount.val()) + amountIncrement);
			return false;
		});

		$('#decreaseAmount').click(function () {
			setAmount(Math.ceil(amount.val()) - amountIncrement);
			return false;
		});

		$('a.DepositButtons').click( function(evt){
		    evt.preventDefault();
		    var link = $(this);
		    var amount = Math.floor($('#selectAmount').val());
		    var cash = parseFloat(link.text().trim().replace(' ','')) + amount;     
		    cash = cash.toString();
		    setAmount(cash);
		});

		amtInput.change(function () {
			setAmount($(this).val());
		});

		currSelect.change(function () {
			setCurrency($(this).val());
		});

		function setCurrency(currency) {
			currSelect.val(currency);
			currInput.val(currency);

			var limits = $('option[value=' + currency + ']', currField).data('limits') || {},
				min = limits.min || 0,
				max = limits.max || 0;
			
			AmountSelector.min = min;
			AmountSelector.max = max;

			toggleLimitField($('.MinAmount', amtField), min);
			toggleLimitField($('.MaxAmount', amtField), max);
		}

		function toggleLimitField(field, value) {
			field.toggleClass('Hidden', !value);

			if (value) 
				$('.AmountValue', field).text(value); 
		}

		function setAmount(value) {
		    if(value < 0){
		        return;
		    }
			amount.val(value);
			
			if (isDebitValue) {
				var accountCurrency = gamingAccount.Currency,
					inputCurrency = currInput.val(),
					debitValue = convertCurrency(amount.val(), inputCurrency, accountCurrency);
				
				amtField.find('.DebitValueMessage')
					.toggleClass('Hidden', (debitValue == 0 || inputCurrency == accountCurrency))
					.find('.DebitValueCurrency')
						.text(accountCurrency)
						.end()
					.find('.DebitValueAmount')
						.text(debitValue.toFixed(2));
			}
		}

		function convertCurrency(value, from, to) {
			if (from == to)
				return value;
			return value / currencyRates[from] * currencyRates[to];
		}

		return {
			lock: lockCurrency,
			update: updateGamingAccount,
			value: setAmount,
			all: allSourceAmount
		} 
	}

	AmountSelector.min = AmountSelector.max = 0;
	AmountSelector.validateAmount = function (value) {
		var min = AmountSelector.min,
			max = AmountSelector.max,
			account = AmountSelector.account,
			creditAmount = parseFloat(this, 10),
			debitAmount = $('#debitAmount').length ? $('#debitAmount').text() : creditAmount
			amountValidator = AmountSelector.customAmountValidator;

		if (isNaN(debitAmount) || debitAmount == 0)
			return '<%= this.GetMetadata(".Amount_Empty").SafeJavascriptStringEncode() %>';

		if ((debitAmount < 0) || (min > 0 && debitAmount < min) || (max > 0 && debitAmount > max))
			return '<%= this.GetMetadata(".Amount_OutsideRange").SafeJavascriptStringEncode() %>';

		if (account !== undefined && debitAmount > account)
			return '<%= this.GetMetadata(".Amount_Insufficient").SafeJavascriptStringEncode() %>';

		if (amountValidator) {
			var result = amountValidator(debitAmount, creditAmount);
			if (result !== true)
				return result;
		}

		return true;
	}
    $(function () {
        var isAmountVisible = <%=IsAmountVisible ? "true" : "false" %>;
        if(!isAmountVisible){
            $("#fldAmount").hide();
        }
    });
</script>
</ui:MinifiedJavascriptControl>