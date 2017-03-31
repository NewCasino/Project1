<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="true" AppendToPageEnd="true">
</ui:MinifiedJavascriptControl>
<script type="text/javascript">
    function initAmountsDropDown() {
        var strAmounts = '10,15,20,25,30,50,60,70,80,100,150,200,250,500,1000';

        var amountContainer = $('#fldAmount');
        $('.AmountContainer', amountContainer).remove();
        $('#DepositExtraButtons').remove();

        var lstAmounts = $('<select id="lstAmount" class="FormInput lst-amounts select" />');

        lstAmounts.change(function () {
            $('#txtAmount').val(lstAmounts.val());
        });

        var strAmountsArr = strAmounts.split(',');

        for (var i = 0; i < strAmountsArr.length; i++) {
            lstAmounts.append($('<option/>').attr('value', strAmountsArr[i]).text(parseFloat(strAmountsArr[i]).toFixed(2)));
        }

        $('.AmountBox', amountContainer).after(lstAmounts);
        $('.AmountBox', amountContainer).after("<input type='hidden' name='amount' id='txtAmount' />");

        $('#txtAmount').val(parseFloat(strAmountsArr[0]).toFixed(2));
    }

    $(document).ready(function () {
        initAmountsDropDown();
    });

</script>
