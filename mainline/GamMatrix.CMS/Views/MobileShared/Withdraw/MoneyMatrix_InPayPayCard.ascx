<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>
<%@ Import Namespace="System.Web.Mvc.Html" %>
<%@ Import Namespace="CM.State" %>
<%@ Import Namespace="GamMatrix.CMS.Models.Common.Components" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>

<script language="C#" runat="server">

    private List<MmInputField> GetInputFieldsFromMetadata()
    {
        var country = CountryManager.GetAllCountries().FirstOrDefault(c => c.InternalID == CustomProfile.Current.UserCountryID).ISO_3166_Alpha2Code;
        var paymentSolutionDetails = GamMatrixClient.GetPaymentSolutionDetails("InPay", country, TransType.Withdraw);

        var metadataFields = new List<PaymentSolutionMetadataField>();

        if (paymentSolutionDetails != null && paymentSolutionDetails.Metadata != null)
        {
            metadataFields = paymentSolutionDetails.Metadata.Fields;
        }

        var inputFields = new List<MmInputField>();

        if (metadataFields != null && metadataFields.Count != 0)
        {
            foreach (var field in metadataFields.Where(f => f.ForWithdraw))
            {
                inputFields.Add(MmInputField.FromMmMetadataField(field));
            }
        }

        return inputFields;
    }

</script>

<% Html.RenderPartial(
        "/Components/MoneyMatrix_PaymentSolutionPayCard",  new MoneyMatrixPaymentSolutionPrepareViewModel(
            TransactionType.Withdraw,
            "InPay",
            inputFields: GetInputFieldsFromMetadata(),
            allowInfiniteCardEntries: true
            )); %>