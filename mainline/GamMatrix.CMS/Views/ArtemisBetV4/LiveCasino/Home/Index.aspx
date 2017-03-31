<%@ Page Language="C#" PageTemplate="/LiveCasino/LiveCasinoMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrixAPI" %>
<asp:Content ContentPlaceHolderID="cphHead" Runat="Server"></asp:Content>
<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div class="pageTitle"><%=this.GetMetadata(".Page_Title")%></div>
<% Html.RenderPartial("XProGamingGames", this.ViewData.Merge()); %>
<div class="venders">
	<%=this.GetMetadata("/Home/_Index_aspx.Guide_Sports_Html").HtmlEncodeSpecialCharactors()%>
	<%=this.GetMetadata("/Home/_Index_aspx.Guide_LiveCasino_Html").HtmlEncodeSpecialCharactors()%>
	<%=this.GetMetadata("/Home/_Index_aspx.Guide_Casino_Html").HtmlEncodeSpecialCharactors()%> 
	<%=this.GetMetadata("/Home/_Index_aspx.Guide_Poker_Html").HtmlEncodeSpecialCharactors()%>
</div>
</asp:Content>

