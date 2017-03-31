<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<div id="reality-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT")) %>
<ui:Panel runat="server" ID="pnRealityCheck">


<%
    if (Profile.IsAuthenticated)
        Html.RenderPartial("InputView", this.ViewData);
    else
        Html.RenderPartial("Anonymous", this.ViewData);
%>

</ui:Panel>

</div>


<ui:MinifiedJavascriptControl runat="server">
<script type="text/javascript">
    $('body').addClass('ProfilePage');
</script>
</ui:MinifiedJavascriptControl>

</asp:Content>

