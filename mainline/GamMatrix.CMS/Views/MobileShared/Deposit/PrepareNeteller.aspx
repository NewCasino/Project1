<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrix.CMS.Models.MobileShared.Deposit.Prepare.PrepareNetellerViewModel>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>

<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div class="UserBox DepositBox CenterBox">
	<div class="BoxContent">
		<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 4, CurrentStep = 2 }); %>
		<form action="<%= this.Url.RouteUrl("Deposit", new { action = "PrepareTransaction", paymentMethodName = this.Model.PaymentMethod.UniqueName }).SafeHtmlEncode() %>" method="post" id="formPrepareNeteller">
            
			<% Html.RenderPartial("/Components/MultiFormState", Model.StateVars); %>

            <%-------------------------------------
                Neteller
              -------------------------------------%>
            <fieldset>
	            <legend class="Hidden">
		            <%= this.GetMetadata(".Neteller_Account").SafeHtmlEncode() %>
	            </legend>
				
	            <ul class="FormList">
                    <li class="FormItem">
                        <% if (!Model.HasPayCards()) {%>
                        <span class="quickregister-wraper"><%=this.GetMetadata(".QuickRegister_Label").HtmlEncodeSpecialCharactors() %></span>
                        <%} %>
                    </li>
		            <li class="FormItem">
			            <label class="FormLabel" for="depositIdentityNumber"><%= this.GetMetadata(".AccountID_Label").SafeHtmlEncode() %></label>
                         <%: Html.TextBox("identityNumber", Model.HasPayCards() ? Model.ExistingPayCard.DisplayNumber : string.Empty, new Dictionary<string, object>()  
                            { 
                                { "class", "FormInput" },
                                { "id", "depositIdentityNumber" },
                                { "dir", "ltr" },
								{ "type", "text" },
                                { "maxlength", "100" },
                                { "autocomplete", "off" },
                                { "required", "required" },
								{ "placeholder", this.GetMetadata(".AccountID_Label") },
                                { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".AccountID_Empty")).Custom("__validateNetellerAccountID") }
                            }.SetReadOnly(Model.HasPayCards())) %>

			            <span class="FormStatus">Status</span>
			            <span class="FormHelp"></span>
		            </li>
		            <li class="FormItem">
			            <label class="FormLabel" for="depositSecurityKey"><%= this.GetMetadata(".SecurityKey_Label").SafeHtmlEncode()%></label>
                        <%: Html.TextBox("securityKey", "", new Dictionary<string, object>()  
                            { 
                                { "class", "FormInput" },
                                { "id", "depositSecurityKey" },
                                { "maxlength", "6" },
                                { "autocomplete", "off" },
                                { "dir", "ltr" },
                                { "required", "required" },
								{ "placeholder", this.GetMetadata(".SecurityKey_Label") },
                                { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".SecurityKey_Empty")).Custom("__validateNelellerSecurityKey") }
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

<ui:MinifiedJavascriptControl runat="server" Enabled="true" AppendToPageEnd="true">
<script type="text/javascript">
    function __validateNetellerAccountID() {
        var value = this;
        var account_ret = /^(.{12,12})$/.test(value);
        var email_ret = /^((([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+(\.([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+)*)|((\x22)((((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(([\x01-\x08\x0b\x0c\x0e-\x1f\x7f]|\x21|[\x23-\x5b]|[\x5d-\x7e]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(\\([\x01-\x09\x0b\x0c\x0d-\x7f]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]))))*(((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(\x22)))@((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.?$/i.test(value);
        if (!account_ret && !email_ret) {
            return '<%= this.GetMetadata(".AccountID_Invalid").SafeJavascriptStringEncode() %>';
        }
        return true;
    }

    function __validateNelellerSecurityKey() {
        var value = this;
        var ret = /^(.{6,6})$/.exec(value);
        if (ret == null || ret.length == 0)
            return '<%= this.GetMetadata(".SecurityKey_Invalid").SafeJavascriptStringEncode() %>';
        return true;
    }
    $(CMS.mobile360.Generic.input);
</script>
</ui:MinifiedJavascriptControl>

</asp:Content>

