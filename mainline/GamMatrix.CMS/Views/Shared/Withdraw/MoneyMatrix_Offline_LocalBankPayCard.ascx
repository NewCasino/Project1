<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>
<%@ Import Namespace="GamMatrix.CMS.Models.Common.Components" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>

<script language="C#" runat="server">

    const string PAYMENT_SOLUTION_NAME = "Offline.LocalBank";

    private MoneyMatrixPaymentSolutionPrepareViewModel BuildModel()
    {
        var model = new MoneyMatrixPaymentSolutionPrepareViewModel(TransactionType.Withdraw, PAYMENT_SOLUTION_NAME, allowInfiniteCardEntries: true);

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

            foreach (var field in details.Metadata.Fields.Where(f => f.ForWithdraw && f.RequiresUserInput))
            {
                var inputField = MmInputField.FromMmMetadataField(field);

                if (inputField.Label.IndexOf("first name", StringComparison.CurrentCultureIgnoreCase) > -1)
                {
                    inputField.DefaultValue = Profile.FirstName;
                }

                if (inputField.Label.IndexOf("last name", StringComparison.CurrentCultureIgnoreCase) > -1)
                {
                    inputField.DefaultValue = Profile.SurName;
                }

                if (inputField.Label.IndexOf("comment", StringComparison.CurrentCultureIgnoreCase) > -1)
                {
                    inputField.IsAlwaysUserInput = true;
                }

                model.InputFields.Add(inputField);
            }
        }

        return model;
    }
</script>

<% Html.RenderPartial(
        "/Components/MoneyMatrix_PaymentSolutionPayCard", this.BuildModel()); %>