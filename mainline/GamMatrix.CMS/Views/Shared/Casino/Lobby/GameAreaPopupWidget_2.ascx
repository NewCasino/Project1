<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="CasinoEngine" %>
<script type="text/C#" runat="server">
    protected bool _IsBackgroundStretchHorizontally = true;
    public bool IsBackgroundStretchHorizontally {
        get { return _IsBackgroundStretchHorizontally; }
        set { _IsBackgroundStretchHorizontally = value; }
    }
    
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

    private string GetLicensesTypeJson()
    {
        string[] paths = Metadata.GetChildrenPaths("/Metadata/Casino/GameLicenses");
        StringBuilder sb = new StringBuilder();
        sb.Append("{");
        string value;

        for (int i = 0; i < paths.Length; i++)
        {
            value = this.GetMetadata(paths[i] + ".Value");
            if (!string.IsNullOrEmpty(value))
            {
                sb.AppendFormat(CultureInfo.InvariantCulture, @" ""{0}"" : ""{1}"" ", paths[i].Substring(paths[i].LastIndexOf("/") + 1).ToLowerInvariant(), value.SafeJavascriptStringEncode());
                if (i < paths.Length - 1)
                {
                    sb.Append(", ");
                }
            }
        }
        sb.Append("}");
        return sb.ToString();
    }
</script>

<div class="Popup2">

<div class="Wrapper1">
<div class="Wrapper2">

    <div class="Popup GamePopup">
        <div class="Lights">
            <a class="TurnOn"><span><%= this.GetMetadata(".Light_Off").SafeHtmlEncode()%></span></a>
            <a class="TurnOff"><span><%= this.GetMetadata(".Light_On").SafeHtmlEncode()%></span></a>
        </div>

        
        <div class="PopupContainer">
            <a class="ClosePopup" href="#" title="<%= this.GetMetadata(".Close_Tip").SafeHtmlEncode() %>">
            </a>

            <div class="TopBar">
                <div class="ModeSwitcher">
                    <input class="SwitchInput" type="radio" name="gameMode" id="btnFunMoneyMode" value="" autocomplete="off">
                    <label class="SwitchLabel OffLabel" for="btnFunMoneyMode"><%= this.GetMetadata(".Switcher_Fun").SafeHtmlEncode() %></label>
                    <input class="SwitchInput" type="radio" name="gameMode" id="btnRealMoneyMode" value="" autocomplete="off">
                    <label class="SwitchLabel OnLabel" for="btnRealMoneyMode"><%= this.GetMetadata(".Switcher_RealMoney").SafeHtmlEncode()%></label>
                </div>

                <div class="Logo"></div>

                <div class="TopLinks">
                    <a class="GameInfo" href="#" title="<%= this.GetMetadata(".TopLink_Information").SafeHtmlEncode()%>"><span><%= this.GetMetadata(".TopLink_Information").SafeHtmlEncode()%></span></a>
                    <a class="LiveChat" href="<%=this.GetMetadata(".TopLink_LiveChat_Url").SafeHtmlEncode()%>" title="<%= this.GetMetadata(".TopLink_LiveChat").SafeHtmlEncode()%>"><span><%= this.GetMetadata(".TopLink_LiveChat").SafeHtmlEncode()%></span></a>
                    <a class="Contact" href="<%= this.GetMetadata(".TopLink_ContactUs_Url").SafeHtmlEncode()%>" target="_blank" title="<%= this.GetMetadata(".TopLink_ContactUs").SafeHtmlEncode()%>"><span><%= this.GetMetadata(".TopLink_ContactUs").SafeHtmlEncode()%></span></a>
                    <a class="Support" href="<%= this.GetMetadata(".TopLink_Support_Url").SafeHtmlEncode()%>" title="<%= this.GetMetadata(".TopLink_Support").SafeHtmlEncode()%>"><span><%= this.GetMetadata(".TopLink_Support").SafeHtmlEncode()%></span></a>
                    <a class="Deposit" href="/Deposit" target="_blank" title="<%= this.GetMetadata(".TopLink_DepositMoney").SafeHtmlEncode()%>"><span><%= this.GetMetadata(".TopLink_DepositMoney").SafeHtmlEncode()%></span></a>
                </div>
            </div>
	        
	        <div class="GameArea">
                <div class="GameContainer">
                </div>
                <div class="License Container"></div>
            </div>

            <div class="BottomBar">
                
            </div>
	
        </div>
    </div>

