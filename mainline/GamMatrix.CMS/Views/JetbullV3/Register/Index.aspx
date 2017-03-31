<%@ Page Language="C#" Inherits="CM.Web.ViewPageEx" PageTemplate="/DefaultMaster.master" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>

<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>
<%@ Import Namespace="BLToolkit.Data" %>
<%@ Import Namespace="BLToolkit.DataAccess" %>

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
        Html.RenderPartial("InputView");    
%>

</ui:Panel>

</div>


</asp:Content>

