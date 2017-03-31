<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="GamMatrix.CMS.Models.Common.Components" %>

<% Html.RenderPartial(
        "/Components/MoneyMatrix_PaymentSolutionPayCard",
        new MoneyMatrixPaymentSolutionPrepareViewModel(
            TransactionType.Withdraw,
            "PPro.Sepa", 
            inputFields: new List<MmInputField>
            {
                new MmInputField("Iban", this.GetMetadata(".Iban_Label"), MmInputFieldType.TextBoxIban) { IsRequired = true },
            })); %>