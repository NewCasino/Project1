﻿<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="GamMatrix.CMS.Models.Common.Components" %>
<%@ Import Namespace="GamMatrixAPI" %>

<% Html.RenderPartial(
        "/Components/MoneyMatrix_PaymentSolutionPayCard",
        new MoneyMatrixPaymentSolutionPrepareViewModel(
            TransactionType.Withdraw,
            "EcoPayz", 
            VendorID.EcoCard, 
            new List<MmInputField>
            {
                new MmInputField("EcoPayzCustomerAccountId", this.GetMetadata(".EcoPayzCustomerAccountId_Label")) { IsRequired = true }
            })); %>