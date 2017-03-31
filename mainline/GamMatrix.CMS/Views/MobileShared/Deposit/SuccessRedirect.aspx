<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<script type="text/javascript">
    var success = false;
    try { if (self.opener !== null && self.opener.redirectToReceiptPage()) { success = true; } } catch (e) { }
    if( !success )
        try { if (self.parent !== null && self.parent.redirectToReceiptPage()) { success = true; } } catch (e) { }


    var url = '<%= (this.ViewData["RedirectUrl"] as string).SafeJavascriptStringEncode() %>';
    if (url.length > 0)
    {
        if (url.indexOf('Error') > -1)
        {
            url = '/Deposit/Error';
        }
        else 
        {
            self.location = url;
        }
    }
        
    if (success && self == top) {
        top.window.opener = top;
        top.window.open('', '_parent', '');
        top.window.close();
    }
</script>
</asp:Content>

