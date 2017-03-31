<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrix.CMS.Models.MobileShared.Deposit.Prepare.PrepareMoneybookers1TapViewModel>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="CM.Web.UI" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>

<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
	<div class="UserBox DepositBox CenterBox">
		<div class="BoxContent">
			<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 4, CurrentStep = 2 }); %>
			<form method="post" id="formTLNakitPayCard" action="<%= this.Url.RouteUrl("Deposit", new 
			{ 
				action = "PrepareTransaction", 
				paymentMethodName = Model.PaymentMethod.UniqueName
			}).SafeHtmlEncode() %>">
                
				<fieldset>
					<legend class="Hidden">
						<%= this.GetMetadata(".1Tap_Legend").SafeHtmlEncode() %>
					</legend>
					<% Html.RenderPartial("/Components/MultiFormState", Model.StateVars); %>

					<%= Html.Hidden("payCardID", Model.PayCard.ID.ToString())%>
					<ul class="FormList">
						<li class="FormItem" id="fldSkrill1TapMaxAmount">
							<label class="FormLabel" for="referenceNumber"><%= this.GetMetadata(".MaxAmount_Label").SafeHtmlEncode()%></label>
							<%: Html.TextBox("maxAmount", string.Empty, new Dictionary<string, object>()  
							{ 
								{ "id", "txtSkrill1TapMaxAmount" },
								{ "class", "FormInput" },
								{ "maxlength", "20" },
								{ "placeholder", this.GetMetadata(".MaxAmount_Label") },
								{ "autocomplete", "off" },
								{ "required", "required" },
								{ "data-validator", ClientValidators.Create()
									.Number(this.GetMetadata(".MaxAmount_Invalid"))
									.Required(this.GetMetadata(".MaxAmount_Empty")) }
							}) %>
							<span class="FormStatus">Status</span>
							<span class="FormHelp"></span>
						</li>
					</ul>
					<% if (!Model.IsFirstTransaction)
					{ %>
					<div class="AccountButtonContainer">
						<a id="maxAmountChangeBtn" class="Button AccountButton" href="#"> <strong class="ButtonText"><%= this.GetMetadata(".Button_ChangeMaxAmount").SafeHtmlEncode()%></strong> </a>
					</div>
					<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl2" runat="server" Enabled="true" AppendToPageEnd="true">
					<script type="text/javascript">
						(function () {
							$('#maxAmountChangeBtn').click(function () {
								toggleMax(true);
								$(this).parent().addClass('Hidden');
							});

							function toggleMax(state) {
								$('#fldSkrill1TapMaxAmount').toggleClass('Hidden', !state);
								$('#txtSkrill1TapMaxAmount').prop('disabled', !state);
							}

							toggleMax(false);
						})();
					</script>
					</ui:MinifiedJavascriptControl>
					<% } %>
				</fieldset>
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

