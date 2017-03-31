<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="GamMatrix.CMS.Models.Common.Components" %>

<% Html.RenderPartial(
         "/Components/MoneyMatrix_PaymentSolutionPayCard",
         new MoneyMatrixPaymentSolutionPrepareViewModel(
             TransactionType.Withdraw,
             "Paysera.Wallet",
             inputFields:new List<MmInputField>
             {
                new MmInputField("PaymentParameterPayseraAccount", this.GetMetadata(".PaymentParameterPayseraAccount_Label")) { IsRequired = true, ValidationJavaScriptMethodName = "PayseraAccountValidator" },
                new MmInputField("PaymentParameterBeneficiaryName", this.GetMetadata(".PaymentParameterBeneficiaryName_Label")) { IsRequired = true }
             })); %>

<script type="text/javascript">
    function PayseraAccountValidator() {
        var value = this;

        var emailRet = true;
        var accountRet = true;

        if (value.indexOf("@") >= 0) {
            emailRet = /^([\w\.\-]+)@([\w\-]+)((\.(\w){2,3})+)$/.test(value);
        }

        if (value.match("^EVP")) {
            var digitsOnly = value.slice(3);
            accountRet = /^\d{13}$/.exec(digitsOnly);
        }

        if (emailRet && accountRet) {
            return '<%= this.GetMetadata(".PaymentParameterPayseraAccount_Invalid").SafeJavascriptStringEncode() %>';
        }
        
        return true;
    }
</script>