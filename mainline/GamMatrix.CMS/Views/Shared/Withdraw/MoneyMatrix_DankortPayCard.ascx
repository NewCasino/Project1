<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GamMatrix.CMS.Models.Common.Components" %>

<% Html.RenderPartial("/Components/MoneyMatrix_CreditCardPayCard",
        new MoneyMatrixCreditCardPrepareViewModel(TransactionType.Withdraw, acceptableCardBins: new List<string> { "5019", "4571" })); %>
