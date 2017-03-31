<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrix.CMS.Models.MobileShared.Deposit.Prepare.PrepareMoneyMatrixOfflineNordeaViewModel>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>

<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="GamMatrix.CMS.Models.Common.Components" %>

<script language="C#" runat="server">

    const string PAYMENT_SOLUTION_NAME = "Offline.Nordea";

    private MoneyMatrixPaymentSolutionPrepareViewModel BuildModel()
    {
        var model = new MoneyMatrixPaymentSolutionPrepareViewModel(TransactionType.Deposit, PAYMENT_SOLUTION_NAME);

        PaymentSolutionDetails details;

        var country = CountryManager.GetAllCountries().FirstOrDefault(c => c.InternalID == Profile.UserCountryID);
        if (country != null && !string.IsNullOrEmpty(country.ISO_3166_Alpha2Code))
        {
            details = GamMatrixClient.GetPaymentSolutionDetails(PAYMENT_SOLUTION_NAME, country : country.ISO_3166_Alpha2Code);
        }
        else
        {
            details = GamMatrixClient.GetPaymentSolutionDetails(PAYMENT_SOLUTION_NAME);
        }

        if (details != null &&
            details.Metadata != null &&
            details.Metadata.Fields != null && details.Metadata.Fields.Count > 0)
        {
            model.InputFields = new List<MmInputField>();

            foreach (var field in details.Metadata.Fields.Where(f => f.ForDeposit && f.RequiresUserInput))
            {
                model.InputFields.Add(MmInputField.FromMmMetadataField(field));
            }
        }

        return model;
    }
</script>

<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>

<asp:content contentplaceholderid="cphMain" runat="Server">
<div class="UserBox DepositBox CenterBox">
	<div class="BoxContent">
		<% Html.RenderPartial("/Components/UserFlowStatus", new UserFlowStatusViewModel { FlowSteps = 4, CurrentStep = 2 }); %>
		<form action="<%= this.Url.RouteUrl("Deposit", new { action = "PrepareTransaction", paymentMethodName = this.Model.PaymentMethod.UniqueName }).SafeHtmlEncode() %>" method="post" id="formPrepareOfflineNordea">
            
    		<% Html.RenderPartial("/Components/MultiFormState", Model.StateVars); %>
            
            <% Html.RenderPartial("/Components/MoneyMatrix_PaymentSolutionPayCard", this.BuildModel()); %>

            <% Html.RenderPartial("/Components/UserFlowNavigation", new UserFlowNavigationViewModel()); %>
		</form>
	</div>
</div>

<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="true" AppendToPageEnd="true">
    <script type="text/javascript">
        $(CMS.mobile360.Generic.input);
    </script>
</ui:MinifiedJavascriptControl>

</asp:content>
