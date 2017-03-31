<%@ Page Language="C#" PageTemplate="/Casino/CasinoMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>

<script type="text/C#" runat="server">
    private string GetLoggedInHtml()
    {
        if (!Profile.IsAuthenticated)
            return string.Empty;
        
        return this.GetMetadata(".LoggedInHtml").HtmlEncodeSpecialCharactors();
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
    <%if(Settings.GRE_Enabled) { %>
    <link rel="stylesheet" type="text/css" href="//cdn.everymatrix.com/Generic/games-recommendation-widget.css" />
    <%} %>
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<div class="Framework" id="framework">

<div class="Zone Container Intro">
    <div class="Main Column">
        <% Html.RenderPartial("/Components/Slider", this.ViewData.Merge(new { @SliderPath = "/Casino/Hall/Slider" })); %> 
        <div id="casino-inline-game-container"></div>
    </div>

    <div class="RightCol Column">
        <h1 class="CasinoPageTitle"><%= this.GetMetadata(".Header").SafeHtmlEncode() %></h1>
        <% Html.RenderAction("IncentiveMessage"); %>

        <%= GetLoggedInHtml() %>

        <% Html.RenderPartial("../Lobby/CashRewardsWidget", this.ViewData.Merge(new { @AboutUrl = "/Casino/FPPLearnMore" })); %>

        <% Html.RenderPartial("../Lobby/RecentWinnersWidget", this.ViewData.Merge(new { })); %>
    </div>
</div>
    <%if(Settings.GRE_Enabled) { %>
         <% Html.RenderPartial("/Components/PopularGamesInCountry", this.ViewData); %>
        <%} %>


<% Html.RenderPartial("GameNavWidget/Main", this.ViewData.Merge( new { } )); %>


<% Html.RenderPartial("GameOpenerWidget/Main", this.ViewData.Merge(new { })); %>


<% Html.RenderAction("JackpotWidget", new { @currency = "EUR" }); %>

</div>


<ui:MinifiedJavascriptControl runat="server">
<script type="text/javascript">
    $(function () {
        $(document).on('INLINE_GAME_OPENED', function (evt, data) {
            $('div.Main > div.GeneralSlider').hide();
            window.scrollTo(0, 0);
        });
        $(document).bind('INLINE_GAME_CLOSED', function () {
            $('div.Main > div.GeneralSlider').show();
        });
        $(document).bind('GAME_TO_BE_OPENED', function () {
            $('div.Main > div.GeneralSlider').show();
        });
    }); 

</script>
</ui:MinifiedJavascriptControl>


</asp:Content>

