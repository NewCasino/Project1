<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="GamMatrix.CMS.Models.Common.Components" %>

<% Html.RenderPartial(
          "/Components/MoneyMatrix_PaymentSolutionPayCard",
          new MoneyMatrixPaymentSolutionPrepareViewModel(
              TransactionType.Deposit,
              "PPro.Przelewy24",
              inputFields: new List<MmInputField>
                 {
                new MmInputField("PProPrzelewy24Email", this.GetMetadata(".PProPrzelewy24Email_Label"), MmInputFieldType.TextBoxEmail) { DefaultValue = this.Profile.Email, IsRequired = true }
                 })); %>
