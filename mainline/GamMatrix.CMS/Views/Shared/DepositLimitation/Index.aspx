<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div id="depositlimit-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT")) %>
<ui:Panel runat="server" ID="pnDepositLimit">


<%
    if (Profile.IsAuthenticated)
        Html.RenderPartial("InputView", this.ViewData);
    else
        Html.RenderPartial("Anonymous", this.ViewData);
%>

</ui:Panel>

</div>
</asp:Content>

