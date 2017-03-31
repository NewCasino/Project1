<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
    <script type="text/javascript" src="//cdn.everymatrix.com/_js/jquery/jquery.form.min.js"></script>
			<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 4 }); %>
	<div class="UserBox TransferBox CenterBox">
		<div class="BoxContent">
        <div class="buddytransfer_steps">
            <div id="select_friend">
                <% Html.RenderPartial("SelectFriend"); %>
            </div>
            <div id="prepare_step" style="display:none"></div>
            <div id="confirm_step" style="display:none"></div>
            <div id="error_step" style="display:none"> 
                <div class="ErrorInternal">                    
                    <% Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Error, 
	   (this.ViewData["ErrorMessage"] as string).DefaultIfNullOrEmpty(
            this.Request["ErrorMessage"].DefaultIfNullOrEmpty(
				this.GetMetadata(".Message")))) { IsHtml = true }); %> 
                </div>
                <div class="BackButtonWrapper">                       
                    <button type="submit" class="Button RegLink DepLink" id="btnTransferToExistingFriend"  onclick = "returnPreviousBuddyTransferStep(); return false;">
                        <span class="ButtonText"><%= this.GetMetadata(".Button_Back").SafeHtmlEncode()%></span>
                </button>               
                </div>  
            </div>
        </div>
     </div>
	</div>
	<script type="text/javascript">
		$(CMS.mobile360.Generic.input);
	</script>
