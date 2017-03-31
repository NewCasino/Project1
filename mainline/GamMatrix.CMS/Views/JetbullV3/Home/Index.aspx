<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx<List<Poker.Tournament>>"   Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>"  MetaDescription="<%$ Metadata:value(.Description)%>" %>
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
    <% Html.RenderPartial("/Components/Vender", this.ViewData.Merge(new { @MetadataPath = "/MetaData/Venders/Sports", @ClassName="sports first" })); %> 
    <% Html.RenderPartial("/Components/Vender", this.ViewData.Merge(new { @MetadataPath = "/MetaData/Venders/LiveCasino", @ClassName = "livecasino" })); %> 
    <% Html.RenderPartial("/Components/Vender", this.ViewData.Merge(new { @MetadataPath = "/MetaData/Venders/Casino", @ClassName="casino" })); %> 
    <% Html.RenderPartial("/Components/Vender", this.ViewData.Merge(new { @MetadataPath = "/MetaData/Venders/Promotions", @ClassName="promotions last" })); %> 
</div>

<script type="text/javascript">
$(function(){
$('html').addClass('HomePage');
$("body").addClass("Homepage");
});
</script>
</asp:content>
