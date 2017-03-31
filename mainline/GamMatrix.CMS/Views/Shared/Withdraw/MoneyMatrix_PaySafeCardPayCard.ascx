<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="GamMatrix.CMS.Models.Common.Components" %>

<% Html.RenderPartial(
        "/Components/MoneyMatrix_PaymentSolutionPayCard",
        new MoneyMatrixPaymentSolutionPrepareViewModel(
            TransactionType.Withdraw,
            "PaySafeCard", 
            inputFields: new List<MmInputField>
            {
                new MmInputField("PaySafeCardAccountId", this.GetMetadata(".CustomerId_Label"), MmInputFieldType.TextBoxEmail) { IsRequired = true, DefaultValue = this.Profile.Email } 
            })); %>