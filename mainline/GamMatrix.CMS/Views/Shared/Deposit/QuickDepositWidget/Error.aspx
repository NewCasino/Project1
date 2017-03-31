<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>


<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>

<asp:content contentplaceholderid="cphMain" runat="Server">

<script language="javascript" type="text/javascript">
    try {
        if (window.parent != window.self) {
            parent.window.$(parent.document).trigger('QUICK_DEPOSIT_FAILED');
        }
    } catch (ex) { }
</script>
</asp:content>

