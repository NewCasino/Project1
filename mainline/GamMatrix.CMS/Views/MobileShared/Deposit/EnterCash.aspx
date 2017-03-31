<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<Finance.PaymentMethod>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>

<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Deposit" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="CM.State" %>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>

<script runat="server">
    public string LockCurrency;
    public bool IsAmountVisible = true;
    protected int TotalSteps;
    protected string ActionUrl;

    protected override void OnInit(EventArgs e)
    {
        if (this.Model.UniqueName == "EnterCash_WyWallet")
        {
            TotalSteps = 4;
            ActionUrl = Url.RouteUrl("Deposit", new { action = "Prepare", paymentMethodName = Model.UniqueName });
        }
        else
        {
            TotalSteps = 3;
            ActionUrl = Url.RouteUrl("Deposit", new { action = "PrepareTransaction", paymentMethodName = Model.UniqueName });
        }

        base.OnInit(e);
    }
</script>

<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>

<asp:content contentplaceholderid="cphMain" runat="Server"> 
	<div class="UserBox CenterBox">
		<div class="BoxContent">
			<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = TotalSteps, CurrentStep = 1 }); %>
			<%--<form action="<%= this.Url.RouteUrl("Deposit", new { action = "Prepare", paymentMethodName = Model.UniqueName }).SafeHtmlEncode() %>" method="post" id="formDepositAmount">--%>
            <form action="<%= ActionUrl.SafeHtmlEncode() %>" method="post" id="formDepositAmount">
                
				<% Html.RenderPartial("/Components/GamingAccountSelector", new GamingAccountSelectorViewModel()
                    {
                        ComponentId = "creditAccountID",
                        SelectorLabel = this.GetMetadata(".GammingAccount_Label")
                    }); %>
				
                <% Html.RenderPartial("EnterCashBankSelector", new EnterCashBankSelectorViewModel()
                    {
                        PaymentDetails = this.Model
                    }); %>

				<%
 
                    Html.RenderPartial("/Components/AmountSelector", new AmountSelectorViewModel
                            {
                                PaymentDetails = Model,
                                TransferType = TransType.Deposit,
                                IsDebitSource = false
                            });
             
                    %>

                

				<% Html.RenderPartial("/Components/BonusSelector", new BonusSelectorViewModel()); %>
                <% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel() { BackButtonEnabled = true }); %>
			</form>
			<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="true" AppendToPageEnd="true">
				<script type="text/javascript">
				    $(function () {
				        var IsAmountVisible = <% = IsAmountVisible? "true" : "false"%>;
				        var accountSelector = new GamingAccountSelector('#creditAccountIDSelector', true),
							bonusSelector = new BonusSelector();				        
				        var	amountSelector;
				        IsAmountVisible ?  amountSelector = new AmountSelector()  : $("#fldAmount").remove();
				        var enterCashBankSelector = new EnterCashBankSelector();

				        accountSelector.evt.bind('bonus', function (data) {
				            bonusSelector.update(data);
				        });

				        accountSelector.evt.bind('change', function (data) {
				            amountSelector.update(data);
				        });

				        enterCashBankSelector.evt.bind('change', function (data) {
				            if (data.Currency != null)
				                amountSelector.lock(data.Currency);
				        });

						<% if (LockCurrency != null && IsAmountVisible)
                            { 
						%>
				        amountSelector.lock('<%= LockCurrency.SafeJavascriptStringEncode()%>');
				        <% 
                            }
						%>

				        <% if (Model.UniqueName == "EnterCash_OnlineBank")
                           { %>
				        enterCashBankSelector.toggle(true);
                        <% } %>
				    });

				    $(CMS.mobile360.Generic.input);
				</script>
			</ui:MinifiedJavascriptControl>
		</div>
	</div>
</asp:content>
