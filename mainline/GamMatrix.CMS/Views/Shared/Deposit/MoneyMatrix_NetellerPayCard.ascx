<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.PaymentMethod>" %>

<%@ Import Namespace="GamMatrix.CMS.Models.Common.Components" %>
<%@ Import Namespace="GamMatrixAPI" %>

<% Html.RenderPartial(
        "/Components/MoneyMatrix_PaymentSolutionPayCard",
        new MoneyMatrixPaymentSolutionPrepareViewModel(
            TransactionType.Deposit, 
            "Neteller", 
            VendorID.Neteller, 
            new List<MmInputField>
            {
                new MmInputField("NetellerEmailAddressOrAccountId", this.GetMetadata(".NetellerEmailAddressOrAccountId_Label")) { IsRequired = true, ValidationJavaScriptMethodName = "NetellerEmailAddressOrAccountIdValidator", DefaultValue = this.Profile.Email },
                new MmInputField("NetellerSecret", this.GetMetadata(".NetellerSecret_Label")) { IsAlwaysUserInput = true, IsRequired = true, ValidationJavaScriptMethodName = "NetellerSecretKeyValidator" } 
            })); %>

<script type="text/javascript">
    function NetellerSecretKeyValidator() {
        var value = this;
        var ret = /^\d{6}$/.exec(value);
        if (ret == null || ret.length == 0)
            return '<%= this.GetMetadata(".NetellerSecret_Invalid").SafeJavascriptStringEncode() %>';
        return true;
    }

    function NetellerEmailAddressOrAccountIdValidator() {
        var value = this;
        var account_ret = /^(.{12,12})$/.test(value);
        var email_ret = /^([\w\.\-]+)@([\w\-]+)((\.(\w){2,3})+)$/.test(value);
        if (!account_ret && !email_ret) {
            return '<%= this.GetMetadata(".NetellerEmailAddressOrAccountId_Invalid").SafeJavascriptStringEncode() %>';
        }
        return true;
    }
</script>