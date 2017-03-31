<%@ Page Language="C#"   Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<html><head><script type="text/javascript" src="//cdn.everymatrix.com/Oddsmatrix/prod/website/js/jquery/jquery-1.7.min.js"></script><link rel="stylesheet" href="//cdn.everymatrix.com/Oddsmatrix/prod/website/style/styleBase.css?v=20141202-0634" />        <link rel="stylesheet" href="//cdn.everymatrix.com/Oddsmatrix/prod/website/style/o-newartemisbet.css?v=20141202-0634" /><script type="text/javascript">        document.domain = 'artemisbet300.com';
        function resizeIframe() {
               if (typeof window.parent !== undefined) {
                       var iframeHeight = jQuery('.message').height();
                       try {
                               setIframeHeight(iframeHeight);
                       } catch (e) {
                               console.log(e);
                       }
               }
       };
       function setIframeHeight(iframeHeight) {
               var sportsbookIframe = getCurrentIframe();
               if (sportsbookIframe) {
                       sportsbookIframe.attr("height", iframeHeight + 100);
                       sportsbookIframe.attr("scrolling", "no");
                       sportsbookIframe.css('height', '' + (iframeHeight + 100) + 'px');
               }
       };
       function getCurrentIframe() {
               var windowCurrent = window;
               var iframe = null;
               try {
                       jQuery(window.parent.document).find('iframe').each(function() {
                               if (jQuery(this)[0].contentWindow == windowCurrent) {
                                       iframe = jQuery(this);
                                       return;
                               }
                       });
               } catch (e) {
                       console.log(e);
               }
               return iframe;
       }
       var requestedURL = '/';
       var pathname = window.location.pathname;
       var disableRTF = true;
/*
       if (pathname != '/') {
               var pathName = window.location.pathname;
               if (window.location.search != '') {
                       pathName += '?' + window.location.search;
               }
               //window.location.href = '/fe_notification?requestedURL=' + pathName;
       }
  */     setTimeout(function() {
               window.location.reload();
       }, 30000);
       jQuery(document).ready(function() {
               resizeIframe();
       });
</script></head><body id="cl-47" class="maintenance Xx artemisbet Xx sBox Xx en_GB Xx ">       <div class="message"
               style="background-image: url('https://imgprod.oddsmatrix.com/omfe/website/img/base-img/maintenance.png');">               <span class="details">Hi There. We are currently performing maintenance, with our engineers hard at work as you are reading this message.<br/><br/>We're sorry about any problems we're causing you, but we promise to be back on track as soon as we possibly can.</span>       </div></body></html>

