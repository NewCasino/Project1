<%@ Page Language="C#" PageTemplate="/Casino/CasinoMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>

<script type="text/C#" runat="server">
    private string GetLoggedInHtml() {
        if (!Profile.IsAuthenticated)
            return string.Empty;
        return this.GetMetadata(".LoggedInHtml").HtmlEncodeSpecialCharactors();
    }
    private string GetCategory() {
        string requestPath = Request.RawUrl;
        if (requestPath.Contains("/Index/")) {
            string category = requestPath.Substring(requestPath.IndexOf("/Index/") + 7);
            string categoryName = category.Replace("_", " ");
            return "<li class=\"BreadItem BreadCurrent\" role=\"menuitem\" itemtype=\"http://data-vocabulary.org/Breadcrumb\" itemscope=\"itemscope\"><a class=\"BreadLink url\" href=\"/Casino/Hall/Index/" + category + "\" itemprop=\"url\" title=\"" + categoryName + "\"><span itemprop = \"title\" >" + categoryName + "</ span ></ a ></ li >";
        } else
            return string.Empty;
    }
    private string isFinal() {
        string requestPath = Request.RawUrl;
        if (requestPath.Contains("/Index/")) return "";
        else return " BreadCurrent";
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

<div class="Breadcrumbs" role="navigation">
    <ul class="BreadMenu Container" role="menu">
        <li class="BreadItem" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
            <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Title") %>">
                <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Name") %></span>
            </a>
        </li>
        <li class="BreadItem <%=isFinal()%>" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
            <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/Casino/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/Casino/.Title") %>">
                <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/Casino/.Name") %></span>
            </a>
        </li>
        <%=GetCategory()%>
    </ul>
</div>

<div class="Framework" id="framework">

    <div class="Zone Container Intro AllSlidersContainer">
        <div class="sliderContainer">
            <% Html.RenderPartial("/Components/Slider", this.ViewData.Merge(new { @SliderPath = "/Casino/Hall/Slider" })); %> 
            <div class="HomeWidget">
                <% if (!Profile.IsAuthenticated) {
                    Html.RenderPartial("/QuickRegister/RegisterWidget");
                } else { 
                    Html.RenderPartial("/Home/DepositWidget");
                } %>
            </div>
        </div>
        <div class="Container InlineGameBox">
            <div id="casino-inline-game-container"></div>
        </div>
        <div class="SliderButtons">    
            <%=this.GetMetadata(".Banner_Controller")%>
        </div>
    </div>

    <main class="MainContent">

        <h1 class="CasinoPageTitle"><%= this.GetMetadata(".Header").SafeHtmlEncode() %></h1>

        <% Html.RenderPartial("GameNavWidget/Main", this.ViewData.Merge( new {@InitialSliderCategoryCount = "3" } )); %>

        <% Html.RenderPartial("GameMultiOpenerWidget/Main", this.ViewData.Merge(new { })); %>
    
    </main>

    <aside class="Zone Container ExtraWidgets">
        <div class="LiveScoreWidget Column">
            <% Html.RenderPartial("/Casino/Hall/LiveScores"); %>
        </div>
        <div class="GamesWidgets Column">
            <div class="JackpotWidget Column">
                <% Html.RenderAction("JackpotWidget", new { @currency = "EUR" }); %>
            </div>
            <div class="RecentWinnersWidget Column">
                <% Html.RenderPartial("../Lobby/RecentWinnersWidget", this.ViewData.Merge(new { })); %>
            </div>
        </div>
    </aside>
    
</div>

<ui:MinifiedJavascriptControl runat="server">
    <script type="text/javascript">
        jQuery('#container').addClass('CasinoPage');
        jQuery('.inner').removeClass('PageBox').addClass('CasinoContent');
    
        function ChangeCategory(el){
    //        var activeCat = $('li.ActiveCat').find('.CatText').html();
                var activeCat = el.find('.CatText').html();
                $('.GamesContainerTitle').html(activeCat);
            }
        $(function () {
            /*$('.GamesCategoriesWrap').wrap('<div class="AllGamesBox"></div>');
            $('.GamesContainer').insertAfter('.GamesCategoriesWrap');
            $('.EgtJackpotBar').insertAfter('.GamesContHeader');*/
    
            $(document).on('INLINE_GAME_OPENED', function (evt, data) {
                $('div.Main > div.GeneralSlider').hide();
                window.scrollTo(0, 0);
            });
            $(document).bind('INLINE_GAME_CLOSED', function () {
                $('div.Main > div.GeneralSlider').show();
            });
            $(document).bind('GAME_TO_BE_OPENED', function () {
                $('div.Main > div.GeneralSlider').show();
            });
            
            //ChangeCategory();
            $('a.TabLink').on('click',function(el){
                var el = $(this);
                ChangeCategory(el);
            });
    
         $('#close-Casinoslider').on('click', function(e){
            e.preventDefault();
            $('.SliderCol').slideUp("500");
            $('#show-Casinoslider').removeClass('hidden');
            $('#close-Casinoslider').addClass('hidden');
        });
        $('#show-Casinoslider').on('click', function(e){
            e.preventDefault();
            $('.SliderCol').slideDown("500");
            $('#show-Casinoslider').addClass('hidden');
            $('#close-Casinoslider').removeClass('hidden');
        });
                 
    }); 
    
    setTimeout(function(){
     //   $(".PopupsContainer").appendTo($(".GamesContainer"));
    //    $(".PopupsContainer").remove();
    
        $('.AddFav a.GOLink').on('click', function(evt){
            evt.preventDefault();
            //console.log( $(this).parents('.GLItem').find('a.GameThumb span.GTfav') );
            var fav= $(this).parents('.GLItem').find('span.GTfav'); 
            if (fav.is( ".Hidden" )) {
                fav.removeClass('Hidden');
            }
            else fav.addClass('Hidden');
        });
    
    },1000);
        //new gaming window
        $(document).on('GAME_MULTI_POPUP_INITIALIZED', function (event, gameMOWidget) {
            // $("<li class='CB CBClose'></li>").insertBefore(".CasinoGameOverlay.Multi li.CBBack").append($(".CasinoGameOverlay.Multi .ClosePopup").clone().append("<span class='icon'></span>"));
            $(".CasinoGameOverlay.Multi li.CBFullScreen").insertAfter(".CasinoGameOverlay.Multi .CBAddNewGame");
             $('.CasinoGameOverlay.Multi').find('li.CBBack').find(".BackButton").click(function () {
                $(".PopupContainer>a.ClosePopup").trigger("click");
            });
            if ($("#txtQuickDepositAmount").length == 1 && $("li.CBQuickDeposit .customCover").length == 0) {
                $("<div class='customCover'><span class='icon'>+</span><span class='label'><%=this.GetMetadata(".QuicklyDeposit").SafeJavascriptStringEncode() %></span></div>").appendTo("li.CBQuickDeposit").click(function () {
                    $("li.CBQuickDeposit").addClass("open");
                });
            }
            
            var gameBarWidgetContainerId = $('.gamebarwidget-container', gameMOWidget.Container).attr('id');
    
            var gameBarWidgetInstance = window['gameNavBarWidget_' + gameBarWidgetContainerId.split('_')[1]];
    
            gameBarWidgetInstance.GamesShowing = function () {
                $('#gameBarWidgetIframe', gameMOWidget.Container).css('width', '');
                $('.gamebarwidget-buttons-container', gameBarWidgetInstance.container).css('height', '100%');
    
                gameBarWidgetInstance.Properties.animationValue = $('.iframe-container', gameMOWidget.Container).width();
    
                setGamesBarCentered(gameBarWidgetInstance);
            };
    
            gameBarWidgetInstance.GamesShowed = function () {
                $('#gameBarWidgetIframe', gameMOWidget.Container).attr('data-visible', 'true');
            };
    
            gameBarWidgetInstance.GamesHided = function () {
                var buttonsWidth = $('.gamebarwidget-buttons-container', gameBarWidgetInstance.container).width();
                $('.gamebarwidget-buttons-container', gameBarWidgetInstance.container).css('height', '');
                $('#gameBarWidgetIframe', gameMOWidget.Container).width(buttonsWidth);
    
                $('#gameBarWidgetIframe', gameMOWidget.Container).attr('data-visible', 'false');
            };
    
            gameBarWidgetInstance.GameLoaded = function () {
                $('.games-holder > div', gameBarWidgetInstance.container).css('width', '');
                $('#gameBarWidgetIframe', gameMOWidget.Container).width($('#gamesHolder', gameMOWidget.Container).css('left'));
                $('#gameBarWidgetIframe', gameMOWidget.Container).attr('data-visible', 'false');
                $('#gameBarWidgetIframe', gameMOWidget.Container).show();
            };
    
            gameMOWidget.GetAvaliableGameSize = function (iframeContainer) {
                if (gameMOWidget.IsFullScreen == true) {
                    return { height: gameMOWidget.Container.height(), width: iframeContainer.width(), occupiedHeight: 0 };
                }
    
                var controlsBottomHeight = 0;// $('.ControlBar.bottom', gameMOWidget.Container).outerHeight(true);
                var addonContainerHeight = $('.AddOnBar', gameMOWidget.Container).outerHeight(true);
                var gamesHolderTop = $('#gamesHolder', gameMOWidget.Container).position().top;
                var gamesHolderLeft = $('#gamesHolder', gameMOWidget.Container).position().left;
                var controlsRightWidth = 0;
    
                if ($('.ControlBar.right', gameMOWidget.Container).css('display') != 'none') {
                    controlsRightWidth = $('.ControlBar.right', gameMOWidget.Container).outerWidth(true);
                }
    
                var occupiedHeight = gamesHolderTop + controlsBottomHeight + addonContainerHeight;
                
                var heightExceptGame = iframeContainer.offset().top + occupiedHeight;
                var avaliableGameHeight = gameMOWidget.Container.height() - heightExceptGame;
    
                var paddingLeft = parseFloat($('.PopupContainer', gameMOWidget.Container).css('padding-left'));
                paddingLeft = !isNaN(paddingLeft) ? paddingLeft : 0;
                var paddingRight = parseFloat($('.PopupContainer', gameMOWidget.Container).css('padding-right'));
                paddingRight = !isNaN(paddingRight) ? paddingRight : 0;
    
                var containerWidth = iframeContainer.width() - controlsRightWidth - gamesHolderLeft -
                    paddingLeft - paddingRight;
    
                return { height: avaliableGameHeight, width: containerWidth, occupiedHeight: occupiedHeight };
            };
    
            gameMOWidget.GetIframeContainerSize = function (gameWidth, gameHeight, gameBorderLeftRight, gameBorderTopBottom, occupiedHeight) {
                var result = { width: 0, height: 0 };
    
                var gameHeightWithBorder = gameHeight + gameBorderTopBottom;
                var gameWidthWithBorder = gameWidth + gameBorderLeftRight;
                var gamesHolderLeft = $('#gamesHolder', gameMOWidget.Container).position().left;
    
                if (gameMOWidget.GameMode.Current == gameMOWidget.GameModes.Single) {
                    result.width = gameWidthWithBorder + gamesHolderLeft;
                    result.height = gameHeightWithBorder + occupiedHeight;
    
                    $('.ControlBar.bottom').width(gameWidthWithBorder);
                } else if (gameMOWidget.GameMode.Current == gameMOWidget.GameModes.Double) {
                    result.width = 2 * gameWidthWithBorder + gamesHolderLeft;
                    result.height = gameHeightWithBorder + occupiedHeight;
    
                    $('.ControlBar.bottom').width(2 * gameWidthWithBorder);
                } else if (gameMOWidget.GameMode.Current == gameMOWidget.GameModes.Fourth) {
                    result.width = 2 * gameWidthWithBorder + gamesHolderLeft;
                    result.height = 2 * gameHeightWithBorder + occupiedHeight;
    
                    $('.ControlBar.bottom').width(2 * gameWidthWithBorder);
                }
    
                var buttonsWidth = $('.gamebarwidget-buttons-container', gameBarWidgetInstance.container).width();
                var paddingLeftRight = parseFloat($('.games-holder', gameBarWidgetInstance.container).css('padding-left')) +
                    parseFloat($('.games-holder', gameBarWidgetInstance.container).css('padding-right'));
                var paddingTopBottom = parseFloat($('.games-holder', gameBarWidgetInstance.container).css('padding-top')) +
                    parseFloat($('.games-holder', gameBarWidgetInstance.container).css('padding-bottom'));
    
                $('.games-holder', gameBarWidgetInstance.container).width(Math.floor(result.width - buttonsWidth) - paddingLeftRight);
                $('.games-holder', gameBarWidgetInstance.container).height(result.height - paddingTopBottom);
    
                if ($('#gameBarWidgetIframe', gameMOWidget.Container).attr('data-visible') == "true") {
                    $('#gameBarWidgetIframe', gameMOWidget.Container).width(result.width);
                    gameBarWidgetInstance.container.width(result.width);
                }
    
                setGamesBarCentered(gameBarWidgetInstance);
    
                return result;
            };
    
            gameMOWidget.ResizeGames();
        });
    
        function setGamesBarCentered(gameBarWidgetInstance) {
            var containerWidth = $('.games-holder', gameBarWidgetInstance.container).width();
            var gameThumbWidth = $($('.games-holder .gamebarwidget-game-title', gameBarWidgetInstance.container)[0]).outerWidth(true);
    
            var gamesCountInOneLine = Math.floor(containerWidth / gameThumbWidth);
    
            var width = gamesCountInOneLine * gameThumbWidth;
    
            $('.games-holder .gameBarWidget-games-container', gameBarWidgetInstance.container).width(width);
        }
    </script>
</ui:MinifiedJavascriptControl>
</asp:Content>