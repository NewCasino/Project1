<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="GamMatrix.CMS.Models.Common.Components" %>

<% Html.RenderPartial(
            "/Components/MoneyMatrix_PaymentSolutionPayCard",
            new MoneyMatrixPaymentSolutionPrepareViewModel(
                TransactionType.Deposit,
                "TlNakit",
                inputFields: new List<MmInputField>
                {
                new MmInputField("TlNakitCardNumber", this.GetMetadata(".TlNakitCardNumber_Label")) { IsRequired = true }
                })
            {
                UseDummyPayCard = true,
                SupportedCurrency = "TRY"
            }); %>