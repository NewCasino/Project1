<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="GamMatrix.CMS.Models.Common.Components" %>
<%@ Import Namespace="GamMatrixAPI" %>

<% Html.RenderPartial(
        "/Components/MoneyMatrix_PaymentSolutionPayCard",
        new MoneyMatrixPaymentSolutionPrepareViewModel(
            TransactionType.Withdraw,
            "Skrill", 
            VendorID.Moneybookers, 
            new List<MmInputField>
            {
                new MmInputField("SkrillEmailAddress", this.GetMetadata(".SkrillEmailAddress_Label"), MmInputFieldType.TextBoxEmail) { IsRequired = true } 
            })); %>