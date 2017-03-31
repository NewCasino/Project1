<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<script type="text/c#" runat="server">
    private string GetCode()
    {
        return this.ViewData["NewCode"] as string;
    }
</script>

<%: Html.H1(string.Empty)%>
<ui:Panel runat="server" ID="pnATMWarningDlg">

    <span class="new-atm-code">
        <%= GetCode().SafeHtmlEncode()%>
    </span>

    <%: Html.WarningMessage( this.GetMetadata(".WarningMessage") ) %>

    <center>
        <%: Html.Button(this.GetMetadata(".Button_OK"), new { @type = "button", @id = "btnReturnGenerateCode" })%>
    </center>
</ui:Panel>

<script type="text/javascript">
    $(function () {
        $('#btnReturnGenerateCode').click(function (e) {
            loadGeorgianCardATMCodeList();
            $.modal.close();
        });
    });
</script>


