<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrix.CMS.Models.MobileShared.Deposit.Prepare.PrepareTLNakitViewModel>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>

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
						<%= this.GetMetadata(".TLNakit_Legend").SafeHtmlEncode() %>
					</legend>
					<% Html.RenderPartial("/Components/MultiFormState", Model.StateVars); %>
					<%= Html.Hidden("payCardID", Model.PayCard.ID.ToString()) %>
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
		</div>
	</div>
	<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="true" AppendToPageEnd="true">
	<script type="text/javascript">
		$(CMS.mobile360.Generic.input);
	</script>
	</ui:MinifiedJavascriptControl>
</asp:Content>


