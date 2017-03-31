<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="System.Globalization" %>
<script type="text/C#" runat="server">

    private string AvoidCloseButtonOverlappingGame
    {
        get
        {
            if (this.GetMetadata(".Button_Close_Avoid_Overlapping_Game").ToLowerInvariant() != "yes")
            {
                return "false";
            }
            return "true";
        }
    }    
    private string ID { get; set; }

    protected override void OnPreRender(EventArgs e)
    {
        this.ID = string.Format(CultureInfo.InvariantCulture, "_{0}", Guid.NewGuid().ToString("N").Truncate(6));
        base.OnPreRender(e);
    }
</script>

<div class="LiveCasinoTableOverlay" id="<%= this.ID %>" style="display:none;">
    <div class="LiveCasinoPopupContainer">
        <a class="ClosePopup" href="#" title="<%= this.GetMetadata(".Close_Tip").SafeHtmlEncode() %>">
            <%= this.GetMetadata(".Close").SafeHtmlEncode() %>
        </a>
        
        <div class="LiveCasinoPopupTableContainer">
        </div>

        <div class="ControlBar">
			<ul class="ControllerButtons">
			    <li class="CB CBQuickDeposit"></li>
                <li class="CB CBFullScreen">
				    <a class="Button" href="javascript:void(0)" title="<%= this.GetMetadata(".Button_FullScreen").SafeHtmlEncode() %>">
					    <span class="InfoIcon FullScreen"></span>
					    <span><%= this.GetMetadata(".Button_FullScreen").SafeHtmlEncode() %></span>
				    </a>
			    </li>
			    <li class="CB CBFav ">
				    <a class="Button" href="javascript:void(0)" title="<%= this.GetMetadata(".Button_AddToFav").SafeHtmlEncode() %>">
					    <span class="InfoIcon AddToFav"></span>
					    <span><%= this.GetMetadata(".Button_AddToFav").SafeHtmlEncode() %></span>
				    </a>
			    </li>
            </ul>
            <% Html.RenderPartial("/Deposit/QuickDepositWidget/QuickDepositWidget", this.ViewData.Merge(new { RealMoney = true })); %>
        </div>
    </div>
</div>

