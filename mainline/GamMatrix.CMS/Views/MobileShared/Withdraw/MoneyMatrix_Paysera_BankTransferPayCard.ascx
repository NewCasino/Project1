<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="GamMatrix.CMS.Models.Common.Components" %>

<% Html.RenderPartial(
         "/Components/MoneyMatrix_PaymentSolutionPayCard",
         new MoneyMatrixPaymentSolutionPrepareViewModel(
             TransactionType.Withdraw,
             "Paysera.BankTransfer",
             inputFields:new List<MmInputField>
             {
                new MmInputField("PaymentParameterIban", this.GetMetadata(".PaymentParameterIban_Label"), MmInputFieldType.TextBoxIban) { IsRequired = true },
                new MmInputField("PaymentParameterBeneficiaryName", this.GetMetadata(".PaymentParameterBeneficiaryName_Label")) { IsRequired = true }
             },
             relatedMoneyMatrixPaymentSolutionNames: new[]
             {
                 "Paysera.LithuanianCreditUnion",
                 "Paysera.MedicinosBankas",
                 "Paysera.SiauliuBankas",
                 "Paysera.Dnb",
                 "Paysera.SwedbankLithuania",
                 "Paysera.SebLithuania",
                 "Paysera.NordeaLithuania",
                 "Paysera.CitadeleLithuania",
                 "Paysera.DanskeLithuania",
                 "Paysera.SwedbankLatvia",
                 "Paysera.SebLatvia",
                 "Paysera.NordeaLatvia",
                 "Paysera.CitadeleLatvia",
                 "Paysera.SwedbankEstonia",
                 "Paysera.SebEstonia",
                 "Paysera.DanskeEstonia",
                 "Paysera.NordeaEstonia",
                 "Paysera.Krediidipank",
                 "Paysera.LhvBank",
                 "Paysera.BzwbkBank",
                 "Paysera.PekaoBank",
                 "Paysera.PkoBank",
                 "Paysera.mBank",
                 "Paysera.AliorBank",
                 "Paysera.BankTransfer"
             })); %>