<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrix.CMS.Models.MobileShared.Deposit.Prepare.PrepareInPayViewModel>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>

<asp:Content ID="Content1" ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="cphMain" Runat="Server">
<div class="UserBox DepositBox CenterBox">
	<div class="BoxContent">
		<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 4, CurrentStep = 2 }); %>
		<form action="<%= this.Url.RouteUrl("Deposit", new { action = "ProcessInPayTransaction", paymentMethodName = this.Model.PaymentMethod.UniqueName }).SafeHtmlEncode() %>" method="post" id="formPrepareNeteller">
            
			<% Html.RenderPartial("/Components/MultiFormState", Model.StateVars); %>

            <%-------------------------------------
                InPay
              -------------------------------------%>
            <fieldset>
	            <legend class="Hidden">
		            <%= this.GetMetadata(".InPay_Account").SafeHtmlEncode() %>
	            </legend>
				<% if (Model.InPayBankList != null) 
                    { %>
	            <ul class="FormList">
		            <li class="FormItem">
			            <label class="FormLabel" for="depositIdentityNumber"><%= this.GetMetadata(".BankID_Label").SafeHtmlEncode() %></label>
                         <%: Html.DropDownList("inPayBankID", Model.InPayBankList, new Dictionary<string, object>()  
                            { 
                                { "class", "FormInput" },
                                { "id", "ddlInPayBankID" },
                                { "dir", "ltr" },
                                { "required", "required" },
                            }) %>

			            <span class="FormStatus">Status</span>
			            <span class="FormHelp"></span>
		            </li>
	            </ul>
                <% } %>
                <% else %>
                <% {
                       Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Info, this.GetMetadata(".CountryNotSupported")));
                   } %>
            </fieldset>

            <input type="hidden" name="payCardID" value="<%= Model.HasPayCards() ? Model.ExistingPayCard.ID.ToString() : string.Empty %>" />

            <% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel() { NextButtonEnabled = Model.InPayBankList != null }); %>
		</form>
	</div>
</div>

<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="true" AppendToPageEnd="true">
<script type="text/javascript">
    $(CMS.mobile360.Generic.input);
</script>
</ui:MinifiedJavascriptControl>

</asp:Content>

