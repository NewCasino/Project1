<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

    <div id="slider" class="sliderContainer iosSlider">
   
        <% Html.RenderPartial("/Home/Slider", this.ViewData.Merge(new {@SliderPath = "/MetaData/Home/Slider" })); %> 
            
        <div class="HomeWidget">
            <% if (!Profile.IsAuthenticated) {
                Html.RenderPartial("/QuickRegister/RegisterWidget");
            } else { 
                Html.RenderPartial("/Home/DepositWidget");
            } %>
        </div>
    
        <%=this.GetMetadata("/Components/_Slider_ascx.Banner_Controller")%>
 
    </div>

    <div class="secondSlider">
        <% Html.RenderPartial("/Components/Slider2", this.ViewData.Merge(new {@SliderPath = "/Metadata/Sliders/Home/Second/" }));%>
    </div>

    <div class="HomeWidgets">
        <div class="HomeBottomWidget SportsWidget">
            <% Html.RenderPartial("/Home/SportsWidget");%>
        </div>
        <div class="HomeBottomWidget CasinoWidget">
            <% Html.RenderPartial("/Home/CommonWidget", this.ViewData.Merge(new {@WidgetPath = "/Metadata/Widgets/Home/Casino/" }));%>
        </div>
        <div class="HomeBottomWidget LiveCasinoWidget">
            <% Html.RenderPartial("/Home/CommonWidget", this.ViewData.Merge(new {@WidgetPath = "/Metadata/Widgets/Home/LiveCasino/" }));%>
        </div>
    </div>

    <ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" AppendToPageEnd="true">
        <script type="text/javascript">
            jQuery('body').addClass('HomePage');
            jQuery('.inner').removeClass('PageBox').addClass('HomeContent');
        </script>
    </ui:MinifiedJavascriptControl>
    <script type="text/javascript">
        $(function () {
            $(".ButtonCTA").attr("href","/register");
        });
    </script>
    <script src="https://zz.connextra.com/dcs/tagController/tag/7d61b44fefd2/homepage?" async defer></script>