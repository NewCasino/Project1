<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="GamMatrix.CMS.Models.Common.Components" %>

<% Html.RenderPartial(
        "/Components/MoneyMatrix_PaymentSolutionPayCard",
        new MoneyMatrixPaymentSolutionPrepareViewModel(
            TransactionType.Deposit, 
            "iBanq",  
            inputFields: new List<MmInputField>
            {
                new MmInputField("BanqUserId", this.GetMetadata(".BanqUserId_Label")) { IsRequired = true },
                new MmInputField("BanqUserPassword", this.GetMetadata(".BanqUserPassword_Label")) { IsAlwaysUserInput = true, IsRequired = true } 
            })); %>