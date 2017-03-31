<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>

<script runat="server" type="text/C#">
    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        if (Profile.IsAuthenticated)
        {
            Response.Redirect("/");
        }
    }
</script>
<asp:Content ContentPlaceHolderID="cphHead" Runat="Server"></asp:Content>

<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<% Html.RenderPartial("Header"); %>
    <div id="slider" class="sliderContainer iosSlider">  
        <% Html.RenderPartial("/Home/Slider", this.ViewData.Merge(new {@SliderPath = "/MetaData/Sliders/AffiliateLanding/Second" })); %> 
        <div class="HomeWidget">
            <% if (!Profile.IsAuthenticated) {
                Html.RenderPartial("/QuickRegister/RegisterWidget2");
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
        <div class="HomeBottomWidget RegisterCTAWidget">
            <%=(Profile.IsAuthenticated ? "" : this.GetMetadata("/Home/_Index_aspx.HomeFinalRegister_Html"))%>
        </div>
    </div>

    <ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" AppendToPageEnd="true">
        <script type="text/javascript">
            $(function() {
                
                $(".topContentMain.commonTopContent").remove();
                $(".topContentMain.AffVedio").show();
            });
            jQuery('body').addClass('HomePage AffLandingPage');
            jQuery('.inner').removeClass('PageBox').addClass('HomeContent');
        </script>
    </ui:MinifiedJavascriptControl>
</asp:Content>