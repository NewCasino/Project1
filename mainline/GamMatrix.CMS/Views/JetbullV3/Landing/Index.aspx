<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<asp:Content ContentPlaceHolderID="cphHead" Runat="Server"> </asp:Content>
<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">  
  <!--[if lt IE 7]><%=this.GetMetadata(".Ie7_Alert_Html")%><![endif]-->
  <div id="framework" class="LP">
    <div class="row-fluid">
      <h1 class="LP-PageH1"><%=this.GetMetadata(".Title_Text")%></h1>
    </div>
    <div class="row-fluid">
      <div class="AuxiliaryContent">
        <div  class="Col3 DepositNow">
          <button class="Button DepNow" onclick="top.location.href='/deposit'"> <%=this.GetMetadata(".Button_DepositNow_Html")%></button>
        </div>
        <div class="Col2 BackHomeP">
          <h3><%=this.GetMetadata(".Link_GoBack_Html")%></h3>
          <a class="BrandingLink" href="/" title="Jetbull Home Page"> <img class="BrandingImg" src="/Views/Jetbull/_files/landing/jetbull-logo.png" width="100%" alt="Jetbull Logo"> </a> </div>
      </div>
      <div id="" class="Col7 WelcomeMessage">
        <div class="Col7Content">
          <h3 class="BoxTitle"><%=this.GetMetadata(".NoticeBox_Title")%></h3>
          <div class="Content"> <%=this.GetMetadata(".NoticeBox_Content_Html")%> </div>
        </div>
        <!-- / --> 
      </div>
    </div>
    <div class="row-fluid">
      <div class="Col4">
        <div class="Col4-Content"> <%=this.GetMetadata(".Promotions_1_Html")%> </div>
      </div>
      <div class="Col4">
        <div class="Col4-Content"> <%=this.GetMetadata(".Promotions_2_Html")%> </div>
      </div>
      <div class="Col4">
        <div class="Col4-Content"> <%=this.GetMetadata(".Promotions_3_Html")%> </div>
      </div>
      <div class="Col4 last">
        <div class="Col4-Content"> <%=this.GetMetadata(".Promotions_4_Html")%> <%=this.GetMetadata(".Contact_Html")%> </div>
      </div>
    </div>
  </div>
  <%--
  <!--[if !(IE)]><!--><script type="text/javascript" src="//ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js"></script><!--<![endif]-->  
--%>
  <!-- Google plus --> 
  <script type="text/javascript">
/* <![CDATA[ */
(function() {
var po = document.createElement('script'); po.type = 'text/javascript'; po.async = true;
po.src = 'https://apis.google.com/js/plusone.js';
var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(po, s);
})();
/* ]]> */
</script> 
  <!-- /Google plus --> 
  
  <!-- Facebook like -->
  <div id="fb-root"></div>
  <script type="text/javascript">
/* <![CDATA[ */
(function(d, s, id) {
var js, fjs = d.getElementsByTagName(s)[0];
if (d.getElementById(id)) {return;}
js = d.createElement(s); js.id = id;
js.src = "//connect.facebook.net/en_US/all.js#xfbml=1";
fjs.parentNode.insertBefore(js, fjs);
}(document, 'script', 'facebook-jssdk'));
/* ]]> */
</script> 
  <!-- /FB like --> 
  
  <!-- Google Analytics --> 
  <script type="text/javascript">
/*
  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', 'UA-5470473-6']);
  _gaq.push(['_setDomainName', 'jetbull.com']);
  _gaq.push(['_trackPageview']);
  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();
*/
$(function(){
  _gaq.push(['_trackEvent', 'Registration', 'FormCompleted', 'Success']);
});
</script>

</asp:Content>
