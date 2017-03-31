<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div id="message-wrapper" class="content-wrapper">
<ui:Panel runat="server" ID="pnMessage">
        <%: Html.WarningMessage(this.GetMetadata(".Message").HtmlEncodeSpecialCharactors(), true)%>
</ui:Panel>
</div>

<script type="text/javascript">
    $(function () {
        setTimeout(function () {
            self.location = '<%= this.Url.RouteUrl("Profile", new { @action = "Index"}).SafeJavascriptStringEncode() %>';
        }, 5000);
    });
    $('body').addClass('AuthenticatedProfile');
</script>
</asp:Content>
