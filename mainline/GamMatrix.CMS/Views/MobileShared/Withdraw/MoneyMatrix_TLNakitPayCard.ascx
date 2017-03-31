<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="GamMatrix.CMS.Models.Common.Components" %>
<%@ Import Namespace="GamMatrixAPI" %>

<% Html.RenderPartial(
        "/Components/MoneyMatrix_PaymentSolutionPayCard",
        new MoneyMatrixPaymentSolutionPrepareViewModel(
            TransactionType.Withdraw,
            "TlNakit", 
            VendorID.TLNakit, 
            new List<MmInputField>
            {
                new MmInputField("TlNakitAccountId", this.GetMetadata(".TlNakitAccountId_Label")) { IsRequired = true } 
            })); %>