<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div id="register-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT")) %>
<ui:Panel runat="server" ID="pnRegister">

<%
    if (Profile.IsAuthenticated)
        Response.Redirect( this.Url.RouteUrl( "Deposit", new { @action="Index" }), false );// logged in
    else
        Html.RenderPartial("Step2InputView", this.ViewData.Merge());    
%>

</ui:Panel>

</div>
</asp:Content>

