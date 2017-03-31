<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="GamMatrix.CMS.Models.Common.Components" %>

<% Html.RenderPartial("/Components/MoneyMatrix_WithdrawCreditCardPayCard",
         new MoneyMatrixCreditCardPrepareViewModel(TransactionType.Withdraw, new List<string> { "MC", "MD" })); %>