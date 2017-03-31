<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrix.CMS.Models.MobileShared.Deposit.Prepare.PrepareIPSTokenViewModel>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="CM.Web.UI" %>

<script language="C#" type="text/C#" runat="server">   
    private string GetSelector()
    {
        StringBuilder script = new StringBuilder();
        foreach (string currency in this.Model.PaymentMethod.SupportedCurrencies.GetAll())
        {
            if (this.Model.PaymentMethod.SupportedCurrencies.Exists(currency))
                script.AppendFormat("*[value=\"{0}\"],", currency);
        }
        if (script.Length > 0)
            script.Remove(script.Length - 1, 1);
        return script.ToString();
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div class="UserBox DepositBox CenterBox">
	<div class="BoxContent">
		<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 4, CurrentStep = 2 }); %>
		<form action="<%= this.Url.RouteUrl("Deposit", new { @action = "ProcessIPSTokenTransaction", @paymentMethodName = this.Model.PaymentMethod.UniqueName }).SafeHtmlEncode() %>" method="post" id="formPrepareIPSToken">
            
            <% Html.RenderPartial("/Components/MultiFormState", Model.StateVars); %>

            <fieldset>
	            <legend class="Hidden">
		            <%= this.GetMetadata(".Neteller_Account").SafeHtmlEncode() %>
	            </legend>
				
	            <ul class="FormList">
		            <li class="FormItem">
                        <label class="FormLabel" for="txtIPSToken"><%= this.GetMetadata(".Token_Label").SafeHtmlEncode() %></label>
                        <%: Html.TextBox("token", string.Empty, new Dictionary<string, object>()
                        {
                            { "class", "FormInput" },
                            { "id", "txtIPSToken" },
                            { "maxlength", 50 },
                            { "dir", "ltr" },
                            {"validator", ClientValidators.Create().Required(this.GetMetadata(".Token_Empty"))}
                        })%>                        
                    </li>
                    <li class="FormItem">
                        <label class="FormLabel" for="txtCheckDigit"><%= this.GetMetadata(".CheckDigit_Label").SafeHtmlEncode() %></label>                        
                        <%: Html.TextBox("checkDigit", string.Empty, new Dictionary<string, object>()
                        {
                            { "class", "FormInput" },
                            { "id", "txtCheckDigit" },
                            {"maxlength", 10},
                            {"dir", "ltr"},
                            {"validator", ClientValidators.Create().Required(this.GetMetadata(".CheckDigit_Empty"))}
                        })%>
                    </li>
                </ul>
            </fieldset>

            <input type="hidden" name="payCardID" value="<%= Model.PayCard.ID.ToString() %>" />

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

