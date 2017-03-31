<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GamMatrixAPI" %>

<form action="<%= this.Url.RouteUrl("Transfer", new { action = "PrepareTransaction"}).SafeHtmlEncode() %>" id="transferInput" method="post">
    
	<fieldset>
		<legend class="hidden">
			Transfer Money
		</legend>
		<% Html.RenderPartial("/Components/GamingAccountSelector", new GamingAccountSelectorViewModel() 
        {
			ComponentId = "debitGammingAccountID",
			EnableBonus = false,
			DisableJsCode = true,
			SelectorLabel = this.GetMetadata(".DebitGammingAccount_Label")
        }); %>

		<% Html.RenderPartial("/Components/GamingAccountSelector", new GamingAccountSelectorViewModel()
        {
			ComponentId = "creditGammingAccountID",
			SelectorLabel = this.GetMetadata(".CreditGammingAccount_Label")
        }); %>

		<% Html.RenderPartial("/Components/AmountSelector", new AmountSelectorViewModel()); %>
		<% Html.RenderPartial("/Components/BonusSelector", new BonusSelectorViewModel { TransferType = TransType.Transfer }); %>

		<div class="AccountButtonContainer">
			<ul class="DepLinks Container">
				<li class="DepItem">
					<button type="submit" class="Button RegLink DepLink BackLink" id="transferAll">
						<span class="ButtonText"><%= this.GetMetadata(".Button_TransferAll").SafeHtmlEncode()%></span>
					</button>
				</li>
				<li class="DepItem">
					<button type="submit" class="Button RegLink DepLink NextStepLink" id="transfer">
						<span class="ButtonText"><%= this.GetMetadata(".Button_Transfer").SafeHtmlEncode()%></span>
					</button>
				</li>
			</ul>
		</div>
	</fieldset>
</form>

<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="true" AppendToPageEnd="true">
<script type="text/javascript">
	function InputView() {
		var fromAccount = new GamingAccountSelector('#debitGammingAccountIDSelector'),
			toAccount = new GamingAccountSelector('#creditGammingAccountIDSelector', false),
			amountSelector = new AmountSelector(),
			bonusSelector = new BonusSelector();

		fromAccount.evt.bind('change', function (data) {
			if (data.ID == toAccount.data().ID) {
				toAccount.clear();
				bonusSelector.update({});
			}

			amountSelector.update(data);
		});

		toAccount.evt.bind('change', function (data) {
			if (data.ID == fromAccount.data().ID) {
				fromAccount.clear();
				amountSelector.update({});
			}
		});

		toAccount.evt.bind('bonus', function (data) {
			bonusSelector.update(data);
		});

		$('#transferAll').click(function () {
			amountSelector.all();
		});
	}

	$(function () {
		new InputView();
	});
</script>
</ui:MinifiedJavascriptControl>