<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GamMatrix.CMS.Models.Common.Components" %>

<% Html.RenderPartial("/Components/MoneyMatrix_CreditCardPayCard",
    new MoneyMatrixCreditCardPrepareViewModel(TransactionType.Withdraw, new List<string> { "VI", "VD", "VE" })); %>
