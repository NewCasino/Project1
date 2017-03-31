<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="GamMatrix.CMS.Models.Common.Components" %>

<% Html.RenderPartial(
        "/Components/MoneyMatrix_PaymentSolutionPayCard",
        new MoneyMatrixPaymentSolutionPrepareViewModel(
            TransactionType.Withdraw,
            "UPayCard", 
            inputFields: new List<MmInputField>
            {
                new MmInputField("UPayCardReceiverAccount", this.GetMetadata(".UPayCardReceiverAccount_Label"), MmInputFieldType.TextBox) {IsRequired = true, ValidationJavaScriptMethodName = "UPayCardReceiverAccountValidator"}            
            })); %>

<script type="text/javascript">
    function UPayCardReceiverAccountValidator() {
        var value = this;
        var account_ret = /^(\d{1,11})$/.test(value);
        if (!account_ret) {
            return '<%= this.GetMetadata(".UPayCardReceiverAccount_Invalid").SafeJavascriptStringEncode() %>';
        }
        return true;
    }
</script>