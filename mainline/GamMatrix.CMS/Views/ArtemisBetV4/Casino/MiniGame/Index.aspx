<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>

<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

    <% Html.RenderPartial("/Casino/Lobby/MiniGameBoxWidget", new { @SelectTheFirstGameAsDefault = false}); %>

    <ui:MinifiedJavascriptControl runat="server">
        <script type="text/javascript">
            jQuery('body').addClass('iframe-MiniGame');
        </script>
    </ui:MinifiedJavascriptControl>

</asp:Content>