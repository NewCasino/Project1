<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<% if (Profile.IsAuthenticated)
   { %>
        <% Html.RenderPartial("Dialog", this.ViewData.Merge()); %>
<% }
   else
   { %>
        <% Html.RenderPartial("Anonymous", this.ViewData.Merge()); %>
<% } %>
</asp:Content>

