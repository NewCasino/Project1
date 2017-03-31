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
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<div class="Framework" id="framework">

<div class="Zone Container Intro">
    <div class="Main Column">
        <% Html.RenderPartial("/Components/Slider", this.ViewData.Merge(new { @SliderPath = "/Casino/Hall/Slider" })); %> 
        <div id="casino-inline-game-container"></div>
    </div>

    <div class="RightCol Column">
    <h1 class="PageTitle"><%=this.GetMetadata(".PageTitle").SafeHtmlEncode() %></h1>
        <% Html.RenderAction("IncentiveMessage"); %>

        <%= GetLoggedInHtml() %>

        <% Html.RenderPartial("../Lobby/CashRewardsWidget", this.ViewData.Merge(new { @AboutUrl = "/Promotions/TermsConditions/casino/casinocashrewards" })); %>

    </div>
</div>


<div id="casino-inline-game-container"></div>
<% Html.RenderPartial("GameNavWidget/Main", this.ViewData.Merge(new { @DefaultCategory = "video-slots" })); %>




    <div class="Zone Container Intro">
        <div class="Main Column">
            <% Html.RenderAction("JackpotWidget", new { @currency = "EUR" }); %>
        </div>
        <div class="RightCol Column">
            <% Html.RenderPartial("../Lobby/RecentWinnersWidget", this.ViewData.Merge(new { })); %>
        </div>
    </div>

</div>
<div class="casino_venders">
    <% Html.RenderPartial("/Components/Vender", this.ViewData.Merge(new { @MetadataPath = "/MetaData/Venders/Sports", @ClassName="sports first" })); %> 
    <% Html.RenderPartial("/Components/Vender", this.ViewData.Merge(new { @MetadataPath = "/MetaData/Venders/LiveCasino", @ClassName = "livecasino last" })); %> 
</div>

<% Html.RenderPartial("/Casino/Jackpots/EGTJackpotBannerWidget", this.ViewData.Merge(new { })); %>


<ui:MinifiedJavascriptControl runat="server">
<script type="text/javascript">
        $(function () {
        $(".GLVendorFilter").find(".GFilterItem.OMI").remove();
        if($(".GLVendorFilter .GFilterItem").length - $(".GLVendorFilter .GFilterItemExtra").length <7)
        {
            $(".GLVendorFilter .GFilterItemExtra").eq(0).removeClass("GFilterItemExtra");
        }

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

