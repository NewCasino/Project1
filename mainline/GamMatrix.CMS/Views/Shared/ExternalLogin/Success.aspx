<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
    <script type="text/javascript">
        $(function () {
            window.opener.location.reload();
            window.close();
        });
    </script>
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
    <%:Html.SuccessMessage(this.GetMetadata(".Success")) %>
</asp:Content>

