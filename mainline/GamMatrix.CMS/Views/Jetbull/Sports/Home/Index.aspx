<%@ Page Language="C#" PageTemplate="/Sports/SportsMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
 

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<h1 class="PageTitle SportsPageTitle"><%=this.GetMetadata(".PageTitle").SafeHtmlEncode() %></h1>
<% Html.RenderPartial( "../Iframe", this.ViewData.Merge( new { ConfigrationItem = "OddsMatrix_HomePage"})); %>

</asp:Content>

