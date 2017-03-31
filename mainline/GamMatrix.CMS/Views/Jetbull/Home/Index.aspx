<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<List<Poker.Tournament>>"
    Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>"
    MetaDescription="<%$ Metadata:value(.Description)%>" %>

<asp:content contentplaceholderid="cphHead" runat="Server"> 
</asp:content>
<asp:content contentplaceholderid="cphMain" runat="Server">
<div id="slider" class="sliderContainer iosSlider">
    <div class="row-fluid">
        <% Html.RenderPartial("/Components/Slider", this.ViewData.Merge(new { @SliderPath = "/MetaData/Home/ImageSlider" })); %> 
    </div>	
    <%=this.GetMetadata(".MobilePageDownload").HtmlEncodeSpecialCharactors()%>
</div>

<div class="venders">
    <% Html.RenderPartial("/Components/Vender", this.ViewData.Merge(new { @MetadataPath = "/MetaData/Venders/Sports", @ClassName = "sports first" })); %> 
    <% Html.RenderPartial("/Components/Vender", this.ViewData.Merge(new { @MetadataPath = "/MetaData/Venders/LiveCasino", @ClassName = "livecasino" })); %> 
    <% Html.RenderPartial("/Components/Vender", this.ViewData.Merge(new { @MetadataPath = "/MetaData/Venders/Casino", @ClassName = "casino last" })); %> 
</div>

<script type="text/javascript">
    $('html').addClass('HomePage');

//    $(function () {
//        var isMobile = $.browser.mobile; /* update this variable to contain mobile device detection */
//        if (isMobile) {
//        } else {
//            $('.MobileButton').each(function (e) {
//                var el = $(this);
//                el.siblings('.MobileBigQR').slideUp(100);
//                el.parents('.MobileLI').removeClass('ActiveItem');
//            });

//            $('.MobileDownload').delegate('.MobileButton', 'click', function (e) {
//                e.preventDefault();
//                var el = $(this);
//                if (el.parents('.MobileLI').hasClass('ActiveItem')) { /* collapse */
//                    el.siblings('.MobileBigQR').slideUp(100);
//                    el.parents('.MobileLI').removeClass('ActiveItem');
//                } else { /* expand */
//                    //$('.MobileBigQR').slideUp( 100, function () {
//                    $('.MobileBigQR').slideUp(100);
//                    $('.MobileLI').removeClass('ActiveItem');
//                    el.siblings('.MobileBigQR').slideDown(500, function () {
//                        el.parents('.MobileLI').addClass('ActiveItem');
//                    });
//                    //});
//                }
//            });
//        }
//    });
</script>
</asp:content>
