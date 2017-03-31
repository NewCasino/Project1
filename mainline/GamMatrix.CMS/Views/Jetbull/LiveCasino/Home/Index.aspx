<%@ Page Language="C#" PageTemplate="/LiveCasino/LiveCasinoMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrixAPI" %>
<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>
<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
    <h1 class="PageTitle"><%=this.GetMetadata(".PageTitle").SafeHtmlEncode() %></h1>
  <div id="livecasino-wrapper" class="language-<%=MultilingualMgr.GetCurrentCulture()%>">
    <% Html.RenderPartial("MicrogamingLivedealers", this.ViewData.Merge()); %>
<%--    <div class="sidePanel">
      <div class="gameCategory">
        <%Html.RenderPartial("CategoryMenu",this.ViewData.Merge()); %>
      </div>
	  <% if (!Profile.IsAuthenticated)   {%><%=this.GetMetadata(".Banner") %><%}%>
    </div>
    <div class="mainPanel">
      <h2 id="Xpro_LobbyTitle" class="MATitle"></h2>
      <% Html.RenderPartial("XProGamingGames", this.ViewData.Merge()); %>
    </div>
    <div style="clear:both"></div>--%>
  </div>
</asp:Content>
