<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Deposit.PrepareTurkeyBankWireViewModel>" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="CM.Web.UI" %>

<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 4, CurrentStep = 2 }); %>
<form method="post" id="formPrepareSMSTransaction" action="<%= Url.RouteUrl("Deposit", new 
{ 
	action = "ConfirmTurkeyBankWireTransaction", 
	paymentMethodName = Model.PaymentDetails.UniqueName 
})%>">
    
	<fieldset>
		<legend class="Hidden">
			<%= this.GetMetadata(".TurkeyBankWire_Legend").SafeHtmlEncode() %>
		</legend>
		<% Html.RenderPartial("/Components/MultiFormState", Model.StateVars); %>
		<ul class="FormList">
			<%------------------------------------------
				FullName
			-------------------------------------------%>
			<li class="FormItem" id="fldFullName">
				<label class="FormLabel" for="fullname"><%= this.GetMetadata(".FullName_Label").SafeHtmlEncode()%></label>
				<%: Html.TextBox("fullname", "", new Dictionary<string, object>()  
				{ 
					{ "class", "FormInput" },
					{ "maxlength", "50" },
					{ "placeholder", this.GetMetadata(".FullName_Label") },
					{ "required", "required" },
					{ "data-validator", ClientValidators.Create().Required(this.GetMetadata(".FullName_Empty")) }
				}) %>
				<span class="FormStatus">Status</span>
				<span class="FormHelp"></span>
			</li>
			<%------------------------------------------
				Citizen ID
			-------------------------------------------%>
			<li class="FormItem" id="fldCitizenID">
				<label class="FormLabel" for="citizenID"><%= this.GetMetadata(".CitizenID_Label").SafeHtmlEncode()%></label>
				<%: Html.TextBox("citizenID", "", new Dictionary<string, object>()  
				{ 
					{ "class", "FormInput" },
					{ "maxlength", "50" },
					{ "placeholder", this.GetMetadata(".CitizenID_Label") },
					{ "required", "required" },
					{ "data-validator", ClientValidators.Create().Required(this.GetMetadata(".CitizenID_Empty")) }
				}) %>
				<span class="FormStatus">Status</span>
				<span class="FormHelp"></span>
			</li>
			<%------------------------------------------
				Bank
			-------------------------------------------%>
			<li class="FormItem" id="fldCountry" runat="server">
				<label class="FormLabel" for="paymentMethod"><%= this.GetMetadata(".Bank_Label").SafeHtmlEncode()%></label>
				<select name="paymentMethod" class="FormInput AccountInput" autocomplete="off">
				<% 
					foreach (string bankID in Model.GetBankList())
					{  
				%>
				<option value="<%= bankID %>"><%= this.GetMetadata(string.Format(".Bank_{0}", bankID)).DefaultIfNullOrEmpty(bankID)%></option>
				<% 
					}
				%>
				</select>
				<span class="FormStatus">Status</span>
				<span class="FormHelp"></span>
			</li>
			<%------------------------------------------
				Transaction ID
			-------------------------------------------%>
			<li class="FormItem" id="fldTransactionID">
				<label class="FormLabel" for="transactionID"><%= this.GetMetadata(".TransactionID_Label").SafeHtmlEncode()%></label>
				<%: Html.TextBox("transactionID", "", new Dictionary<string, object>()  
				{ 
					{ "class", "FormInput" },
					{ "maxlength", "50" },
					{ "placeholder", this.GetMetadata(".TransactionID_Label") },
				}) %>
				<span class="FormStatus">Status</span>
				<span class="FormHelp"></span>
			</li>
		</ul>
	</fieldset>
	<% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel()); %>
</form>