<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>

<%: Html.ErrorMessage(this.ViewData["ErrorMessage"] as string, false, new { @id = "msgGeorgianCardATMError" })%>

<center>
    <%: Html.Button(this.GetMetadata(".Button_Back"), new { @type = "button", @id = "btnReturnCodeList" })%>
</center>
<script type="text/javascript">
    $(function () {
        $('#btnReturnCodeList').click(function () {
            $(this).toggleLoadingSpin(true);
            var url = '<%= this.Url.RouteUrl( "Withdraw", new { @action = "GeorgianCardATMCodeList" }).SafeJavascriptStringEncode() %>';
            $('#msgGeorgianCardATMError').parent().load(url, function () { $('#btnReturnCodeList').toggleLoadingSpin(false); });
        });
    });
</script>