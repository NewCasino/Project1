<%@ Page Language="C#" PageTemplate="/LiveCasino/LiveCasinoMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div class="Framework" id="framework">
<div class="Zone Container Intro">
<% Html.RenderPartial("/Components/Slider", this.ViewData.Merge(new { @SliderPath = "/Metadata/LiveCasino/Slider" })); %> 
</div>

<% Html.RenderPartial("GameNavWidget/Main", this.ViewData.Merge( new { } )); %>
<div class="casino_venders">    
    <% Html.RenderPartial("/Components/Vender", this.ViewData.Merge(new { @MetadataPath = "/MetaData/Venders/Sports", @ClassName="sports first" })); %>    
    <% Html.RenderPartial("/Components/Vender", this.ViewData.Merge(new { @MetadataPath = "/MetaData/Venders/Casino", @ClassName = "casino last" })); %>    
     <% Html.RenderPartial("/Components/Vender", this.ViewData.Merge(new { @MetadataPath = "/MetaData/Venders/Casino", @ClassName="casino" })); %> 
    <% Html.RenderPartial("/Components/Vender", this.ViewData.Merge(new { @MetadataPath = "/MetaData/Venders/Promotions", @ClassName="promotions last" })); %> 
</div>
</div>
</asp:Content>

