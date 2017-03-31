<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrix.CMS.Models.MobileShared.Components.TransactionInfo>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script runat="server">
    public string GetBankList()
    {
        Type type = typeof(TurkeyBankWirePaymentMethod);
        Array values = Enum.GetValues(type);
        string[] table1paths = Metadata.GetChildrenPaths("/Metadata/TurkeyBankWire_Banks");
        string bankText;
        string bankValue = string.Empty;
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < table1paths.Length; i++)
        {
            bankValue = table1paths[i].Substring(table1paths[i].LastIndexOf("/") + 1);
            if (values.ConvertToCommaSplitedString().Contains(bankValue)) {
                bankText = this.GetMetadata(string.Format("{0}.Text", table1paths[i])).DefaultIfNullOrEmpty(bankValue);
                sb.Append("<option value=\"" + bankValue + "\">" + bankText + "</option>");
            }
        }
        return sb.ToString();
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>

<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
	<div class="UserBox DepositBox CenterBox">
		<div class="BoxContent">
			<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 4, CurrentStep = 2 }); %>
			<form method="post" id="formPrepareSMSTransaction" action="<%= Url.RouteUrl("Deposit", new 
			{ 
				action = "ConfirmTurkeyBankWireTransaction", 
				paymentMethodName = Model.PaymentMethod.UniqueName 
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
							<%=GetBankList()%>
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
		</div>
	</div>
	<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="true" AppendToPageEnd="true">
	<script type="text/javascript">
		$(CMS.mobile360.Generic.input);
	</script>
	</ui:MinifiedJavascriptControl>
</asp:Content>

