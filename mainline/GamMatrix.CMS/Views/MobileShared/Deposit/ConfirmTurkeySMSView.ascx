<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Deposit.ConfirmTurkeySMSViewModel>" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 4, CurrentStep = 3 }); %>

<form method="post" id="formConfirmSMSTransaction" action="<%= Model.PostbackUrl %>">
    
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
					<span class="DetailName"><%= this.GetMetadata(".ReceiverBirthDate_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= Model.GetBirthDate()%></span>
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