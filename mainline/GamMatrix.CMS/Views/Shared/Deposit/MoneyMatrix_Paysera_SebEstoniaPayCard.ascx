<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="GamMatrix.CMS.Models.Common.Components" %>

<% Html.RenderPartial(
         "/Components/MoneyMatrix_PaymentSolutionPayCard",
         new MoneyMatrixPaymentSolutionPrepareViewModel(TransactionType.Deposit, "PaySera.SebEstonia")
         {
             UseDummyPayCard = true
         }); %>