<script type="text/javascript">
    function LiveCasinoTableOpenerWidget(){
        var self = this;
        var gameId;

        var overlay = $('#<%= this.ID %>');
        var container = $('.LiveCasinoPopupTableContainer');
        var controlBar = $('.ControlBar');
        var fullscreenButton = $('.ControllerButtons .CB.CBFullScreen');

        var fullScreenText = "<%=this.GetMetadata(".Button_FullScreen").SafeJavascriptStringEncode()%>";
        var exitFullScreenText = "<%=this.GetMetadata(".Button_ExitFullScreen").SafeJavascriptStringEncode()%>";

        var closeAvoidOverlappingGame = <%= AvoidCloseButtonOverlappingGame %>;

        var $iframe;

        self.OpenTable = function (game) {
            gameId = game.ID;
            $('.ControllerButtons .CB.CBFav .Button').data('gameId', game.ID);

            var containerInline = $('.LiveCasinoInlineTableContainer');
            if (containerInline != null) {
                var $iframePopup = $('<iframe>', {
                    src: '/LiveCasino/Hall/Start?tableID=' + game.ID,
                    id: 'LiveCasinoPopupTableFrame',
                    frameborder: 0,
                    scrolling: 'auto',
                });

                $(containerInline).empty();
                $iframePopup.appendTo(containerInline);
                $iframePopup.width($iframePopup.width()).height($iframePopup.height());
                
                $iframePopup.detach();
                container.append($iframePopup);
                self.Resize();
            }
            
            $(window).bind('resize', self.Resize);
            $(document).trigger('LIVECASINO_TABLE_POPUP_GAME_LOADED', gameId);
        };

        $('a.ClosePopup').click(function (e) {
            e.preventDefault();
            if (fullscreenButton.hasClass("isfull")) {
                switchFullScreen();
            }
            $('.LiveCasinoTableOverlay').hide();
            container.empty();

            $(window).unbind('resize', self.Resize);
            $(document).trigger('LIVECASINO_TABLE_POPUP_CLOSED');
        });

        $('.CB.CBFullScreen').click(function () {
            switchFullScreen();
        });

        self.Resize = function () {
            $iframe = $('.LiveCasinoPopupTableContainer iframe');
            if ($iframe.length > 0) {
                var controlBarHeight = (controlBar.height() === 0) ? 45 : controlBar.height();
                var controlCloseWidth = ($('.ClosePopup').width() === 0) ? 80 : $('.ClosePopup').width()*1.5;

                var windowH = $(window).height() - controlBarHeight;   // returns height of browser viewport
                var windowW = $(window).width();   // returns width of browser viewport
                if (closeAvoidOverlappingGame)
                    windowW = $(window).width() - controlCloseWidth*2;   // Adjustment
                container.width(windowW).height(windowH);

                var finalHeight = container.height();
                var finalWidth = container.height() * $iframe.width() / $iframe.height();
                if (finalWidth > windowW) {
                    finalHeight = container.width() * $iframe.height() / $iframe.width();
                    finalWidth = container.width();
                }
                if (!finalWidth) {
                    finalWidth = '100%';
                }
                $iframe.height(finalHeight);
                $iframe.width(finalWidth);
                controlBar.width(finalWidth);
            }
        };

        function switchFullScreen() {
            if (fullscreenButton.hasClass("isfull")) {
                fullscreenButton.addClass('Actived');
                fullscreenButton.find('span').text(fullScreenText);
                fullscreenButton.find('.Button').attr('title', fullScreenText);
            } else {
                fullscreenButton.removeClass('Actived');
                fullscreenButton.find('span').text(exitFullScreenText);
                fullscreenButton.find('.Button').attr('title', exitFullScreenText);
            }

            EnterFullScreen('#<%= this.ID %>', fullscreenButton);
        }

        function EnterFullScreen(selector, target) {
            if (typeof (target) === "undefined" || !target) return;
            var elem = $(selector), hasApply = false;
            if (elem.length == 0)
                return;

            elem = elem.get(0);
            if (!target.hasClass("isfull")) {
                if (elem.requestFullscreen) {
                    // This is how to go into fullscren mode in Firefox
                    elem.requestFullscreen();
                    hasApply = true;
                }
                else if (elem.mozRequestFullScreen) {
                    // This is how to go into fullscren mode in Firefox
                    elem.mozRequestFullScreen();
                    hasApply = true;
                } else if (elem.webkitRequestFullscreen) {
                    // This is how to go into fullscreen mode in Chrome and Safari
                    elem.webkitRequestFullscreen();
                    hasApply = true;
                } else if (elem.msRequestFullscreen) {
                    elem.msRequestFullscreen();
                    hasApply = true;
                } else {
                    alert("Sorry, Fullscreen is not supported in your browser");
                }
                if (hasApply && !target.hasClass("isfull")) target.addClass("isfull");
            }
            else {
                if (document.cancelFullscreen) {
                    document.cancelFullscreen();
                    hasApply = true;
                }
                else if (document.mozCancelFullScreen) {
                    document.mozCancelFullScreen();
                    hasApply = true;
                }
                else if (document.webkitCancelFullScreen) {
                    document.webkitCancelFullScreen();
                    hasApply = true;
                }
                else if (document.msExitFullscreen) {
                    document.msExitFullscreen();
                    hasApply = true;
                }
                if (hasApply && target.hasClass("isfull")) target.removeClass("isfull");
            }
        }
    }


    var liveCasinoTableOpenerWidget = null;

    $(function () {
        liveCasinoTableOpenerWidget = new LiveCasinoTableOpenerWidget();

        $(document).trigger('LIVECASINO_TABLE_POPUP_INITIALIZED', liveCasinoTableOpenerWidget);
    });
</script>
