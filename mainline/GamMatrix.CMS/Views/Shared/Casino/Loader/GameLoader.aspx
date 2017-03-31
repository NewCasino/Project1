<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<Casino.Game>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
<title><%= this.Model.Title.SafeHtmlEncode() %></title>
<meta name="description" content="<%= this.Model.Description.SafeHtmlEncode() %>" />
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<% Html.RenderPartial("Loader", this.Model, this.ViewData.Merge()); %>
</asp:Content>