<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="true" AppendToPageEnd="true">
<script language="javascript" type="text/javascript">
 
    var g_previousBuddyTransferSteps = new Array();

    function returnPreviousBuddyTransferStep() {
        if (g_previousBuddyTransferSteps.length > 0) {
            $('div.buddytransfer_steps > div').hide();
            var $last = g_previousBuddyTransferSteps.pop();
            $last.show();
        }
    }

    function showBuddyTransferError(errorText) {
        $('.StatusContainer .StatusMessage').text(errorText);
        g_previousBuddyTransferSteps.push($('div.buddytransfer_steps > div:visible'));
        $('div.buddytransfer_steps > div').hide();
        $('#error_step').show();
    }

    function showBuddyTransferPrepare(encryptedUserID) {
        g_previousBuddyTransferSteps.push($('div.buddytransfer_steps > div:visible'));
        $('div.buddytransfer_steps > div').hide();
        var url = '<%= this.Url.RouteUrl("BuddyTransfer", new { @action = "Prepare" }).SafeJavascriptStringEncode() %>?encryptedUserID=' + encodeURIComponent(encryptedUserID);
        $('#prepare_step').show().html('<img border="0" src="/images/icon/loading.gif" />').load(url);
    }

    function showBuddyTransferConfirmation(sid) {
        $("#CircleProgress").removeClass("Step2").addClass("Step3");
        $(".MiddleCol").eq(1).addClass("ActiveCol");
        g_previousBuddyTransferSteps.push($('div.buddytransfer_steps > div:visible'));
        $('div.buddytransfer_steps > div').hide();
        var url = '<%= this.Url.RouteUrl("BuddyTransfer", new { @action = "Confirmation" }).SafeJavascriptStringEncode() %>?sid=' + encodeURIComponent(sid);
        $('#confirm_step').show().html('<img border="0" src="/images/icon/loading.gif" />').load(url);
    }

    
 
 
        //GamingAccountSelector
        var currentData = {};
        function GamingAccountSelector(domSelector, defaultSelection) {

            var selector = $('.AccountInput', domSelector) ;

            var dispatcher = new CMS.utils.Dispatcher();

            function clearSelection() {
                selector.val('');

                currentData = {};
                $('.GamingSelectorHidden', domSelector).val('');
            }

            function selectItem(data) {
                currentData = data;

                var account = getAccountData(),
                    bonus = data.bonus || {};

                $('.GamingSelectorHidden', domSelector).val(account.ID).valid();

                dispatcher.trigger('change', account);
                dispatcher.trigger('bonus', bonus);
            }

            function getAccountData() {
                return currentData.account || {};
            }

            selector.change(function () {
                selectItem($(':selected', selector).data());
            });

            if (defaultSelection !== false) {
                $(document).ready(function () {
                    var option = $('option', selector).eq(1);
                    selector.val(option.val());
                    selectItem(option.data());
                });
            }

            return {
                evt: dispatcher,
                data: getAccountData,
                clear: clearSelection
            }
        }
 
    //AmountSelector

    var gamingAccount, lockedCurrency;
    function AmountSelector() {

        var currField = $('#fldCurrency'),
			currInput = $('#currency'),
			currSelect = $('#selectCurrency'),
			amtField = $('#fldAmount'),
			amtInput = $('#selectAmount');

        var currencyRates = currSelect.data('rates'),
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

        $('a.DepositButtons').click(function (evt) {
            evt.preventDefault();
            var link = $(this);
            var amount = Math.floor($('#selectAmount').val());
            var cash = parseFloat(link.text().trim().replace(' ', '')) + amount;
            cash = cash.toString();
            setAmount(cash);
        });

        amtInput.change(function () {
            setAmount($(this).val());
            if (parseFloat(amtInput.val(), 10) <= 0) {
                $("#fldAmount .FormHelp").text('<%= this.GetMetadata("/BuddyTransfer/_Prepare_ascx.CurrencyAmount_Empty").SafeJavascriptStringEncode() %>');
                return;
            }
            if (parseFloat(amtInput.val(), 10) > gamingAccount.Amount) {
                $("#fldAmount .FormHelp").text('<%= this.GetMetadata("/BuddyTransfer/_Prepare_ascx.CurrencyAmount_Insufficient").SafeJavascriptStringEncode() %>');
                return;
            }
            $("#fldAmount .FormHelp").text('');
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
            amount.val(value);
            $("#debitAmount").text(value);
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
            return '<%= this.GetMetadata("/Components/_AmountSelector_ascx.Amount_Empty").SafeJavascriptStringEncode() %>';

        if ((debitAmount < 0) || (min > 0 && debitAmount < min) || (max > 0 && debitAmount > max))
            return '<%= this.GetMetadata("/Components/_AmountSelector_ascx.Amount_OutsideRange").SafeJavascriptStringEncode() %>';

        if (account !== undefined && debitAmount > account)
            return '<%= this.GetMetadata("/Components/_AmountSelector_ascx.Amount_Insufficient").SafeJavascriptStringEncode() %>';

        if (amountValidator) {
            var result = amountValidator(debitAmount, creditAmount);
            if (result !== true)
                return result;
        }

        return true;
    }

    function InitPrepare() {
        $("#CircleProgress").removeClass("Step1").addClass("Step2");
        $(".MiddleCol").eq(0).addClass("ActiveCol"); 
        CMS.mobile360.Generic.input(); 
        var amountSelector = new AmountSelector(); 
        var accountSelector = new GamingAccountSelector('#debitGammingAccountIDSelector', true); 
        var creditGammingAccountSelector = new GamingAccountSelector('#creditGammingAccountIDSelector', true);
            accountSelector.evt.bind('change', function (data) { 
            amountSelector.update(data); 
        });
        amountSelector.update($("#debitGammingAccountIDSelector select option[value!='']:selected").data().account);
        $("#debitGammingAccountIDSelector select").change(function () {
            $("#debitGammingAccountID").val($("#debitGammingAccountIDSelector select").val()); 
        }); 
        $("#creditGammingAccountIDSelector select").bind('change', function (data) {
            $("#creditGammingAccountID").val($("#creditGammingAccountIDSelector select").val());
        }); 
        $('#btnBuddyTransferMoney').click(function (e) {
            e.preventDefault();
            if (parseFloat($("#selectAmount").val(), 10) <= 0) {
                $("#fldAmount .FormHelp").text('<%= this.GetMetadata("/BuddyTransfer/_Prepare_ascx.CurrencyAmount_Empty").SafeJavascriptStringEncode() %>');
                return;
            }
            if (parseFloat($("#selectAmount").val(), 10) > gamingAccount.Amount) {
                $("#fldAmount .FormHelp").text('<%= this.GetMetadata("/BuddyTransfer/_Prepare_ascx.CurrencyAmount_Insufficient").SafeJavascriptStringEncode() %>');
                return;
            }
            if (!$('#formBuddyTransfer').valid())
                return;
            //$(this).toggleLoadingSpin(true);
            var options = {
                dataType: "json",
                type: 'POST',
                success: function (json) {
                    //$('#btnBuddyTransferMoney').toggleLoadingSpin(false);
                    if (!json.success) {
                        showBuddyTransferError(json.error);
                        return;
                    }
                    $(document).trigger('BUDDY_TRANSFER_TRANSACTION_PREPARED', json.sid);
                    showBuddyTransferConfirmation(json.sid);
                },
                error: function (xhr, textStatus, errorThrown) {
                    //$('#btnBuddyTransferMoney').toggleLoadingSpin(false);
                    showBuddyTransferError(errorThrown);
                }
            };
            $('#formBuddyTransfer').ajaxForm(options);
            $('#formBuddyTransfer').submit();
        });
    }
</script> 
    </ui:MinifiedJavascriptControl>
</asp:Content>

