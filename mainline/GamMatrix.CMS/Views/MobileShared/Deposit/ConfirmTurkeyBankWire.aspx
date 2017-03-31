<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrix.CMS.Models.MobileShared.Components.TransactionInfo>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="System.Globalization" %>


<script runat="server">
	public string GetGamingAccountName(string accountId)
	{
		long tempId = 0L;
		AccountData account = null;

		if (long.TryParse(accountId, NumberStyles.Integer, CultureInfo.InvariantCulture, out tempId))
			account = GamMatrixClient.GetUserGammingAccounts(Profile.UserID).FirstOrDefault(a => a.ID == tempId);

		if (account == null)
			throw new ArgumentOutOfRangeException("creditAccountID");

		return this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name", account.Record.VendorID));
	}

	public string GetFormattedAmount()
	{
		decimal amount = decimal.Parse(Model.StateVars["amount"], CultureInfo.InvariantCulture);
		return MoneyHelper.FormatWithCurrency(Model.StateVars["currency"], amount);
	}
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
	<div class="UserBox DepositBox CenterBox">
		<div class="BoxContent">
		<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 4, CurrentStep = 3 }); %>
		<form method="post" id="formConfirmSMSTransaction" action="<%= Url.RouteUrl("Deposit", new 
		{ 
			action = "ProcessTurkeyBankWireTransaction", 
			paymentMethodName = Model.PaymentMethod.UniqueName 
		})%>">
            
			<% Html.RenderPartial("/Components/MultiFormState", Model.StateVars); %>
			<div class="MenuList L DetailContainer">
				<ol class="DetailPairs ProfileList">
					<li>
						<div class="ProfileDetail">
							<span class="DetailName"><%= this.GetMetadata(".CreditAccount_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= GetGamingAccountName(Model.StateVars["creditAccountID"])%></span>
						</div>
					</li>
					<li>
						<div class="ProfileDetail">
							<span class="DetailName"><%= this.GetMetadata(".CreditAmount_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= GetFormattedAmount()%></span>
						</div>
					</li>
					<li>
						<div class="ProfileDetail">
							<span class="DetailName"><%= this.GetMetadata(".FullName_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= Model.StateVars["fullname"]%></span>
						</div>
					</li>
					<li>
						<div class="ProfileDetail">
							<span class="DetailName"><%= this.GetMetadata(".CitizenID_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= Model.StateVars["citizenID"]%></span>
						</div>
					</li>
					<li>
						<div class="ProfileDetail">
							<span class="DetailName"><%= this.GetMetadata(".Bank_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= 
																															  this.GetMetadata(string.Format(".Bank_{0}", Model.StateVars["paymentMethod"]))
																															  .DefaultIfNullOrEmpty(Model.StateVars["paymentMethod"])%></span>
						</div>
					</li>
					<% if (!string.IsNullOrWhiteSpace(Model.StateVars["transactionID"])) 
						{ %>
					<li>
						<div class="ProfileDetail">
							<span class="DetailName"><%= this.GetMetadata(".TransactionID_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= Model.StateVars["transactionID"]%></span>
						</div>
					</li>
					<% } %>
				</ol>
			</div>
			<% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel()); %>
		</form>
		</div>
	</div>
	<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="true" AppendToPageEnd="true">
	<script type="text/javascript">
		$(CMS.mobile360.Generic.input);
	</script>
	</ui:MinifiedJavascriptControl>
</asp:Content>

