<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Deposit.PrepareTLNakitViewModel>" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="CM.Web.UI" %>

<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 4, CurrentStep = 2 }); %>
<form method="post" id="formTLNakitPayCard" action="<%= this.Url.RouteUrl("Deposit", new 
{ 
	action = "PrepareTransaction", 
	paymentMethodName = Model.PaymentDetails.UniqueName
}).SafeHtmlEncode() %>">
    
	<fieldset>
		<legend class="Hidden">
			<%= this.GetMetadata(".TLNakit_Legend").SafeHtmlEncode() %>
		</legend>
		<% Html.RenderPartial("/Components/MultiFormState", Model.StateVars); %>
		<%= Html.Hidden("payCardID", Model.GetDummyPayCard().ID.ToString()) %>
		<ul class="FormList">
			<li class="FormItem" id="fldTLNakitNumber">
				<label class="FormLabel" for="referenceNumber"><%= this.GetMetadata(".CardNumber_Label").SafeHtmlEncode()%></label>
				<%: Html.TextBox("cardNumber", "", new Dictionary<string, object>()  
				{ 
					{ "class", "FormInput" },
					{ "maxlength", "50" },
					{ "placeholder", this.GetMetadata(".CardNumber_Label") },
					{ "required", "required" },
					{ "data-validator", ClientValidators.Create().Required(this.GetMetadata(".CardNumber_Empty")) }
				}) %>
				<span class="FormStatus">Status</span>
				<span class="FormHelp"></span>
			</li>
		</ul>
	</fieldset>
	<% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel()); %>
</form>