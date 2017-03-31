<%@ Page Language="C#" PageTemplate="/Mobile/MobileMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div id="mobile_presentation">
    <div id="mobile_content"> 
      <div id="mobile_wrapper">
        <div id="mobile_preview">
          <ul id="MobileSliderList">
            <li id="slide-1" class="Active"><%= this.GetMetadata(".MobileSliderPic1") %></li>
            <li id="slide-2"><%= this.GetMetadata(".MobileSliderPic2") %></li>
            <li id="slide-3"><%= this.GetMetadata(".MobileSliderPic3") %></li>
            <li id="slide-4"><%= this.GetMetadata(".MobileSliderPic4") %></li>
          </ul>
          <script type="text/javascript">
$(document).ready( function () { 
   var list = $('ul#MobileSliderList');
   list.find('li').removeClass('Active');
   window.slide = 1;
   list.find('#slide-'+window.slide).show();
   window.slideNow = function () {
 if ( window.timer ) {
 list.find('#slide-'+window.slide).fadeOut( 1000, function () {
 if ( window.slide < list.find('li').length ) window.slide += 1;
 else window.slide = 1;
 list.find('#slide-'+window.slide).fadeIn( 1000 );
 if ( window.timer ) {
 window.x = setTimeout('slideNow();', 6000);
 }
 } );
 }
 
   }
   window.x = setTimeout('slideNow();', 6000);
   window.timer = true;
});
    </script> 
        </div>
      </div>
      <div id="mobile_text"><%= this.GetMetadata(".Html").HtmlEncodeSpecialCharactors() %></div>
    </div>
    <div class="w2c w2e-20"></div>
  </div>
</asp:Content>

