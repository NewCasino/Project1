<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<%: Html.SuccessMessage(this.GetMetadata(".Success_Message"),true)%>

<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="true" AppendToPageEnd="true">
    <script language="javascript" type="text/javascript">
        $(document).ready(function () {
            setTimeout(function () { window.location.href="/deposit";}, 3000);
        });
    </script>
</ui:MinifiedJavascriptControl>