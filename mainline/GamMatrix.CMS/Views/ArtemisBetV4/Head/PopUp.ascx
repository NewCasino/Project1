<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
    <input class="button" id="RedirectToRegister" onclick="this.blur();" type="button" style="display:none;" />
    <input class="button" id="RedirectToLogin" onclick="this.blur();" type="button" style="display:none;" />
    <input class="button" id="RedirectToForgotPassword" onclick="this.blur();" type="button" style="display:none;" />
<script type="text/javascript">
    var IntVRegisterPopUp=function(){PopUpInIframe("/QuickRegister","register-popup",670,690);}
    var IntVLoginPopUp=function(){$('a.OpenLogin',top.document.body).click();}
    var IntVForgotPasswordPopUp=function(){$('li.forgotpassword a',top.document.body).click();}
    var PopUpStructureInterval; 
    function PopUpInIframe(url,className,width,height){
        $('iframe.ARFrameLoader').remove();
        $('<iframe style="border:0px;display:none" frameborder="0" scrolling="yes" allowTransparency="true" id="ARFrameLoader" name="ARFrameLoader" class="ARFrameLoader"></iframe>').appendTo(top.document.body);
        var $iframe = $('iframe.ARFrameLoader', top.document.body).eq(0);
        $iframe.attr('src', url + "?_=<%= DateTime.Now.Ticks %>");
        $iframe.css({"width":width,"height":height,"visibility":"hidden"});
        PopUpStructureInterval=setInterval(verifyPopUpStructure,500); 
        $iframe.modalex(width, height, true, top.document.body);
        $('#ARFrameLoader').load(function() {
            $('#ARFrameLoader').contents().find('body').addClass("PopUpPage "+className);
            //$(top.document.body).addClass("PopUpPage "+className);
            $('#ARFrameLoader').contents().find('.PopUpPage #header, .PopUpPage #footer, .PopUpPage .ProfileMenu').hide();
            $('#ARFrameLoader').contents().find('.main-pane').css("width","100%");
            $('#ARFrameLoader').contents().find(".PromoOverlay").hide();
            $iframe.css({"visibility":"visible"});
            $('#simplemodal-container', top.document.body).addClass("PopUpContainer ");
            var arrClassName = className.split(" ");
            for(var i=0;i<arrClassName.length;i++){
                $('#simplemodal-container', top.document.body).addClass(arrClassName[i] + "-Container ");
            }
            try {
                $("iframe",top.document.body).contents().find(".PopUpPage .topContentMain").hide();
            }
            catch (e) { }
            adjustPosition(this);
            $("#simplemodal-overlay").click(function(e){
                $(".simplemodal-close").click();
            });
            $("#ARFrameLoader",top.document.body).contents().find(".join_now").click(function(e){
                e.preventDefault();
                $('#RedirectToRegister').trigger("click");
            });
            $("#ARFrameLoader",top.document.body).contents().find("#btnGoToSignUpPage").click(function(e){
                e.preventDefault();
                $('#RedirectToRegister').trigger("click");
            });
            $("#ARFrameLoader",top.document.body).contents().find("#signin-button").click(function(e){
                e.preventDefault();
                $('#RedirectToLogin').trigger("click");
            });
            $("#ARFrameLoader",top.document.body).contents().find(".forgot_password").click(function(e){
                e.preventDefault();
                $('#RedirectToForgotPassword').trigger("click");
            });
        });
    }
    function verifyPopUpStructure(){
        if($('.simplemodal-wrap .simplemodal-data', top.document.body).length == 0){
            if($('.simplemodal-wrap', top.document.body).length > 0 && $('.simplemodal-data', top.document.body).length > 0){
                if($('iframe.ARFrameLoader', top.document.body).appendTo(".simplemodal-wrap", top.document.body))
                    clearInterval(PopUpStructureInterval);
            }
        }
        else
            clearInterval(PopUpStructureInterval);
     }
    function adjustPosition(obj) {
        var containerHeight = $('#ARFrameLoader', top.document.body).contents().find("#container").height();
        if(containerHeight == null)
            containerHeight = $('#ARFrameLoader', top.document.body).contents().find('body').height();
        var containerWidth = $('#ARFrameLoader', top.document.body).contents().find("#container").width();
        if(containerWidth == null)
            containerWidth = $('#ARFrameLoader', top.document.body).contents().find('body').width();
        if($('#ARFrameLoader', top.document.body).contents().find('.DialogHeader').length == 0) {
            $('#ARFrameLoader', top.document.body).contents().find('body').css("padding-top","15px").css("padding-right","10px");
        }
        else{
            containerHeight = $('#ARFrameLoader', top.document.body).contents().find('body').height() + parseInt($('#ARFrameLoader', top.document.body).contents().find('body').css("padding-top")) + parseInt($('#ARFrameLoader', top.document.body).contents().find('body').css("padding-bottom"));
        }
        var screenHeight = $(top.window).height();
        if(containerHeight>screenHeight-50){
            containerHeight=screenHeight-50;
        }
        var screenWidth = $(top.window).width();
        var leftX = (screenWidth - containerWidth) / 2;
        var topY = (screenHeight - containerHeight) / 2;
        if($('#ARFrameLoader', top.document.body).contents().find('.DialogHeader').length > 0) {
            topY = topY - 20;
        }
        if (topY < 0) {
            topY = 0;
        }
        $("#ARFrameLoader", top.document.body).css({ width: containerWidth, height: containerHeight });
        $('#simplemodal-container', top.document.body).css({ left: leftX, top: topY, width: containerWidth, height: containerHeight });
    }
    function changeIframeSrc(url,className,width,height){
        var $iframe = $('iframe.ARFrameLoader', top.document.body).eq(0);
        $iframe.attr('src', url + "?_=<%= DateTime.Now.Ticks %>");
        $iframe.css({"width":width,"height":height,"visibility":"hidden"});
        $iframe.modalex(width, height, true, top.document.body);
    }
    $(function () {
        $(".join_now, .ButtonCTA").click(function(e){
            e.preventDefault();
            if($("body").hasClass("AffLandingPage")){
                top.PopUpInIframe("/LandingRegister","AffPopup",670,690);
            }
            else{
                PopUpInIframe("/QuickRegister","register-popup",670,690);
            }
        });
        $('.DepositButton').click(function(e){
            e.preventDefault();
            top.PopUpInIframe("/deposit","deposit-popup",670,690);
        });
        $('#WidgetbtnRegisterContinue').click(function(e){
            e.preventDefault();
            top.PopUpInIframe("/QuickRegister","register-popup",670,690);
        });
        $('#LandingRegisterContinue').click(function(e){
            e.preventDefault();
            top.PopUpInIframe("/LandingRegister","AffPopup",670,690);
        });
        $("a.OpenLogin").click(function(e) {
            e.preventDefault();
            PopUpInIframe("/Login/Dialog","Login-popup",460,500);
        });
        $("#btn_Aff_Login").click(function(e) {
            e.preventDefault();
            PopUpInIframe("/Login/Dialog","Login-popup Aff-Login-popup",500,488);
        });
        $("li.forgotpassword a").click(function(e) {
            e.preventDefault();
            PopUpInIframe("/forgotpassword","forgotpassword-popup register-popup",670,690);
        });
    });
    $('#RedirectToRegister').bind("click",function(e){
            $(".simplemodal-close",top.document.body).click();
            setTimeout(IntVRegisterPopUp, 500);
        });
    $('#RedirectToLogin').bind("click",function(e){
            $(".simplemodal-close",top.document.body).click();
            setTimeout(IntVLoginPopUp, 500);
        });
    $('#RedirectToForgotPassword').bind("click",function(e){
            $(".simplemodal-close",top.document.body).click();
            setTimeout(IntVForgotPasswordPopUp, 500);
        });
    
</script>