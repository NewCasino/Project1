<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<div class="LoginDialogContainer">
    <div class="LoginDialog">
<%--        <div class="logo"><%=this.GetMetadata("/_DefaultMaster_master.Logo").HtmlEncodeSpecialCharactors() %></div>
--%>        <%: Html.Partial("/Head/LoginPane", this.ViewData.Merge(new { RefreshTarget = "top" }))%>

        <%: Html.Partial("/Head/ForgotPassword", this.ViewData.Merge())%>

        <%: Html.Partial("/Head/SignUp", this.ViewData.Merge())%>

    </div>
</div>

</asp:Content>

