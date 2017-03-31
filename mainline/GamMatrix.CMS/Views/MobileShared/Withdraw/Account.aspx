<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<Finance.PaymentMethod>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script runat="server">
    private VendorID[] ThreeStepsVendors = new VendorID[]
    {
        VendorID.Trustly,
        VendorID.IPG,
        VendorID.Nets,
    };

    private bool IsThreeSteps()
    {
        if (ThreeStepsVendors.Contains(this.Model.VendorID))
            return true;

        if (this.Model.UniqueName.Equals("MoneyMatrix_Trustly", StringComparison.InvariantCultureIgnoreCase) ||
            this.Model.UniqueName.Equals("MoneyMatrix_PayKasa", StringComparison.InvariantCultureIgnoreCase) ||
            this.Model.UniqueName.Equals("MoneyMatrix_Offline_Nordea", StringComparison.InvariantCultureIgnoreCase))
        {
            return true;
        }

        return false;
    }

    public string LockCurrency;
    protected int TotalSteps;
    protected string ActionUrl;
    protected override void OnInit(EventArgs e)
    {
        string paymentId = Model.UniqueName;

        if (paymentId == "Envoy_FundSend")
            LockCurrency = "EUR";

        if (paymentId.Contains("ArtemisSMS") || paymentId.Contains("TurkeySMS"))
            LockCurrency = "TRY";

        if (paymentId == "TurkeyBankWire")
            LockCurrency = "TRY";

        if (paymentId == "TLNakit")
            LockCurrency = "TRY";

        if (paymentId == "MoneyMatrix_IBanq")
            LockCurrency = "USD";

        if (paymentId == "MoneyMatrix_PayKasa")
            LockCurrency = "EUR";

        if (IsThreeSteps())
        {
            TotalSteps = 3;
            ActionUrl = Url.RouteUrl("Withdraw", new { action = "MobilePrepareTransaction", paymentMethodName = Model.UniqueName });
        }
        else
        {
            TotalSteps = 4;
            ActionUrl = Url.RouteUrl("Withdraw", new { action = "Prepare", paymentMethodName = Model.UniqueName });
        }

        base.OnInit(e);
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>

<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
	<div class="UserBox CenterBox WithdrawBox WithdrawDetails">
		<div class="BoxContent WithdrawContent" id="WithdrawContent">
            <% if (!Settings.MobileV2.IsV2DepositProcessEnabled) { %>
			    <% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = this.TotalSteps, CurrentStep = 0 }); %>
            <% } %>
			<form action="<%= this.ActionUrl.SafeHtmlEncode() %>" method="post" id="formWithdrawAmount" class="GeneralForm WithdrawForm WithdrawAmount">
                
				<% Html.RenderPartial("/Components/GamingAccountSelector", new GamingAccountSelectorViewModel()
					{
						ComponentId = "gammingAccountID",
						SelectorLabel = this.GetMetadata(".GammingAccount_Label")
					}); %>

				<% Html.RenderPartial("/Components/AmountSelector", new AmountSelectorViewModel
					{
						TransferType = TransType.Withdraw,
						PaymentDetails = Model
					}); %>

                <% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel() { BackButtonEnabled = !IsThreeSteps() }); %>
			</form>
		</div>
	</div>
	<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="true" AppendToPageEnd="true">
	<script type="text/javascript">
		$(function () {
			CMS.mobile360.Generic.input();
			var amountSelector = new AmountSelector();
			var accountSelector = new GamingAccountSelector('#gammingAccountIDSelector', true);
		
			accountSelector.evt.bind('change', function (data) {
				amountSelector.update(data);
			});

			<% if(LockCurrency != null)
				{ 
			%>
			amountSelector.lock('<%= LockCurrency.SafeJavascriptStringEncode()%>');
			<% 
				} 
			%>
			<% if (Model.UniqueName == "TLNakit") 
				{%>
			AmountSelector.customAmountValidator = function(debitAmount, creditAmount){
				if (creditAmount % 1 != 0)
					return '<%= this.GetMetadata(".TLNakit_InvalidAmount").SafeJavascriptStringEncode() %>';
				return true;
			}
			<% } %>
		});
	</script>
	</ui:MinifiedJavascriptControl>
</asp:Content>
