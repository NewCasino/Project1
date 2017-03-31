<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Deposit.ConfirmTLNakitViewModel>" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 4, CurrentStep = 3 }); %>
<form id="formTLNakitPayCard" method="post" action="<%= this.Url.RouteUrl("Deposit", new { 
	action = "SaveTLNakit", 
}).SafeHtmlEncode() %>">
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
				<span class="DetailName"><%= this.GetMetadata(".CardNumber_Label").SafeHtmlEncode()%></span> <span class="DetailValue"><%= Model.StateVars["cardNumber"]%></span>
			</div>
		</li>
	</ol>
</div>
<% Html.RenderPartial("/Components/MultiFormState", Model.StateVars); %>
<% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel()); %>
</form>