</div>
</div>

</div>

<script type="text/javascript">
    var _isBackgroundStretchHorizontally = <%=IsBackgroundStretchHorizontally ? "true" : "false" %>;
    var _gameInPopup2Width = 0;
    var _gameInPopup2Height = 0;

    function getElementEdgeDistances(ele) {
        var paddingTop = 0;
        var paddingBottom = 0;
        var paddingLeft = 0;
        var paddingRight = 0;
        var marginTop = 0;
        var marginBottom = 0;
        var marginLeft = 0;
        var marginRight = 0;
        if (ele) {
            paddingTop = parseInt(ele.css("padding-top")) || 0;
            paddingBottom = parseInt(ele.css("padding-bottom")) || 0;
            paddingLeft = parseInt(ele.css("padding-left")) || 0;
            paddingRight = parseInt(ele.css("padding-right")) || 0;

            marginTop = parseInt(ele.css("margin-top")) || 0;
            marginBottom = parseInt(ele.css("margin-bottom")) || 0;
            marginLeft = parseInt(ele.css("margin-left")) || 0;
            marginRight = parseInt(ele.css("margin-right")) || 0;
        }
        return { "paddingTop": paddingTop, "paddingBottom": paddingBottom, "paddingLeft": paddingLeft, "paddingRight": paddingRight, "marginTop": marginTop, "marginBottom": marginBottom, "marginLeft": marginLeft, "marginRight": marginRight };
    }

    function adaptGamePopupWindowSize($iframe) {
        if (!$iframe) {
            $iframe = $("#ifmPopup2GameLoader");
        } 
        if ($iframe.length == 0)
            return;
        $('div.Popup2').height(_isBackgroundStretchHorizontally ? $(window).height() : $(document).height() + 'px');

        var popupContainer = $('div.Popup2 div.PopupContainer');
        var minGameAreaHeight = 430;        
        var windowHeight = $(window).height();
        var windowWidth = $(window).width();
        //Popup Container extra space
        var popupContainerEd = getElementEdgeDistances(popupContainer);
        
        var popupTopBar = popupContainer.find(".TopBar");
        //Top bar extra space
        var popupTopBarEd = getElementEdgeDistances(popupTopBar);
        var topBarHeldHeight = popupTopBar.outerHeight() + popupTopBarEd.marginTop + popupTopBarEd.marginBottom + popupTopBarEd.paddingTop + popupTopBarEd.paddingBottom;        

        var popupBottomBar = popupContainer.find(".BottomBar");
        //Bottom bar extra space
        var popupBottomBarEd = getElementEdgeDistances(popupBottomBar);
        var bottomBarHeight = popupBottomBar.outerHeight() + popupBottomBarEd.marginTop + popupBottomBarEd.marginBottom + popupBottomBarEd.paddingTop + popupBottomBarEd.paddingBottom;

        var gameAreaMaxHeight = windowHeight - topBarHeldHeight - bottomBarHeight - popupContainerEd.paddingTop - popupContainerEd.paddingBottom - popupContainerEd.marginTop - popupContainerEd.marginBottom - (popupContainerEd.marginTop > 50 ? 50 : popupContainerEd.marginTop < 20 ? 20 : popupContainerEd.marginTop);
        var gameAreaMaxWidth = windowWidth - popupContainerEd.paddingLeft - popupContainerEd.paddingRight;
        
        var realGameAreaHeight;
        var realGameAreaWidth;
        var temp = gameAreaMaxHeight * _gameInPopup2Width / (_gameInPopup2Height * 1.0); //temp is width;
        if (temp > gameAreaMaxWidth) {//base on width
            temp = gameAreaMaxWidth * _gameInPopup2Height / (_gameInPopup2Width * 1.0); //temp is height
            realGameAreaHeight = temp;
            realGameAreaWidth = gameAreaMaxWidth;
        }
        else {
            realGameAreaHeight = gameAreaMaxHeight;
            realGameAreaWidth = temp;
        }
        //if the height < mini height
        if (realGameAreaHeight < minGameAreaHeight) {//base on height
            realGameAreaHeight = minGameAreaHeight;
            realGameAreaWidth = realGameAreaHeight * _gameInPopup2Width / (_gameInPopup2Height * 1.0);
        }
        
        popupContainer.find('div.GameContainer').height(realGameAreaHeight);
        popupContainer.find('div.GameContainer').width(realGameAreaWidth);
        popupContainer.width(realGameAreaWidth);
        $iframe.height(realGameAreaHeight);
        $iframe.width(realGameAreaWidth);

        var popupBottomBarPrevWidth = popupBottomBar.find(".Prev").width() || 0;
        var popupBottomBarNextWidth = popupBottomBar.find(".Next").width() || 0;
        popupBottomBar.width(realGameAreaWidth - popupBottomBarPrevWidth - popupBottomBarNextWidth);
        /****************************************/
        adaptSimilarGamesCanvasSize();
        /****************************************/
        return { "width": realGameAreaWidth, "height" : realGameAreaHeight };
    }

    function adaptSimilarGamesCanvasSize()
    {
        var container = $('div.Popup2').find(".SimilarGamesCanvas");
        container.find(".SimilarGameList li.SGItem").css("margin-right", "");

        var li = container.find(".SimilarGameList li.SGItem");
        var containerWidth = container.width();
        var marginRight = parseInt(li.css("margin-right")) || 0;
        var width = marginRight + li.outerWidth();
        var count = parseInt(containerWidth / width);
        var extraWidth = containerWidth - width*count;
        if(extraWidth>0)
        {
            var temp = extraWidth/count;
            container.find(".SimilarGameList li.SGItem").css("margin-right", marginRight + temp);

            marginRight = parseInt(li.css("margin-right")) || 0;
            width = marginRight + li.outerWidth();
            var adjustWidth = containerWidth -width * count;
            if(adjustWidth > 0)
            {
                container.find(".SimilarGameList li.SGItem").css("margin-right", marginRight + Math.ceil(adjustWidth/count));
            }
        }
    }

    var gameLicenses = <%=GetLicensesTypeJson() %>;
    function __loadGame(gameID, playForFun) {
        
        <% if (Profile.IsInRole("Incomplete Profile") && SiteManager.Current.DisplayName.Equals("energycasino", StringComparison.InvariantCultureIgnoreCase))
            {%>
        if(!playForFun)
        {
            window.top.location = '<%= this.Url.RouteUrl("Profile", new { @_gurl = this.Url.RouteUrl("Deposit")}).SafeJavascriptStringEncode() %>';
            return;
        }
        <% } %>

        var overlayHeight = _isBackgroundStretchHorizontally ? $(window).height() : $(document).height();        
        var $li = $('li.GLItem[data-backgroundImage][data-gameID="' + gameID.scriptEncode() + '"]');
        var url = $li.data('backgroundImage') || $li.attr('data-backgroundImage');
        if( url != null )
            $('div.Popup2').data('backgroundImageUrl', url);

        var img = new Image();
        img.src = url;
        $('div.Popup2 a.TurnOff').trigger('click');

        $('div.Popup2').appendTo(document.body);
        $('div.Popup2').css('position', 'fixed').height(overlayHeight + 'px').addClass('ShowPopup').fadeIn(500);

        $('#btnFunMoneyMode').attr('disabled', true);
        $('#btnRealMoneyMode').attr('disabled', true);
        if (playForFun)
            $('#btnFunMoneyMode').trigger('click');
        else
            $('#btnRealMoneyMode').trigger('click');

        var url = '<%= this.Url.RouteUrl( "CasinoLobby", new { @action = "GetGameInfo" }).SafeJavascriptStringEncode() %>';
        $.getJSON(url, { gameID: gameID, playForFun: playForFun }, function (json) {
            if (!json.success) {
                switch (json.errorCode) {
                    case "-1": alert('<%= this.GetMetadata(".Error_FunModeNotAvailable").SafeJavascriptStringEncode() %>'); break;
                    case "-2": alert('<%= this.GetMetadata(".Error_AnonymousFunModeNotAvailable").SafeJavascriptStringEncode() %>'); break;
                    case "-3": alert('<%= this.GetMetadata(".Error_RealModeNotAvailable").SafeJavascriptStringEncode() %>'); break;
                    case "-4": alert('<%= this.GetMetadata(".Error_SessionTimedout").SafeJavascriptStringEncode() %>'); self.location = self.location.toString().replace("realMoney=True", "realMoney=False"); return;
                    case "-5": alert('<%= this.GetMetadata(".Error_EmailNotVerified").SafeJavascriptStringEncode() %>'); break;
                    default: break;
                }
                $('div.Popup2 a.ClosePopup').trigger("click");
                return;
            }

            if(gameLicenses[json.game.LicenseType.toLowerCase()])
            {
                $('div.Popup2 div.License').html('<%=this.GetMetadata(".GameLicense").SafeJavascriptStringEncode() %>'.format(gameLicenses[json.game.LicenseType.toLowerCase()])).show();
            }
            else
            {
                $('div.Popup2 div.License').html("").hide();
            }
            var _id = json.game.ID;
            if(json.game.Slug && json.game.Slug!=null)
                _id = json.game.Slug;
            $('div.Popup2').find("a.GameInfo").attr("href", "/OurGames/GameInfo/Index/"+_id);

            // <%-- Load the game --%>
            var $iframe = $('<iframe id="ifmPopup2GameLoader" frameborder="0" scrolling="no" allowTransparency="true"></iframe>')
                .attr('src', playForFun ? json.game.FunModeUrl : json.game.RealMoneyModeUrl);

            _gameInPopup2Width = json.game.Width;
            _gameInPopup2Height = json.game.Height;
            var size = adaptGamePopupWindowSize($iframe);
           
            $('div.Popup2 div.GameContainer').empty().append($iframe);

            // <%-- Update the switcher the game --%>
            if (json.game.FunModeUrl.length > 0) {
                $('#btnFunMoneyMode').attr('disabled', false);
                $('div.Popup2 #btnFunMoneyMode').val(json.game.FunModeUrl);
            }

            if (json.game.RealMoneyModeUrl.length > 0) {
                $('#btnRealMoneyMode').attr('disabled', false);
                $('div.Popup2 #btnRealMoneyMode').val(json.game.RealMoneyModeUrl);
            }
        });
         
        // <%-- load the similar games --%>
        url = '<%= this.Url.RouteUrl( "CasinoLobby", new { @action = "SimilarGameSliderWidget" }).SafeJavascriptStringEncode() %>';
        $('div.Popup2 div.BottomBar').load( url, { gameID : gameID, maxCount : 10 });
    }

    $(function () {
        $(window).resize(function () { adaptGamePopupWindowSize(); });
        // <%-- Close button click event --%>
        $('div.Popup2 a.ClosePopup').click(function (e) {
            e.preventDefault();

            $('#btnFunMoneyMode').attr('disabled', true);
            $('#btnRealMoneyMode').attr('disabled', true);
            $('div.Popup2 div.GameContainer').empty();
            $('div.Popup2').fadeOut(500, function () { $(this).removeClass('ShowPopup') });
            $('div.Popup2').data('backgroundImageUrl', '');
        });

        $('div.Popup2 a.TurnOff').click(function (e) {
            e.preventDefault();
            $('div.Popup2').css({'background-image': 'none','background-color':''});
            $(this).addClass('hidden');
            $('div.Lights a.TurnOn').removeClass('hidden');
        });
        $('div.Popup2 a.TurnOn').click(function (e) {
            e.preventDefault();
            var backgroundUrl = $('div.Popup2').data('backgroundImageUrl');
            if(backgroundUrl && backgroundUrl.trim()!="")
                $('div.Popup2').css({'background-image': 'url(' + backgroundUrl + ')', 'background-color':'#000000'});
            else
                $('div.Popup2').css({'background-image': 'inherit', 'background-color':'#000000'});
            $(this).addClass('hidden');
            $('div.Lights a.TurnOff').removeClass('hidden');
        })

        $('div.ModeSwitcher .SwitchLabel').click(function (e) {
            var forID = $(this).attr('for');
            var $btn = $(document.getElementById(forID));
            if (!$btn.is(':disabled')) {
                $(document.getElementById(forID)).trigger('click');
                $(this).siblings('.checked').removeClass('checked');
                $(this).addClass('checked');
            }
        });
        $('div.ModeSwitcher .SwitchInput').click(function (e) {
            var id = $(this).prop('id');
            $(this).siblings('.checked').removeClass('checked');
            $('div.ModeSwitcher .SwitchLabel[for="' + id + '"]').addClass('checked');
        });



        $('#btnFunMoneyMode').click(function (e) {
            if ($(this).val().length > 0)
                $('#ifmPopup2GameLoader').attr('src', $(this).val());
        });

        $('#btnRealMoneyMode').click(function (e) {
            if ($(this).val().length > 0)
                $('#ifmPopup2GameLoader').attr('src', $(this).val());
        });


        // <%-- Remove unnecessary controls --%>
        $('div.GameArea > div.GameBody > div.Incentive').remove();
        $('div.GameArea > div.GameBody > div.controller').remove();
    });

</script>