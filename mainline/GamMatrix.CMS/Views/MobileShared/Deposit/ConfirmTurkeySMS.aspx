<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrix.CMS.Models.MobileShared.Deposit.TurkeySMSViewModel>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="System.Globalization" %>

<script runat="server">
	public string PostbackUrl { get; protected set; }

	public string GetFormattedAmount()
	{
		decimal amount = decimal.Parse(Model.StateVars["amount"], CultureInfo.InvariantCulture);
		return MoneyHelper.FormatWithCurrency(Model.StateVars["currency"], amount);
	}

	public string GetBirthDate()
	{
		return string.Format("{0}/{1}/{2}",
			Model.StateVars["rbday"],
			Model.StateVars["rbmonth"],
			Model.StateVars["rbyear"]);
	}

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
	
	protected override void OnInit(EventArgs e)
	{
		var paymentId = Model.PaymentMethod.UniqueName;
		if (paymentId.Contains("ArtemisSMS"))
			PostbackUrl = Url.RouteUrl("Deposit", new { action = "ProcessArtemisSMSTransaction", paymentMethodName = paymentId });
		else
			PostbackUrl = Url.RouteUrl("Deposit", new { action = "ProcessTurkeySMSTransaction", paymentMethodName = paymentId });
		
		base.OnInit(e);
	}
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
	<div class="UserBox DepositBox CenterBox">
		<div class="BoxContent">
		<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 4, CurrentStep = 3 }); %>
		<form method="post" id="formConfirmSMSTransaction" action="<%= PostbackUrl %>">
            
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
					<% if (Model.ShowSenderPhoneNumber)
					   { %>
					<li>
						<div class="ProfileDetail">
							<span class="DetailName"><%= this.GetMetadata(".SenderPhoneNumber_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= Model.StateVars["senderPhoneNumber"]%></span>
						</div>
					</li>
					<% } %>
					<% if (Model.ShowReceiverPhoneNumber)
						{ %>
					<li>
						<div class="ProfileDetail">
							<span class="DetailName"><%= this.GetMetadata(".ReceiverPhoneNumber_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= Model.StateVars["receiverPhoneNumber"]%></span>
						</div>
					</li>
					<% } %>
					<% if (Model.ShowReceiverBirthDate)
						{ %>
					<li>
						<div class="ProfileDetail">
							<span class="DetailName"><%= this.GetMetadata(".ReceiverBirthDate_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= GetBirthDate()%></span>
						</div>
					</li>
					<% } %>
					<% if (Model.ShowPassword)
						{ %>
					<li>
						<div class="ProfileDetail">
							<span class="DetailName"><%= this.GetMetadata(".Password_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= Model.StateVars["password"]%></span>
						</div>
					</li>
					<% } %>
					<% if (Model.ShowReferenceNumber)
						{ %>
					<li>
						<div class="ProfileDetail">
							<span class="DetailName"><%= this.GetMetadata(".ReferenceNumber_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= Model.StateVars["referenceNumber"]%></span>
						</div>
					</li>
					<% } %>
					<% if (Model.ShowSenderTCNumber)
						{ %>
					<li>
						<div class="ProfileDetail">
							<span class="DetailName"><%= this.GetMetadata(".SenderTCNumber_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= Model.StateVars["senderTCNumber"]%></span>
						</div>
					</li>
					<% } %>
					<% if (Model.ShowReceiverTCNumber)
						{ %>
					<li>
						<div class="ProfileDetail">
							<span class="DetailName"><%= this.GetMetadata(".ReceiverTCNumber_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= Model.StateVars["receiverTCNumber"]%></span>
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

