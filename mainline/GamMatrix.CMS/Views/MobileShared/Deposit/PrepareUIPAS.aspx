<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrix.CMS.Models.MobileShared.Deposit.Prepare.PrepareUiPasViewModel>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>

<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div class="UserBox DepositBox CenterBox">
	<div class="BoxContent">
		<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 4, CurrentStep = 2 }); %>
		<form action="<%= this.Url.RouteUrl("Deposit", new { action = "PrepareTransaction", paymentMethodName = this.Model.PaymentMethod.UniqueName }).SafeHtmlEncode() %>" method="post" id="formPrepareUiPas">
            
			<% Html.RenderPartial("/Components/MultiFormState", Model.StateVars); %>

            <%-------------------------------------
                UiPas
              -------------------------------------%>
            <fieldset>
	            <legend class="Hidden">
		            <%= this.GetMetadata(".UiPas_Account").SafeHtmlEncode() %>
	            </legend>
				
	            <ul class="FormList">
		            <li class="FormItem">
			            <label class="FormLabel" for="depositIdentityNumber"><%= this.GetMetadata(".AccountID_Label").SafeHtmlEncode() %></label>
                         <%: Html.TextBox("identityNumber", Model.HasPayCards() ? Model.ExistingPayCard.DisplayNumber : string.Empty, new Dictionary<string, object>()  
                            { 
                                { "class", "FormInput" },
                                { "id", "depositIdentityNumber" },
                                { "dir", "ltr" },
								{ "type", "text" },
                                { "maxlength", "16" },
                                { "autocomplete", "off" },
                                { "required", "required" },
								{ "placeholder", this.GetMetadata(".AccountID_Label") },
                                { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".AccountID_Empty")).Custom("__validateUiPasAccountID") }
                            }.SetReadOnly(Model.HasPayCards())) %>

			            <span class="FormStatus">Status</span>
			            <span class="FormHelp"></span>
		            </li>
		            <li class="FormItem">
			            <label class="FormLabel" for="depositPassword"><%= this.GetMetadata(".Password_Label").SafeHtmlEncode()%></label>
                        <%: Html.TextBox("securityKey", "", new Dictionary<string, object>()  
                            { 
                                { "class", "FormInput" },
                                { "id", "depositPassword" },
                                { "maxlength", "16" },
                                { "autocomplete", "off" },
                                { "dir", "ltr" },
                                { "required", "required" },
								{ "placeholder", this.GetMetadata(".Password_Label") },
                                { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".Password_Empty")).Custom("__validateUiPasPassword") }
                            }) %>
			            <span class="FormStatus">Status</span>
			            <span class="FormHelp"></span>
		            </li>
	            </ul>
            </fieldset>

            <input type="hidden" name="payCardID" value="<%= Model.HasPayCards() ? Model.ExistingPayCard.ID.ToString() : string.Empty %>" />

            <% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel()); %>
		</form>
	</div>
</div>

<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="true" AppendToPageEnd="true">
<script type="text/javascript">
    function __validateUiPasAccountID() {
        var value = this;
        var ret = /^(.{7,16})$/.exec(value);
        if (ret == null || ret.length == 0)
            return '<%= this.GetMetadata(".AccountID_Invalid").SafeJavascriptStringEncode() %>';
        return true;
    }

    function __validateUiPasPassword() {
        var value = this;
        var ret = /^(.{8,16})$/.exec(value);
        if (ret == null || ret.length == 0)
            return '<%= this.GetMetadata(".Password_Invalid").SafeJavascriptStringEncode() %>';
        return true;
    }

    $(CMS.mobile360.Generic.input);
</script>
</ui:MinifiedJavascriptControl>

</asp:Content>

