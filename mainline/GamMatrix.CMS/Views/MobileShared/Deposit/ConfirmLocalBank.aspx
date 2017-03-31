<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrix.CMS.Models.MobileShared.Deposit.ConfirmLocalBankViewModel>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>

<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>

<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>


<asp:content contentplaceholderid="cphMain" runat="Server">

    <div class="Box CenterBox">
<div class="BoxContent">

    <% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 4, CurrentStep = 3 }); %>

    <form action="<%= this.Url.RouteUrl("Deposit"
        , new { @action = "ProcessLocalBankTransaction"
        , @paymentMethodName = "LocalBank" }).SafeHtmlEncode() %>" method="post" id="formPrepareMoneybookers">
        
        <% Html.RenderPartial("/Components/MultiFormState", Model.StateVars); %>

    <ul>
        <li class="FormItem">
            <% Html.RenderPartial("/Components/GamingAccountSelector", new GamingAccountSelectorViewModel()
                {
                    ComponentId = "creditAccountID",
                    SelectorLabel = this.GetMetadata(".GammingAccount_Label")
                }); %>
        </li>
        <li class="FormItem">
            <span class="FormInput">Amount: <%= this.Model.StateVars["amount"] %> KRW</span><br />
        </li>
        <li class="FormItem">
            <span class="FormInput">Bank: <%= this.Model.StateVars["bankName"] %> - <%= this.Model.StateVars["bankAccountNo"] %></span>
        </li>
    </ul>

    <%: Html.Hidden("currency", "KRW" , new { @class = "Hidden", autocomplete = "off" })%>
    <% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel()); %>

    </form>

    </div>
        </div>
</asp:content>

