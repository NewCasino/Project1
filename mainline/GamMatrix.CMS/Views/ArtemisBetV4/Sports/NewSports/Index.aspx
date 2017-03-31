<%@ Page Language="C#" PageTemplate="/Sports/SportsMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
<style type="text/css">
#ifmSportsbook { min-height:600px;  }
</style>
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div style="width:1010px; margin:0 auto;">
<% Html.RenderPartial( "../Iframe", this.ViewData.Merge( new { ConfigrationItem = "OddsMatrix_NewHomePage", PercentageWidth = "100"})); %>
</div>
</asp:Content>

