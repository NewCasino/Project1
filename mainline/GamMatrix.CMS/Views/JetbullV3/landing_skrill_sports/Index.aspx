<%@ Page Language="C#" Inherits="CM.Web.ViewPageEx" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html class=" js flexbox flexboxlegacy canvas canvastext no-touch geolocation postmessage no-websqldatabase indexeddb hashchange history draganddrop websockets rgba hsla multiplebgs backgroundsize borderimage borderradius boxshadow textshadow opacity cssanimations csscolumns cssgradients no-cssreflections csstransforms csstransforms3d csstransitions fontface generatedcontent video audio localstorage sessionstorage webworkers applicationcache svg inlinesvg json cookies firefox firefox35 win" style="" xmlns="http://www.w3.org/1999/xhtml" dir="ltr" lang="en">
<script runat="server" type="text/C#">
protected override void OnLoad(EventArgs e)
{
    string affiliateMarker = Request.QueryString["btag"];

    if (!string.IsNullOrWhiteSpace(affiliateMarker))
    {
        HttpCookie cookie = new HttpCookie("btag", affiliateMarker.Trim());
        cookie.Secure = false;
        cookie.Expires = DateTime.Now.AddMinutes(Settings.Affiliate.Btag_CookieExpiresMinutes);
        cookie.HttpOnly = false;
        if (!string.IsNullOrWhiteSpace(SiteManager.Current.SessionCookieDomain))
            cookie.Domain = SiteManager.Current.SessionCookieDomain;
        HttpContext.Current.Response.Cookies.Add(cookie);
    }    base.OnLoad(e);
}
</script>
<head id="Head1">
    <link rel="stylesheet" type="text/css" href="//cdn.everymatrix.com/JetbullV2/landing_skrill_files/_import.css" />
    <script src="//cdn.everymatrix.com/JetbullV2/landing_skrill_files/analytics.js" async=""></script>
    <script type="text/javascript" src="//cdn.everymatrix.com/JetbullV2/landing_skrill_files/combined.js"></script>
    <meta http-equiv="content-type" content="text/html; charset=UTF-8">
    <meta http-equiv="X-UA-Compatible" content="requiresActiveX=true">
    <link rel="shortcut icon bookmark" href="http://www.jetbull.com/favicon.ico" type="image/x-icon">
    <link rel="apple-touch-icon" href="http://www.jetbull.com/apple-touch-icon.png" type="image/png">
    <meta http-equiv="content-language" content="en">
    <title><%=this.GetMetadata(".Title").HtmlEncodeSpecialCharactors() %></title>
    <link href="//cdn.everymatrix.com/JetbullV2/landing_skrill_files/jquery.css" media="screen" type="text/css" rel="stylesheet" /><!--[if LT IE 9]><link href="//cdn.everymatrix.com/JetbullV2/ie.css" rel="stylesheet" type="text/css" /><![endif]-->
</head>


<body dir="ltr" class="lang_en  Anonymous" data-desktop="http://www.jetbull.com/" data-mobile="http://m.jetbull.com/" data-cookiedomain="jetbull.com" data-ismobile="0">
    

<script type="text/javascript">
if (window.location.toString().indexOf('.gammatrix-dev.net') > 0)
    document.domain = document.domain;
else
    document.domain = 'jetbull.com';

