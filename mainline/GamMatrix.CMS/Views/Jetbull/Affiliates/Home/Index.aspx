<%@ Page Language="C#" PageTemplate="/Affiliates/AffiliateMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<asp:Content ContentPlaceHolderID="cphHead" Runat="Server"> </asp:Content>
<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
  <div class="affiliate_banner_home">
    <div class="affiliate_banner_left">
        
        <div class="affiliate_banner_icon">

        </div>
        <div class="affiliate_banner_title">
        <%=this.GetMetadata(".Welcome_Text").HtmlEncodeSpecialCharactors()%>
        </div>
        <div class="affiliate_banner_button">
            <%: Html.Button(this.GetMetadata(".Welcome_Link_Text"), new { onclick = "self.location='" + this.GetMetadata(".Welcome_Link_Url") + "';" })%>
        </div>
    </div>
    <div class="affiliate_banner_right">
        <% Html.RenderPartial("Slider", this.ViewData.Merge(new { @MetadataPath = "/Metadata/Affiliates/BannerSlider" })); %>
    </div>
  </div>
  <div class="affiliate_steps">
    <div class="affiliate_step_title">
      <span><%=this.GetMetadata(".Guide_1_Text")%></span>
    </div>
    <a class="affiliate_step step1" href="http://affiliate.jetbull.com/user/register.do" target="_blank">
      <div class="step_img"> <%=this.GetMetadata(".Guide_1_Image")%> </div>
      <div class="step_txt">
        <div class="step_icon"></div>
        <div class="step_intro"><%=this.GetMetadata(".Guide_1_Intro")%></div>
      </div>
    </a>
    <a class="affiliate_step step2" href="/Affiliates/MarketingTools">
      <div class="step_img"> <%=this.GetMetadata(".Guide_2_Image")%> </div>
      <div class="step_txt">
        <div class="step_icon"></div>
        <div class="step_intro"><%=this.GetMetadata(".Guide_2_Intro")%></div>
      </div>
    </a>
    <a class="affiliate_step step3" href="/Affiliates/Rates">
      <div class="step_img"><%=this.GetMetadata(".Guide_3_Image")%></div>
      <div class="step_txt">
        <div class="step_icon"></div>
        <div class="step_intro"><%=this.GetMetadata(".Guide_3_Intro")%></div>
      </div>
    </a>
  </div>
  <script>
      $(function () { menu_setMenuCurrent($("#menu li.home")); });
  </script>
</asp:Content>
