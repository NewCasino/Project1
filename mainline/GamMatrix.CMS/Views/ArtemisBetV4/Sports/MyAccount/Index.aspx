<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>





<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
<style type="text/css">

#ifmSportsbook{ margin-top:1.5em;}
</style>
</asp:Content>





<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT")) %>

<% Html.RenderPartial( "../Iframe", this.ViewData.Merge( new { ConfigrationItem = "OddsMatrix_AccountPage",PercentageWidth = "100"})); %>

</asp:Content>



