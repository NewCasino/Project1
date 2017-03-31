<%@ Page Language="C#" PageTemplate="/Sports/SportsMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<script>
		if('https:' != document.location.protocol){
			window.location.href="https://www.jetbull.com/sports/asian";
		}  
</script>
<% Html.RenderPartial( "../Iframe", this.ViewData.Merge( new { ConfigrationItem = "OddsMatrix_AsianSports"})); %>
</asp:Content>