// <![CDATA[
    InputFields.onErrorPlacement = function (error, element) {
        var $pdiv = $(element).parents("div.inputfield");error.attr('elementId', $pdiv.attr('id'));if($('td.hint > *', $pdiv).length < 1 ){$('td.hint', $pdiv).html("<span class='NoticeText'>"+ $('td.hint', $pdiv).text() +" </span>");}
        error.insertAfter($('td.hint > *:last', $pdiv));
    }



    function Page_Style_Init() {
        
        //$('.notification_icon').each(function() {
        //    $(this).parent().find('a.menu-item').append($(this).detach());
        //});
    }

    function GetPaymentLink() {
        $(".deposit-table .link").each(function () {
            var href = $(this).find("a").attr("href");
            $(this).parents("tr").click(function () {
                
                    $('iframe.CasinoHallDialog').remove();
                    $('<iframe style="border:0px;width:400px;height:300px;display:none" frameborder="0" scrolling="no" src="/Casino/Hall/Dialog?_=635591839165064933" allowTransparency="true" class="CasinoHallDialog"></iframe>').appendTo(top.document.body);
                    var $iframe = $('iframe.CasinoHallDialog', top.document.body).eq(0);
                    $iframe.modalex($iframe.width(), $iframe.height(), true, top.document.body);
                    return false;
                
            });
        });

        
    }

    $(document).ready(function () {
        $("head").append('<!--[if LT IE 9]><link href="//cdn.everymatrix.com/JetbullV2/ie.css" rel="stylesheet" type="text/css" /><![endif]-->');

        
            $(".sidemenu .withdraw,.sidemenu .pendingwithdrawal,.sidemenu .transfer,.sidemenu .buddytransfer,.sidemenu .accountstatement,.sidemenu .changeemail,.sidemenu .changepwd,.sidemenu .changepwd,.sidemenu .mysportsaccount,,.sidemenu .availablebonus").parent("li").remove();
        
            $(".sidemenu .transfer").parent("li").remove();
        

        $('#pnAccountStatement #filterType option[value=BuddyTransfer]').remove();
        $('#pnAccountStatement #filterType option[value=CakeNetworkWalletCreditDebit]').remove();

        GetPaymentLink();
        $(".withdraw-table .link").each(function () {
                var href = $(this).find("a").attr("href");
                $(this).parents("tr").click(function () {
                    
                        $('iframe.CasinoHallDialog').remove();
                        $('<iframe style="border:0px;width:400px;height:300px;display:none" frameborder="0" scrolling="no" src="/Casino/Hall/Dialog?_=635591839165064933" allowTransparency="true" class="CasinoHallDialog"></iframe>').appendTo(top.document.body);
                        var $iframe = $('iframe.CasinoHallDialog', top.document.body).eq(0);
                        $iframe.modalex($iframe.width(), $iframe.height(), true, top.document.body);
                        return false;
                    
                });
        });

        $(document).bind("_ON_PAYMENT_METHOD_LIST_LOAD_", GetPaymentLink);
        
        

        $('.foot_links a').each(function() {
            var href = $(this).attr('href');
            var reg = new RegExp(href);
            var currentUrl = document.location;
            if (reg.test(currentUrl)) {
                $(this).parent().addClass('ActiveItem');
            }
        });
         
        setInterval(function() { if ($(document).scrollTop() < 110) {$('#toplinks a.Home').css('display','none');} else {$('#toplinks a.Home').css('display','block');}},200);

        $(window).resize(function () {
            Page_Style_Init();
        });
        //alert('182 10.0.10.244');
        Page_Style_Init();
    });
// ]]>
</script>
<script>
  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

  ga('create', 'UA-5470473-6', 'auto');
  ga('send', 'pageview');

</script>
<script language="javascript" type="text/javascript">
$(document).bind( 'BALANCE_UPDATED', function(){
    try { top.reloadBalance(); }catch(e){}
});
$(document).ready(function() {
var LiveChatUrl = $(".LiveChatPop a").attr('href');
$(".LiveChatPop a").attr('target','_self').attr('href','javascript:void(0);return false;');
//$(".icon_mobile a").attr('target','_self').attr('href','javascript:void(0);'); 
$(".LiveChatPop").click(function(){ 
    window.open(LiveChatUrl, "LiveChat", "height=400, width=500, top=100, left=100,toolbar=no, menubar=no, scrollbars=no, resizable=no, location=no, status=no");
});
  $(".livechat").click(function(){
    $(".LiveChatPop").click();
  });
  $(".icon_mobile a").click(function(){
    DeviceChecker.Switcher.Custom(true, false, false);
  });
});
 
</script>
    <%=this.GetMetadata(".Html_container") %>
    <!--keep session alive-->
    
    <script>//<![CDATA[
;var isIE6=/msie 6/i.test(navigator.userAgent);if(isIE6){alert("You are using Internet Explorer 6, some of the features may not be available, and we recommend that you upgrade your Internet Explorer to a higher version for an improved experience.");}try{var arrCookie=document.cookie.split(";");for(var i=0;i<arrCookie.length;i++){var arr=arrCookie[i].split("=");if("_ser"==arr[0].replace(/(^\s*)|(\s*$)/g,"")){var endIndex=arr[1].indexOf(";");if(endIndex==-1){endIndex=arr[1].length;}var sessionExitReason=unescape(arr[1].substring(arr[1],endIndex));var expDate=new Date();expDate.setDate(expDate.getDate()-1);document.cookie="_ser=0; expires="+expDate.toGMTString()+";path=/; domain=jetbull.com";var msg="";switch(sessionExitReason){case"Expired":msg="You have been inactive for too long and your session has timed out. For security reasons you have been logged out automatically.\u000A\u000APlease click OK to log in again.";break;case"Reentry":msg="You have been disconnected as someone has signed in with your account in another place.\u000A\u000APlease note that if this was not intentional, someone may have stolen your password and we suggest you change it immediately.";
break;case"IPChanged":msg="You have been disconnected as your IP address has changed since your last login.";break;case"LimitExceeded":msg="You have been disconnected as your session time limitation is reached.";break;}if(msg.length>0){alert(msg);}}}}catch(e){}$(function(){$(document).bind("BALANCE_UPDATED",function(){try{top.reloadBalance();}catch(e){}});});

//]]>
</script>
    
    <script type="text/javascript" src="//cdn.everymatrix.com/JetbullV2/landing_skrill_files/devicechecker.js"></script>
    
    <%=this.GetMetadata(".Html_SwitchPromot") %>
    <script type="text/javascript">
        $(function () {
            DeviceChecker.Promoting.Init();
        });
    </script>
    


</body></html>