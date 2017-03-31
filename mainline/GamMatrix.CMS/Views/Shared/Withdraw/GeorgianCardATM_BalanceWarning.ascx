<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<Finance.Range>" %>
<%@ Import Namespace="Finance" %>

<script runat="server" type="text/C#">
    private string GetWarningMessage()
    {
        return this.GetMetadataEx(".WarningMessage"
            , MoneyHelper.FormatWithCurrencySymbol( this.Model.Currency, this.Model.MinAmount)
            );
    }
</script>

<%: Html.H1(string.Empty)%>
<ui:Panel runat="server" ID="pnATMWarningDlg">
<%: Html.WarningMessage(GetWarningMessage())%>
<center>
    <%: Html.Button(this.GetMetadata(".Button_Transfer"), new { @type = "button", @id = "btnOpenTransferDlgForATM" })%>
    <%: Html.Button(this.GetMetadata(".Button_Continue"), new { @type = "button", @id = "btnContinueGenerateCode" })%>
    
</center>
</ui:Panel>


<script type="text/javascript">
    $(function () {
        $('#btnOpenTransferDlgForATM').click(function (e) {
            e.preventDefault();
            var url = '<%= this.Url.RouteUrl("Transfer", new { @action = "Dialog" }).SafeJavascriptStringEncode() %>';
            $('#pnATMWarningDlg').parent().html('<img border="0" src="/images/icon/loading.gif" />').load(url);
        });

        $('#btnContinueGenerateCode').click(function () {
            e.preventDefault();
            var url = '<%= this.Url.RouteUrl( "Withdraw", new { @action = "GenerateGeorgianCardATMCode", @ignoreBalance = true }).SafeJavascriptStringEncode() %>';
            $('#pnATMWarningDlg').parent().html('<img border="0" src="/images/icon/loading.gif" />').load(url);
        });

    });
</script>