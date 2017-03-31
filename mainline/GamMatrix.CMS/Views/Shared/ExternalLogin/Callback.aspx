<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
    <ui:MinifiedJavascriptControl runat="server" ID="scriptQuickSignup" AppendToPageEnd="false" Enabled="true">
    <script type="text/javascript">
        $(function () {
            var referrerID = '<%:this.ViewData["referrerID"]%>';
            var parent = window.opener || window.parent;
            if (parent != null) {
                if (typeof (parent.callback) == 'function') {
                    parent.callback(referrerID);
                }
            }
            else {
                self.location = "/Register?referrerID=" + referrerID;
            }
        });
    </script>
    </ui:MinifiedJavascriptControl>
</asp:Content>

