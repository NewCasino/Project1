<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<div id="selfexclusion-wrapper" class="content-wrapper">

<%
    if (Profile.IsAuthenticated)
        Html.RenderPartial("InputViewV2", this.ViewData);
    else
    { %>
<%: Html.H1(this.GetMetadata(".HEAD_TEXT")) %>
<ui:Panel runat="server" ID="pnSelfExclusion">
<%
        Html.RenderPartial("Anonymous", this.ViewData);
%>
</ui:Panel>
<%  } %>

</div>


</asp:Content>

