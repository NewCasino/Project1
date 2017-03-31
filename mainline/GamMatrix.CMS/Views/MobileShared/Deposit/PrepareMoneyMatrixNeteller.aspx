<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrix.CMS.Models.MobileShared.Deposit.Prepare.PrepareMoneyMatrixNetellerViewModel>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>

<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GamMatrix.CMS.Models.Common.Components" %>
<%@ Import Namespace="GamMatrixAPI" %>

<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>

<asp:content contentplaceholderid="cphMain" runat="Server">
    <div class="UserBox DepositBox CenterBox">
        <div class="BoxContent">
            <% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel {FlowSteps = 4, CurrentStep = 2}); %>
            <form action="<%= this.Url.RouteUrl("Deposit", new {action = "PrepareTransaction", paymentMethodName = this.Model.PaymentMethod.UniqueName}).SafeHtmlEncode() %>" method="post" id="formPrepare">

                <% Html.RenderPartial("/Components/MultiFormState", Model.StateVars); %>
                
                <% Html.RenderPartial(
                        "/Components/MoneyMatrix_PaymentSolutionPayCard",
                        new MoneyMatrixPaymentSolutionPrepareViewModel(
                            TransactionType.Deposit, 
                            "Neteller", 
                            VendorID.Neteller, 
                            new List<MmInputField>
                            {
                                new MmInputField("NetellerEmailAddressOrAccountId", this.GetMetadata(".NetellerEmailAddressOrAccountId_Label")) { IsRequired = true, ValidationJavaScriptMethodName = "NetellerEmailAddressOrAccountIdValidator", DefaultValue = this.Profile.Email },
                                new MmInputField("NetellerSecret", this.GetMetadata(".NetellerSecret_Label")) { IsAlwaysUserInput = true, IsRequired = true, ValidationJavaScriptMethodName = "NetellerSecretKeyValidator" } 
                            })); %>

                <% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel()); %>
            </form>
        </div>
    </div>
    <ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="true" AppendToPageEnd="true">
        <script type="text/javascript">
            function NetellerSecretKeyValidator() {
                var value = this;
                var ret = /^\d{6}$/.exec(value);
                if (ret == null || ret.length == 0)
                    return '<%= this.GetMetadata(".NetellerSecret_Invalid").SafeJavascriptStringEncode() %>';
                return true;
            }

            function NetellerEmailAddressOrAccountIdValidator() {
                var value = this;
                var account_ret = /^(.{12,12})$/.test(value);
                var email_ret = /^([\w\.\-]+)@([\w\-]+)((\.(\w){2,3})+)$/.test(value);
                if (!account_ret && !email_ret) {
                    return '<%= this.GetMetadata(".NetellerEmailAddressOrAccountId_Invalid").SafeJavascriptStringEncode() %>';
                }
                return true;
            }

            $(CMS.mobile360.Generic.input);
        </script>
    </ui:MinifiedJavascriptControl>   
</asp:content>