<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">



<div id="profile-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT")) %>
<ui:Panel runat="server" ID="pnProfile">


<%
    if (Profile.IsAuthenticated)
    {
        UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
        cmUser user = ua.GetByID(Profile.UserID);
        Html.RenderPartial("InputView", user);
    }
    else
        Html.RenderPartial("Anonymous", this.ViewData);
%>

</ui:Panel>

</div>


</asp:Content>

