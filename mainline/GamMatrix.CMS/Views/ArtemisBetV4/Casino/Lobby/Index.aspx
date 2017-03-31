<%@ Page Language="C#" PageTemplate="/Casino/CasinoMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
<link id="casino-stylesheet" href="//cdn.everymatrix.com/ArtemisBetV3/casino.css" rel="stylesheet" type="text/css" /> 
 </asp:Content>
<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">  
<%Response.Redirect("/casino/hall");%>
  <div id="framework" class="Container">
    <div class="Zone Container Intro">
      <div class="Main Column">
        <%: Html.CachedPartial("GameSliderWidget")  %>
        <% Html.RenderPartial("GameAreaPopupWidget", this.ViewData.Merge(new { })); %>
      </div>
      <div class="RightCol Column">
        <%: Html.CachedPartial("TopPromotionWidget", this.ViewData.Merge(new { @allPromotionsPageUrl = "" }))  %>
        <%  Html.RenderPartial("CashReWardsWidget", this.ViewData.Merge(new { @aboutUrl = "/Casino/FPPLearnMore" }));  %>
        <div id="recent-winners-widget-place-holder"> </div>
      </div>
    </div>
    <div class="Zone Container Games">
      <% Html.RenderPartial("GameBoxWidget"); %>
      <% Html.RenderAction("JackpotBoxWidget", new { @currency = "EUR", @allJackpotsPageUrl = "/Casino/jackpots" }); %>
    </div>
    <div class="Zone Container Additional">
      <div class="RightCol Column">
        <% Html.RenderAction("TopWinnersWidget", new { @maxWinners = "10", @allWinnersUrl="" }); %>
      </div>
      <div class="Main Column">
        <div class="Container">
          <%: Html.CachedPartial("PromotionListWidget", this.ViewData.Merge(new { @allPromotionsPageUrl = "/Promotions/Home" }))  %>
        </div>
      </div>
    </div>    
  </div>
<ui:MinifiedJavascriptControl runat="server" Enabled="true" AppendToPageEnd="true">
  <script type="text/javascript">
    $(function () {
      $("#gameSearch").insertAfter($("#gameFilter"));
      var url = '<%= this.Url.RouteUrl("CasinoLobby", new { @action = "RecentWinnersWidget", @maxWinners = 10}).SafeJavascriptStringEncode() %>';
      $('#recent-winners-widget-place-holder').load(url);
    });
  </script>
</ui:MinifiedJavascriptControl>
</asp:Content>
