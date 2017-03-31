<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrix.CMS.Models.MobileShared.Deposit.Prepare.PrepareMoneybookersViewModel>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrixAPI" %>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div class="UserBox DepositBox CenterBox">
	<div class="BoxContent">
		<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 4, CurrentStep = 2 }); %>
		<form action="<%= this.Url.RouteUrl("Deposit", new { @action = "PrepareTransaction", @paymentMethodName = this.Model.PaymentMethod.UniqueName }).SafeHtmlEncode() %>" method="post" id="formPrepareMoneybookers">
            
            <% Html.RenderPartial("/Components/MultiFormState", Model.StateVars); %>

            <%-------------------------------------
                Moneybookers
              -------------------------------------%>
            <fieldset>
	            <legend class="Hidden">
		            <%= this.GetMetadata(".Moneybookers_Account").SafeHtmlEncode() %>
	            </legend>
                <% if (!Model.PayCard.IsDummy)
				   { %>

	            <ul class="FormList">
                    
		            <li class="FormItem">
			            <label class="FormLabel" for="depositIdentityNumber"><%= this.GetMetadata(".Email_Label").SafeHtmlEncode()%></label>
                         <%: Html.TextBox("identityNumber", Model.PayCard.DisplayNumber, new Dictionary<string, object>()  
                            { 
                                { "class", "FormInput" },
                                { "id", "depositIdentityNumber" },
                                { "dir", "ltr" },
								{ "type", "text" },
                                { "readonly", "readonly" },
								{ "placeholder", this.GetMetadata(".Email_Label") },
                            })%>

			            <span class="FormStatus">Status</span>
			            <span class="FormHelp"></span>
		            </li>
	            </ul>
                <% 
				   }
				   else
				   {
						Html.RenderPartial("/Components/StatusNotification", new StatusNotificationViewModel(StatusType.Info, this.GetMetadata(".Moneybookers_Info")));
				   } %>

                <input type="hidden" name="payCardID" value="<%= Model.PayCard.ID.ToString() %>" />
            </fieldset>
            <% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel()); %>
		</form>
	</div>
</div>


<ui:MinifiedJavascriptControl runat="server" Enabled="true" AppendToPageEnd="true">
<script type="text/javascript">
    $(CMS.mobile360.Generic.input);
</script>
</ui:MinifiedJavascriptControl>

</asp:Content>

