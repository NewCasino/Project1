<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

   
<div id="login-dlg-wrapper">
    <div id="login-dlg">

        <%: Html.Partial("/Head/LoginPane", this.ViewData.Merge()) %>

        <%: Html.Partial("/Head/ForgotPassword", this.ViewData.Merge())%>

        <%: Html.Partial("/Head/SignUp", this.ViewData.Merge())%>

    </div>
</div>

</asp:Content>

