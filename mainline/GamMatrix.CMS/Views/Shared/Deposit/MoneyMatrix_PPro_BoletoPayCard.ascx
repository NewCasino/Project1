<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="GamMatrix.CMS.Models.Common.Components" %>

<% Html.RenderPartial(
           "/Components/MoneyMatrix_PaymentSolutionPayCard",
           new MoneyMatrixPaymentSolutionPrepareViewModel(
               TransactionType.Deposit,
               "PPro.Boleto",
              inputFields: new List<MmInputField>
                   {
                new MmInputField("PProBoletoNationalId", this.GetMetadata(".PProBoletoNationalId_Label"), MmInputFieldType.TextBox) { IsRequired = true },
                new MmInputField("PProBoletoEmail", this.GetMetadata(".PProBoletoEmail_Label"), MmInputFieldType.TextBoxEmail) { DefaultValue = this.Profile.Email, IsRequired = true },
                new MmInputField("PProBoletoBirthDate", this.GetMetadata(".PProBoletoBirthDate_Label"), MmInputFieldType.DropDownDate) { IsRequired = true }
              })); %>
