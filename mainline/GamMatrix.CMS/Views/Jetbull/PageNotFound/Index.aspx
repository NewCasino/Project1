<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<%--<ui:Panel runat="server" ID="pnLiteral">
--%><div class="error_panel">
    <div class="left_panel">
        <%=this.GetMetadata(".Left_Content").HtmlEncodeSpecialCharactors()%>
    </div>
    <div class="right_panel">
        <div class="ErrorTitle">
            <%=this.GetMetadata(".Title").SafeHtmlEncode() %>
        </div>
        <div class="error_content">
            <%=this.GetMetadata(".Content").HtmlEncodeSpecialCharactors()%>
        </div>
    </div>
</div>
<%--</ui:Panel>--%>

<script type="text/javascript">
function ClientService() {
    $('a.livechat').click();
    return false;
}
</script>
</asp:Content>

