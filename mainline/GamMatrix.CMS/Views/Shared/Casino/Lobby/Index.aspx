<%@ Page Language="C#" PageTemplate="/Casino/CasinoMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
  <div id="framework" class="Container">
    <div class="Zone Container Intro">
      <div class="Main Column">
        <%: Html.CachedPartial("GameSliderWidget")  %>
        <% Html.RenderPartial("GameAreaExpandableWidget", this.ViewData.Merge(new { HiddenElementID = "casino_game_slider" })); %>
        
      </div>
      <div class="RightCol Column">
        <%: Html.CachedPartial("TopPromotionWidget", this.ViewData.Merge(new { @allPromotionsPageUrl = "" }))  %>
        <%  Html.RenderPartial("CashReWardsWidget", this.ViewData.Merge(new { @aboutUrl = "/Casino/FPPLearnMore" }));  %>
        <div id="recent-winners-widget-place-holder"> </div>
        <div class="similar-games-widget-place-holder"></div>
      </div>
    </div>
    <div class="Zone Container Games">
      <% Html.RenderPartial("GameBoxWidget"); %>
      <% Html.RenderAction("JackpotBoxWidget", new { @currency = "EUR", @allJackpotsPageUrl = "" }); %>
    </div>
    <div class="Zone Container Additional">
      <div class="RightCol Column">
        <% Html.RenderAction("TopWinnersWidget", new { @maxWinners = "10", @allWinnersUrl="" }); %>
      </div>
      <div class="Main Column">
        <div class="Container">
          <%: Html.CachedPartial("PromotionListWidget", this.ViewData.Merge(new { @allPromotionsPageUrl = "#" }))  %>
        </div>
      </div>
    </div>
    
  </div>
  <script type="text/javascript">
    $(function () {
        var url = '<%= this.Url.RouteUrl("CasinoLobby", new { @action = "RecentWinnersWidget", @maxWinners = 10}).SafeJavascriptStringEncode() %>';
        $('#recent-winners-widget-place-holder').load(url);
    });
</script> 

</asp:Content>

