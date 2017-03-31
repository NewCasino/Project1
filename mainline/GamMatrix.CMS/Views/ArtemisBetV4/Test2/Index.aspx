<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<% Html.RenderPartial("/Head/TopContent", this.ViewData.Merge(new {@MetaPath = "/Metadata/TopContent/" })); %>
<% Html.RenderPartial("/Home/MainContent", this.ViewData.Merge(new { })); %>
</asp:Content>

