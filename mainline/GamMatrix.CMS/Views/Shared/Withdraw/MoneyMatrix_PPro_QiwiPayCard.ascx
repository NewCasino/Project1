<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="GamMatrix.CMS.Models.Common.Components" %>
<%@ Import Namespace="GamMatrixAPI" %>

<% Html.RenderPartial(
        "/Components/MoneyMatrix_PaymentSolutionPayCard",
        new MoneyMatrixPaymentSolutionPrepareViewModel(
            TransactionType.Withdraw,
            "PPro.Qiwi", 
            inputFields: new List<MmInputField>
            {
                new MmInputField("PProQiwiMobilePhone", this.GetMetadata(".PProQiwiMobilePhone_Label"), MmInputFieldType.TextBox) { IsRequired = true } 
            })); %>