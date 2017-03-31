<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="GamMatrix.CMS.Models.Common.Components" %>

<% Html.RenderPartial(
         "/Components/MoneyMatrix_PaymentSolutionPayCard",
         new MoneyMatrixPaymentSolutionPrepareViewModel(
             TransactionType.Deposit,
             "GPaysSafe.PayKasa")
         {
             SupportedAmounts = new [] { "10", "15" , "20", "25", "30", "50", "60", "70", "80", "100", "150", "200", "250", "500", "1000" },
             SupportedCurrency = "EUR"
         }); %>