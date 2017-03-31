<%@ Page Language="C#" PageTemplate="/LiveCasino/LiveCasinoMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div class="Framework" id="framework">
<div class="Zone Container Intro">
    <% Html.RenderPartial("/Components/Slider", this.ViewData.Merge(new { @SliderPath = "/Metadata/LiveCasino/Lottery" })); %> 
</div>
    <% Html.RenderPartial("/LiveCasino/Hall/GameNavWidget/Main",   this.ViewData.Merge( new{ @Category = "LOTTERY"})); %>
    <div class="casino_venders">    
    <% Html.RenderPartial("/Components/Vender", this.ViewData.Merge(new { @MetadataPath = "/MetaData/Venders/LiveCasino", @ClassName = "livecasino first" })); %>    
    <% Html.RenderPartial("/Components/Vender", this.ViewData.Merge(new { @MetadataPath = "/MetaData/Venders/Casino", @ClassName = "casino last" })); %>    
    </div>
</div>
<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" AppendToPageEnd="true">
<script type="text/javascript">
    $('body').addClass('LotteryPage');

    $(function () {
        $('.topmenu .main-item').removeClass('selected');
        $('.topmenu .main-item.menu-lottery').addClass('selected');

        $('ol.GamesCategories li.cat-LOTTERY').find('.TabLink').trigger('click');

        $('.GLVendorFilter .GFilterItem').each(function (i, n) {
            var $n = $(n);
            if (!$n.hasClass('Ezugi') && !$n.hasClass('BetGames')) {
                $n.hide();
                $n.find(':checkbox[name="filterVendors"]').removeAttr('checked');
            }
            else
                $n.show();
        });        
    });
</script>
</ui:MinifiedJavascriptControl>
</asp:Content>


