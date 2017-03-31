<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>

<script type="text/C#" runat="server">
    private int GetSubtractiveBorderHeight()
    {
        int height = 0;
        try
        {
            if (int.TryParse(this.ViewData["SubtractiveBorderHeight"].ToString(), out height))
                return height;
        }
        catch
        {
        }
        return 200;
    }

    private string GetCustomClass()
    { 
        if (this.ViewData["CustomClass"] != null)
        {
            return this.ViewData["CustomClass"].ToString();
        }
        return string.Empty;
    }

    
    #region  Reality
    private static string RealityCookieKey = "_c_r_c_k_";
    private string RealityUserKey = string.Empty;
    private bool? _isRealityChecked;
    private bool RealityCheck()
    {
        if (!Settings.SafeParseBoolString(Metadata.Get("Metadata/Settings.RealityCheckEnabled"), false) || (Profile.UserCountryID != 230))
            return true;

        HttpCookie cookie = Request.Cookies[RealityCookieKey];
        Action removeCookie = () =>
        {
            if (cookie != null)
            {
                cookie.Expires = DateTime.Now.AddDays(-1);
                Response.AppendCookie(cookie);
            }
        };
        Action<string> writeCookie = (key) =>
        {
            if (cookie == null)
                cookie = new HttpCookie(RealityCookieKey);
            cookie.Value = key;
            cookie.Expires = DateTime.Now.AddYears(1);

            Response.AppendCookie(cookie);
        };

        if (!Profile.IsAuthenticated)
        {
            removeCookie();
            return true;
        }


        RealityUserKey = Profile.UserID.ToString().DefaultEncrypt();
        if (cookie != null)
        {
            if (cookie.Value.Equals(RealityUserKey, StringComparison.InvariantCultureIgnoreCase))
                return true;
            else
            {
                // re-check
                var coreChecked = CheckRealityByCore();
                if (coreChecked)
                {
                    writeCookie(RealityUserKey);
                    return true;
                }
                else
                {
                    removeCookie();
                    return false;
                }
            }
        }
        else
        {
            var coreChecked = CheckRealityByCore();
            if (coreChecked)
            {
                writeCookie(RealityUserKey);
            }
            return coreChecked;
        }
    }
    private bool IsRealityChecked
    {
        get
        {
            if (_isRealityChecked != null)
                return _isRealityChecked.Value;

            _isRealityChecked = RealityCheck();

            return _isRealityChecked.Value;

        }
    }

    private bool CheckRealityByCore()
    {
        using (GamMatrixClient client = GamMatrixClient.Get())
        {
            GetUserRealityCheckRequest realityCheck = client.SingleRequest<GetUserRealityCheckRequest>(new GetUserRealityCheckRequest()
            {
                UserID = Profile.UserID,
            });

            var realityValue = realityCheck.UserRealityCheckValue;

            return !string.IsNullOrWhiteSpace(realityValue);
        }
    }
    #endregion
</script>
<% if (!IsRealityChecked)
    { %>
    <div id="realityCheckWrap" style="display:none;">
        <% Html.RenderPartial("/RealityCheck/InputView", this.ViewData); %>
    </div>
    <style type="text/css">
        #realityCheckWrap p {
            text-align: left;
            font-size: 1.6em;
            line-height: 1.3em;
            text-indent: 1em;
            margin-top: 1em;
        }
    </style>
<%} %>


<div class="Overlay GonzoPopup <%=GetCustomClass().SafeHtmlEncode() %>">

<div class="Wrapper1">
<div class="Wrapper2">

    <div class="Popup GamePopup">
        <div class="PopupContainer">

	        <a class="ClosePopup" href="#" title="<%= this.GetMetadata(".Close_Tip").SafeHtmlEncode() %>">
                <%= this.GetMetadata(".Close").SafeHtmlEncode() %>
            </a>

	        <div class="panAction">
                <% Html.RenderPartial("/Casino/Lobby/GameAreaCore"); %>
            </div>
	
        </div>
    </div>

</div>
</div>

</div>

<script type="text/javascript">

     var needRealityCheck = <%=(!IsRealityChecked).ToString().ToLower() %>;
        var userRealityKey = "<%=RealityUserKey %>";
        var realityCookieKey = "<%=RealityCookieKey %>";

        var onRealityCheckd;

        if(needRealityCheck){
            $(document).bind("_ON_RealityCheck_APPLIED",function(){
                $.cookie(realityCookieKey,userRealityKey,{
                    path:"/",
                    expires:  (function(){
                        var d = new Date();
                        d.setYear(d.getYear() + 1);
                        return d;
                    })()
                });

                if(onRealityCheckd)
                    onRealityCheckd();
            });
        }

    function __loadGame(gameID, playForFun) {
        var documentHeight = $(document).height();
        var popupHeight = Math.max( $(window).height(), 650) - 20;
        var iframeHeight = popupHeight - <%= GetSubtractiveBorderHeight() %>;

        if(!needRealityCheck || playForFun){
            openGamingWindow();
        }else{
            $("#realityCheckWrap").modal();

            onRealityCheckd = function(){
                needRealityCheck = false;
                $.modal.close();
                openGamingWindow();
            }
        }

        function openGamingWindow(){

            var $li = $('li.GLItem[data-backgroundImage][data-gameID="' + gameID.scriptEncode() + '"]');
            var url = $li.data('backgroundImage') || $li.attr('data-backgroundImage');

            $('div.Overlay').appendTo(document.body);
            if( url != '' )
                $('div.Overlay').css('background-image', 'url(' + url + ')');
            $('div.Overlay').height(documentHeight + 'px').fadeIn(500);
            $('div.Overlay').css('position','fixed');
            //$('div.Overlay').css('paddingTop', $(document.documentElement).scrollTop() + 10);
            $('div.Popup').height(popupHeight + 'px').slideDown(700).addClass('ShowPopup');
            $('div.Popup div.GameContainer').height(iframeHeight);
            __loadCasinoGame(gameID, playForFun == true, iframeHeight);
        }
    }

    $(function () {
        $(document).bind("CASINOENGINE_GAME_ERROR", function(e,params){            
            if(params.ErrorCode == '-5')
            {
                __loadGame(params.GameID, true);
                return;
            }
            $('a.ClosePopup').trigger("click");
        });
        // <%-- Close button click event --%>
        $('a.ClosePopup').click(function (e) {
            e.preventDefault();

            __unloadCasinoGame();
            $('div.Popup').slideUp(500).removeClass('ShowPopup');
            $('div.Overlay').fadeOut(700);
        });

        // <%-- Back button click event --%>
        $('div.GameArea ul.ControllerButtons li.CBBack a.Button').click(function (e) {
            e.preventDefault();

            __unloadCasinoGame();
            $('div.Popup').slideUp(500).removeClass('ShowPopup');
            $('div.Overlay').fadeOut(700);
        });

        // <%-- Fullscreen button click event --%>
        $('div.GameArea ul.ControllerButtons li.CBFull a.Button').click(function (e) {
            e.preventDefault();

            var features = "toolbar=no,menubar=no,scrollbars=no,resizable=yes,location=no,status=no,left=0,top=0,width=" + window.screen.availWidth + ",height=" + window.screen.availHeight;
            window.open($('#ifmCasinoGame').attr('src'), "_blank", features);

            __unloadCasinoGame();
            $('div.Popup').slideUp(500).removeClass('ShowPopup');
            $('div.Overlay').fadeOut(700);
        });

    });

</script>