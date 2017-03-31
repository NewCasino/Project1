<%@ Page Language="C#" PageTemplate="/Affiliates/AffiliatesMaster.master" Inherits="CM.Web.ViewPageEx"
    Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>"
    MetaDescription="<%$ Metadata:value(.Description)%>" %>

<asp:content contentplaceholderid="cphHead" runat="Server">
<link rel="stylesheet" type="text/css" href="//cdn.everymatrix.com/ArtemisBetV3/affiliates.css" />
</asp:content>


<asp:content contentplaceholderid="cphMain" runat="Server">
<%--
Response.Redirect("http://affiliates.artemisbet100.com/user/register.do");--%>
<div class="AffiliateBanners">
<div class="JoinBanner AffiliateBlock">
    <h3 class="title AffiliateTitle"> <%=this.GetMetadata(".Welcome_Text").HtmlEncodeSpecialCharactors()
%> </h3>
    <p class="Subtitle AffiliateSubTitle"><%=this.GetMetadata(".SubTitle").HtmlEncodeSpecialCharactors()
%></p>
    <p class="AffiliateJoinNow"> <%=this.GetMetadata(".Join_Image")%> </p>
    <p class="AffiliateSignUpBox">
      <%: Html.Button(this.GetMetadata(".Button_SignUp"), new { onclick = "self.location='http://affiliates.artemisbet100.com/user/register.do';" })%>
    </p>
</div>
    <div class="SliderBanner AffiliateBlock">
    <% Html.RenderPartial("Slider", this.ViewData.Merge(new { @MetadataPath = "/Metadata/Affiliates/BannerSlider" })); %>
    </div>
</div>

<div class="AffiliateSteps">
<div class="Step1 AffiliateBlock">
    <span class="AffiliateStepIcon AFFIcon Icon AFFICon1">&nbsp;</span>  
        <%=this.GetMetadata(".Guide_Step1").HtmlEncodeSpecialCharactors()%>
    </div>
    
    <div class="Step2 AffiliateBlock">
    <span class="AffiliateStepIcon AFFIcon Icon AFFICon2">&nbsp;</span>  
        <%=this.GetMetadata(".Guide_Step2").HtmlEncodeSpecialCharactors()%>
    </div>
    
    <div class="Step3 AffiliateBlock">
    <span class="AffiliateStepIcon AFFIcon Icon AFFICon2">&nbsp;</span> 
        <%=this.GetMetadata(".Guide_Step3").HtmlEncodeSpecialCharactors()%>
    </div>
</div>
<ui:MinifiedJavascriptControl runat="server" Enabled="true" AppendToPageEnd="true">
<script type="text/javascript"> 
jQuery("body").addClass("affiliatePage");
jQuery('.inner').addClass('AffiliateContent');
</script>
</ui:MinifiedJavascriptControl>

</asp:content>

