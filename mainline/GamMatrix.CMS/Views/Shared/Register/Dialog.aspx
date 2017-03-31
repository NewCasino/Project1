<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div class="quickregister-dialog-wrapper">
    <div class="quickregister-dialog">
    <%
    if (Profile.IsAuthenticated){%>
        <%: Html.WarningMessage(this.GetMetadata(".Message_LoggedIn"), true) %>
    <%}else {
        Html.RenderPartial("InputView");    
    %>
    </div>
</div>
</asp:Content>

