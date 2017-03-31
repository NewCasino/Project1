<%@ Page Language="C#" PageTemplate="/LiveCasino/LiveCasinoMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
<link rel="stylesheet" type="text/css" href="//cdn.everymatrix.com/ArtemisBetV3/casinohall.css" />
<link rel="stylesheet" type="text/css" href="//cdn.everymatrix.com/ArtemisBetV3/livecasinohall.css" />
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<%-- Html.RenderPartial("Slider", this.ViewData.Merge( new { } )); --%>
<% Html.RenderPartial("/LiveCasino/Hall/GameNavWidgetV2/Main", this.ViewData.Merge( new{ @Category = "LOTTERY",@BannerPath = "/LiveCasino/Lottery/_Index_aspx.StaticBanner_Html"} )); %>
<ui:MinifiedJavascriptControl runat="server" Enabled="true" AppendToPageEnd="true">
<script>
jQuery('body').addClass('LotteryPage');
$('#close-LiveCasinoSlider').on('click', function(e){
      e.preventDefault();
      $('.LiveCasinoSlider').slideUp("500");
      $('#show-LiveCasinoSlider').removeClass('hidden');
      $('#close-LiveCasinoSlider').addClass('hidden');
});
$('#show-LiveCasinoSlider').on('click', function(e){
        e.preventDefault();
        $('.LiveCasinoSlider').slideDown("500");
        $('#show-LiveCasinoSlider').addClass('hidden');
        $('#close-LiveCasinoSlider').removeClass('hidden');
});
$(function(){
    $('ol.GamesCategories li.cat-LOTTERY').addClass('ActiveCat');
    $('ol.GamesCategories li.ActiveCat a.TabLink').data('category','LOTTERY');
                $('ol.TablesList li.GLItem').show();

            !($(':checkbox[name="filterVIPTables"]:not(:checked)').length > 0) ?  
                $('ol.TablesList li.GLItem[data\-viptable="0"]').hide() :
                "";

            var selectedCat = $('ol.GamesCategories li.ActiveCat a.TabLink').data('category');
            if (selectedCat != null) {
                $('ol.TablesList li.GLItem[data\-category!="' + selectedCat + '"]').hide();
            }            
                   
            $(':checkbox[name="filterVendors"]:not(:checked)').each(function (el) {
                var v = $(this).val();
                $('ol.TablesList li.GLItem[data\-vendor="' + v + '"]').hide();
            });    
            var existings = {};
            $('ol.TablesList li.GLItem:visible').each(function(el){
                var id = $(this).data('tableid');
                if( existings[id] != null )
                    $(this).hide();
                else
                    existings[id] = true;
            });
            $(".BannerGLItem").show();
            $('#livecasino-game-popup').hide();
});
</script>
</ui:MinifiedJavascriptControl>
</asp:Content>

