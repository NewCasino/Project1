<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrix.CMS.Models.MobileShared.Deposit.Prepare.PrepareBoCashViewModel>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="CM.Web.UI" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

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
		<form action="<%= this.Url.RouteUrl("Deposit", new { @action = "PrepareTransaction", @paymentMethodName = this.Model.PaymentMethod.UniqueName }).SafeHtmlEncode() %>" method="post" id="formPrepareBocash">
            
			<% Html.RenderPartial("/Components/MultiFormState", Model.StateVars); %>

            <%-------------------------------------
                BoCash
              -------------------------------------%>
            <fieldset>
	            <legend class="Hidden">
		            <%= this.GetMetadata(".BoCash_Voucher").SafeHtmlEncode() %>
	            </legend>
				
	            <ul class="FormList">
					<% Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Warning, this.GetMetadata(".Warning_Message"))); %>

		            <li class="FormItem">
			            <label class="FormLabel" for="depositIdentityNumber"><%= this.GetMetadata(".VoucherCode_Label").SafeHtmlEncode()%></label>
                         <%: Html.TextBox("inputValue1", string.Empty, new Dictionary<string, object>()  
                            { 
                                { "class", "FormInput" },
                                { "id", "depositBocashNumber" },
                                { "dir", "ltr" },
								{ "type", "text" },
                                { "max-length", "50" },
                                { "autocomplete", "off" },
                                { "required", "required" },
								{ "placeholder", this.GetMetadata(".VoucherCode_Label") },
                                { "data-validator", ClientValidators.Create().Required(this.GetMetadata(".VoucherCode_Empty")) }
                            }) %>

			            <span class="FormStatus">Status</span>
			            <span class="FormHelp"></span>
		            </li>


                   
                    
	            </ul>
            </fieldset>

            <input type="hidden" name="payCardID" value="<%= Model.PayCard.ID.ToString() %>" />

            <% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel()); %>
		</form>
	</div>
</div>

<script type="text/javascript">
//<![CDATA[


$(function () {
    // <%-- Ukash is only available  --%>
    $('#depositCurrency > option').not('<%= GetSelector().SafeJavascriptStringEncode() %>').remove();

});

$(CMS.mobile360.Generic.input);
//]]>
</script>


</asp:Content>

