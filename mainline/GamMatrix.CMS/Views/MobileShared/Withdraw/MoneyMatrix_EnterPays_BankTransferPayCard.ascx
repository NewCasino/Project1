<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="GamMatrix.CMS.Models.Common.Components" %>

<% Html.RenderPartial(
        "/Components/MoneyMatrix_PaymentSolutionPayCard",
        new MoneyMatrixPaymentSolutionPrepareViewModel(
            TransactionType.Withdraw,
            "EnterPays.BankTransfer", 
            inputFields: new List<MmInputField>
            {
                new MmInputField("Iban", this.GetMetadata(".Iban_Label"), MmInputFieldType.TextBoxIban) { IsRequired = true },
                new MmInputField("BankSwiftCode", this.GetMetadata(".BankSwiftCode_Label"), MmInputFieldType.TextBoxSwiftCode) { IsRequired = true },
                new MmInputField("BankSortCode", this.GetMetadata(".BankSortCode_Label"), MmInputFieldType.TextBoxSortCode)
            },
            allowInfiniteCardEntries: true)); %>