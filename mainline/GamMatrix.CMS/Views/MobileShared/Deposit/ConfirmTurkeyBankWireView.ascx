<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Deposit.ConfirmTurkeyBaknWireViewModel>" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 4, CurrentStep = 3 }); %>

<form method="post" id="formConfirmSMSTransaction" action="<%= Url.RouteUrl("Deposit", new 
{ 
	action = "ProcessTurkeyBankWireTransaction", 
	paymentMethodName = Model.PaymentDetails.UniqueName 
})%>">
    
	<% Html.RenderPartial("/Components/MultiFormState", Model.StateVars); %>
	<div class="MenuList L DetailContainer">
		<ol class="DetailPairs ProfileList">
			<li>
				<div class="ProfileDetail">
					<span class="DetailName"><%= this.GetMetadata(".CreditAccount_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= Model.GetGamingAccountName(Model.StateVars["creditAccountID"])%></span>
				</div>
			</li>
			<li>
				<div class="ProfileDetail">
					<span class="DetailName"><%= this.GetMetadata(".CreditAmount_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= Model.GetFormattedAmount()%></span>
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