<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CasinoEngine.Game>" %>
<%@ Import Namespace="System.Globalization" %>
<script type="text/C#" runat="server">
    private string ID { get; set; }

    protected override void OnPreRender(EventArgs e)
    {
        this.ID = string.Format(CultureInfo.InvariantCulture, "_{0}", Guid.NewGuid().ToString("N").Truncate(6));
        base.OnPreRender(e);
    }
</script>


<div class="CasinoGameOverlay Multi" style="background-image: url(<%= this.Model.BackgroundImageUrl %>)" id="<%= this.ID %>">
    <div class="Wrapper1">
        <div class="Wrapper2">
            <div class="PopupContainer">
                <a class="ClosePopup" href="#" title="<%= this.GetMetadata(".Close_Tip").SafeHtmlEncode() %>">
                    <%= this.GetMetadata(".Close").SafeHtmlEncode() %>
                </a>
                <% Html.RenderPartial("/Casino/GameBarWidget/Widget", this.ViewData.Merge(new { Path = "/Casino/GameBarWidget/GameOpenerProperties/" })); %>
                <div class="PanelGameFrame">
                    <% Html.RenderPartial("/Casino/Hall/GameMultiOpenerWidget/Game", this.Model, this.ViewData); %>
                </div>
                <% Html.RenderPartial("/Deposit/QuickDepositWidget/QuickDepositWidget", this.ViewData.Merge(new { })); %>
            </div>
            <div class="gameNavWrapper">
                <div class="close" id="closeNavWidget<%= this.ID %>">x</div>
                <div class="gameNavWrapperInner">
                    <% Html.RenderPartial("/Casino/Hall/GameMultiOpenerWidget/GameNavWidget", this.ViewData.Merge(new { })); %>
                </div>
            </div>
        </div>
    </div>
    <%  Html.RenderPartial("/Casino/Hall/GameMultiOpenerWidget/PopupPlus", this.ViewData.Merge( new { @ContainerID= this.ID } )); %>
</div>

<script type="text/javascript">
    function gameMultiOpenerWidget(){
        var self = this;

        var container = $('#<%= this.ID %>');
        var bodyOverflow = null;

        var gameModes = { Single: 1, Double: 2, Fourth: 4 };
        var gameMode = { Current: gameModes.Single, Prev: gameModes.Single };
        var games = [];

        var addToFavText = "<%=this.GetMetadata("/Casino/Hall/GameOpenerWidget/_GameFrame_snippet.Button_AddToFav").SafeJavascriptStringEncode()%>";
        var removeFromFavText = "<%=this.GetMetadata("/Casino/Hall/GameOpenerWidget/_GameFrame_snippet.Button_RemoveFav").SafeJavascriptStringEncode()%>";

        var gameNavWidgetMultiInstance = null;
        var gameLoadedIndex = 0;

        var windowScrollTop = 0;

        self.SetGameMode = function(mode){
            gameMode.Prev = gameMode.Current;
            gameMode.Current = mode;

            setGamesCount();
            self.AdjustGameSize();
        };

        self.Container = container;
        self.AdjustGameSize = adjustGameSize;
        self.ResizeGames = resizeGames;
        self.ResetGameSize = resetGameSize;
        self.GetGameBorderSize = getGameBorderSize;
        self.GetAvaliableGameSize = getAvaliableGameSize;
        self.GetGameContainerSize = getGameContainerSize;
        self.GetIframeContainerSize = getIframeContainerSize;
        self.CalculateGameSize = calculateGameSize;
        self.ShowGameInfo = showGameInfo;
        self.GameMode = gameMode;
        self.GameModes = gameModes;
        self.IsFullScreen = false;

        init();

        function init(){

            windowScrollTop = $(window).scrollTop();
            $(window).scrollTop(0);
            //debugger;
            if(typeof($('body').attr("bk"))==="undefined"){
                bodyOverflow = $('body').css('overflow');
                $('body').attr("bk",bodyOverflow);
            }else
                bodyOverflow = $('body').attr("bk");
            $('body').css('overflow', 'hidden');

            $('body').addClass('body-multi-popup');

            games.push($('.GameLoaderWrapper:first'));

            $('.GameLoaderWrapper:first .game-menu .change-game').click(function(){
                openGameSelector(1);
            });

            $('.GameLoaderWrapper:first .game-menu .CB.CBFav').click(function(){
                if ($(this).hasClass('Actived')){
                    removeFromFav(1);
                }else{
                    addToFav(1);
                }
            });

            $('.GameLoaderWrapper:first .game-menu .CB.CBInfo').click(function(){
                self.ShowGameInfo(1);
            });

            $('.GameLoaderWrapper:first .menu-icon').click(function(){
                showGameMenu(1);
            });

            $('.GameLoaderWrapper:first .GameLoaderMenu .close').click(function(){
                hideGameMenu(1);
            });

            $(window).bind('resize', self.ResizeGames);

            var parent = container.parent();

            $('body > div.CasinoGameOverlay').remove();
            container.appendTo(document.body).fadeIn(700);

            parent.remove();

            $(document).trigger('LOAD_CASINO_POPUP_ADDON_BAR', 
                { RealMoney : <%=  this.ViewData["RealMoney"].ToString().ToLowerInvariant() %>,
                    Container: $('div.AddOnBar', container),
                    GameID: '<%= this.Model.ID.SafeJavascriptStringEncode() %>' 
                });

                $(document).trigger('POPUP_GAME_CLOSED');

                $('div.TitleBar  a.BackButton').remove();

                $('a.ClosePopup', container).click(function (e) {
                    e.preventDefault();
                    close();
                });

                $('.mode1').click(function (e) {
                    e.preventDefault();
                    self.SetGameMode(1);
                });

                $('.mode2').click(function (e) {
                    e.preventDefault();
                    // debugger;
                    self.SetGameMode(2);
                    return false;
                });
		
                $('.mode4').click(function (e) {
                    e.preventDefault();
                    self.SetGameMode(4);
                    return false;
                });

                $('#closeNavWidget<%= this.ID %>').click(function(){
                    $('.CasinoGameOverlay.Multi .GameContainer').css('visibility', 'visible');
                    $('.gameNavWrapper').hide();
                    $(".PopupsContainer .Popup.GamePopup .Close").trigger("click");
                });
                
                $('.CB.CBAddNewGame', self.Container).click(function(){
                    openGameSelector(games.length < 4 ? games.length + 1 : 4);
                });

                $('.CB.CBFullScreen', self.Container).click(function(){
                    var self=$(this);
                    EnterFullScreen2('#<%= this.ID %>',self);
                });

                $('.exit-full-screen', self.Container).click(function(){
                    ExitFullScreen();
                });

                initGameBarWidget();

                self.ResizeGames();
            }

            function EnterFullScreen2(selector,target) {
                if(typeof(target)==="undefined" || !target)return;
                var elem = $(selector),hasApply=false;
                if (elem.length == 0)
                    return;

                elem=elem.get(0);
                if (!target.hasClass("isfull")) {
                    if (elem.requestFullscreen) {
                        // This is how to go into fullscren mode in Firefox
                        elem.requestFullscreen();
                        hasApply=true;
                    }
                    else if (elem.mozRequestFullScreen) {
                        // This is how to go into fullscren mode in Firefox
                        elem.mozRequestFullScreen();
                        hasApply=true;
                    } else if (elem.webkitRequestFullscreen) {
                        // This is how to go into fullscreen mode in Chrome and Safari
                        elem.webkitRequestFullscreen();
                        hasApply=true;
                    }else if (elem.msRequestFullscreen){
                        elem.msRequestFullscreen();
                        hasApply=true;
                    }else{
                        alert("Fullscreen API is not supported");
                    }
                    if(hasApply && !target.hasClass("isfull"))target.addClass("isfull")
                }
                else {
                    if (document.cancelFullscreen) {
                        document.cancelFullscreen();
                        hasApply=true;
                    }
                    else if (document.mozCancelFullScreen) {
                        document.mozCancelFullScreen();
                        hasApply=true;
                    }
                    else if (document.webkitCancelFullScreen) {
                        document.webkitCancelFullScreen();
                        hasApply=true;
                    }
                    else if (document.msExitFullscreen) {
                        document.msExitFullscreen();
                        hasApply=true;
                    }
                    if(hasApply && target.hasClass("isfull"))target.removeClass("isfull")
                }
            }
            
            function EnterFullScreen(){
                self.IsFullScreen = true;
                self.Container.addClass('fullscreen');
                $('#gameBarWidgetIframe').hide();

                self.ResizeGames();
            }

            function ExitFullScreen(){
                self.IsFullScreen = false;
                self.Container.removeClass('fullscreen');
                $('#gameBarWidgetIframe').show();

                self.ResizeGames();
            }

            function initGameBarWidget(){
                var gameBarWidgetContainerId = $('.gamebarwidget-container', container).attr('id');

                var gameBarWidgetInstance = window['gameNavBarWidget_' + gameBarWidgetContainerId.split('_')[1]];

                if (gameBarWidgetInstance){
                    gameBarWidgetInstance.GamesShowing = GameBarWidgetGameShowing;
                    gameBarWidgetInstance.GamesHiding = GameBarWidgetGameHiding;
                    gameBarWidgetInstance.CloseGameBarOnClickAgain = true;
                    gameBarWidgetInstance.GameSelected = function(){
                        $(window).unbind('resize', self.ResizeGames);
                    };
                }
            }

            function GameBarWidgetGameShowing(){
                $('.CasinoGameOverlay.Multi .GameContainer').css('visibility', 'hidden');
                $('#gameBarWidgetIframe').height('auto');
            }

            function GameBarWidgetGameHiding(){
                $('.CasinoGameOverlay.Multi .GameContainer').css('visibility', 'visible');
                $('#gameBarWidgetIframe').css('height', '');
            }

            function close(){
                var target = $('.CB.CBFullScreen');
                if (target.hasClass("isfull")) {
                    if (document.cancelFullscreen) {
                        document.cancelFullscreen();
                    }
                    else if (document.mozCancelFullScreen) {
                        document.mozCancelFullScreen();
                    }
                    else if (document.webkitCancelFullScreen) {
                        document.webkitCancelFullScreen();
                    }
                    else if (document.msExitFullscreen) {
                        document.msExitFullscreen();
                    }
                }

                container.hide();
                $(window).unbind('resize', self.ResizeGames);
                $(document).trigger('POPUP_GAME_CLOSED');
                $("div[id^='casino-hall-popups_']").remove();
                $('body').css('overflow', bodyOverflow);
                $('body').removeClass('body-multi-popup');
                $(window).scrollTop(windowScrollTop);
                
                setTimeout(function() {container.remove();}, 1000);
            };

            function setGamesCount(){
                if (gameMode.Current < gameMode.Prev){
                    for (var i = 0; i < gameMode.Prev - gameMode.Current; i++) {
                        var game = games.pop();
                        game.remove();
                    }
                }else {
                    for (var i = 0; i < gameMode.Current - gameMode.Prev; i++) {
                        games.push(addNewGameContainer());
                    }
                }
            }

            function addNewGameContainer(){
                var gameIndex = games.length + 1;

                var gameWrapper = $('<div class="GameLoaderWrapper" />');
                gameWrapper.attr('id', 'gameWrapper_' + gameIndex);

                gameWrapper.append($('<div class="addGameContainer"/>').click(function(){
                    openGameSelector(gameIndex);
                }));

                $('#gamesHolder .GameLoaderWrapper:last').after(gameWrapper);

                return gameWrapper;
            }
            
            function openGameSelector(gameIndex){
                if (!gameNavWidgetMultiInstance && gameNavWidgetMulti){
                    gameNavWidgetMultiInstance = gameNavWidgetMulti;
                    gameNavWidgetMultiInstance.SubscribeGameSelected(gameSelectedCallback);
                }

                gameLoadedIndex = gameIndex;

                $('.CasinoGameOverlay.Multi .GameContainer').css('visibility', 'hidden');
                $('.gameNavWrapper').show();
                if(container.attr("loaded")!=="1"){
                    $(".TabItem.ActiveCat a.Button",container).trigger("click");
                    container.attr("loaded","1");
                }
            }

            function gameSelectedCallback(game){
                var realMoney = $('.GameArea', self.Container).data('real');
                
                $.post('/Casino/Hall/GetGameData',
                    { gameid: game.ID, realMoney: realMoney },
                    function(data){
                        addGameToContainer(data.Data);
                    }, "json");
            }

            function addGameToContainer(game){
                var gameIndex = gameLoadedIndex;

                var gameWrapper = $('#gameWrapper_' + gameIndex);

                if (gameWrapper.length == 0){
                    if (gameIndex < 3){
                        self.SetGameMode(2);
                    }else{
                        self.SetGameMode(4);
                    }
                    
                    gameWrapper = $('#gameWrapper_' + gameIndex);
                }

                var gameLoaderMenu = $('.GameLoaderMenu.index1').clone();
                gameLoaderMenu.attr('class', 'GameLoaderMenu index' + gameIndex);

                $('.CasinoGameOverlay.Multi .GameContainer').css('visibility', 'visible');
                gameLoaderMenu.hide();
                
                $('.game-menu .change-game', gameLoaderMenu).click(function(){
                    openGameSelector(gameIndex);
                });

                $('.game-menu .CB.CBFav', gameLoaderMenu).click(function(){
                    if ($(this).hasClass('Actived')){
                        removeFromFav(gameIndex);
                    }else{
                        addToFav(gameIndex);
                    }
                });

                $('.game-menu .CB.CBInfo', gameLoaderMenu).click(function(){
                    self.ShowGameInfo(gameIndex);
                });

                $('.game-menu .CB.CBFav', gameLoaderMenu).removeClass('Actived');
                $('.game-menu .CB.CBFav span', gameLoaderMenu).text(addToFavText);

                $('.game-menu .CB.CBInfo', gameLoaderMenu).removeClass('hidden');

                if (game.IsFavorite == true){
                    $('.game-menu .CB.CBFav', gameLoaderMenu).addClass('Actived');
                    $('.game-menu .CB.CBFav span', gameLoaderMenu).text(removeFromFavText);
                }

                if (!game.HasHelpUrl){
                    $('.game-menu .CB.CBInfo', gameLoaderMenu).addClass('hidden');
                }

                $('.close', gameLoaderMenu).click(function(){
                    hideGameMenu(gameIndex);
                });

                var menuIcon = $('<div class="menu-icon" />');
                menuIcon.click(function(){
                    showGameMenu(gameIndex);
                });

                gameWrapper.empty();

                gameWrapper.append(menuIcon);
                gameWrapper.append(gameLoaderMenu);

                var gameHolder = $('<div class="GameHolder" />');
                var gameHtml = $('<iframe scrolling="no" frameborder="0" class="GameLoaderIframe" allowtransparency="allowtransparency" />');

                gameHtml.attr('id', 'iframeGame_' + gameIndex);
                gameHtml.attr('src', game.Url);
                gameHtml.attr('data-width', game.Width);
                gameHtml.attr('data-height', game.Height);
                gameHtml.attr('data-gameid', game.ID);
                gameHtml.attr('data-slug', game.Slug);

                gameHolder.append(gameHtml);
                gameWrapper.append(gameHolder);
                gameWrapper.addClass('game-loaded');

                $('.gameNavWrapper').hide();

                self.ResizeGames();
            }

            function adjustGameSize(){
                switch (gameMode.Current) {
                    case gameModes.Single:
                        self.Container.addClass('single');
                        self.Container.removeClass('double');
                        self.Container.removeClass('fourth');
                        break;
                    case gameModes.Double:
                        self.Container.addClass('double');
                        self.Container.removeClass('single');
                        self.Container.removeClass('fourth');
                        break;
                    case gameModes.Fourth:
                        self.Container.addClass('fourth');
                        self.Container.removeClass('single');
                        self.Container.removeClass('double');
                        break;
                }

                self.ResizeGames();
            }

            function resizeGames() {
                var gameLoaderWrappers = $('.GameLoaderWrapper', container);
                var gameLoaderIframes = $('.GameLoaderIframe', container);
                var iframeContainer = $('.iframe-container', container);

                self.ResetGameSize(iframeContainer);

                var borderGameSize = self.GetGameBorderSize(gameLoaderWrappers);
                var avaliableGameSize = self.GetAvaliableGameSize(iframeContainer);
                var gameContainerSize = self.GetGameContainerSize(avaliableGameSize.width, avaliableGameSize.height, borderGameSize.width, borderGameSize.height);
                var newGameSize = self.CalculateGameSize(gameContainerSize.width, gameContainerSize.height);

                gameLoaderWrappers.width(newGameSize.width).height(newGameSize.height);
                gameLoaderIframes.width(newGameSize.width).height(newGameSize.height);

                var iframeContainerSize = self.GetIframeContainerSize(newGameSize.width, newGameSize.height, borderGameSize.width, borderGameSize.height, avaliableGameSize.occupiedHeight);

                iframeContainer.height(iframeContainerSize.height);
                iframeContainer.width(iframeContainerSize.width);
            }
            
            function resetGameSize(iframeContainer){
                iframeContainer.css('width' , '');
            }

            function getGameBorderSize(gameLoaderWrappers){
                var borderTopBottom = parseFloat(gameLoaderWrappers.css('border-top-width')) + parseFloat(gameLoaderWrappers.css('border-bottom-width'));
                borderTopBottom = !borderTopBottom ? 0 : borderTopBottom;

                var borderLeftRight = parseFloat(gameLoaderWrappers.css('border-left-width')) + parseFloat(gameLoaderWrappers.css('border-right-width'));
                borderLeftRight = !borderLeftRight ? 0 : borderLeftRight;

                return { height: borderTopBottom, width: borderLeftRight };
            }

            function getAvaliableGameSize(iframeContainer){
                if (self.IsFullScreen == true){
                    return { height: container.height(), width: iframeContainer.width(), occupiedHeight: 0 };
                }

                var controlsBottomHeight = 0; // $('.ControlBar.bottom', container).outerHeight(true);
                var addonContainerHeight = $('.AddOnBar', container).outerHeight(true);
                var gamesHolderTop = $('#gamesHolder', container).position().top;

                var occupiedHeight = gamesHolderTop + controlsBottomHeight;

                var heightExceptGame = iframeContainer.offset().top + occupiedHeight + addonContainerHeight;
                var avaliableGameHeight = container.height() - heightExceptGame;
                var containerWidth = iframeContainer.width();

                return { height: avaliableGameHeight, width: containerWidth, occupiedHeight: occupiedHeight };
            }

            function getGameContainerSize(avaliableGameWidth, avaliableGameHeight, gameBorderLeftRight, gameBorderTopBottom){
                var result = { width: 0, height: 0 };

                if (gameMode.Current == gameModes.Single){
                    result.width = avaliableGameWidth - gameBorderLeftRight;
                    result.height = avaliableGameHeight - gameBorderTopBottom;
                }else if (gameMode.Current == gameModes.Double){
                    result.width = avaliableGameWidth / 2 - 2 * gameBorderLeftRight;
                    result.height = avaliableGameHeight - gameBorderTopBottom;
                }else if (gameMode.Current == gameModes.Fourth){
                    result.width = avaliableGameWidth / 2 - 2 * gameBorderLeftRight;
                    result.height = avaliableGameHeight / 2 - 2 * gameBorderTopBottom;
                }

                return result;
            }

            function getIframeContainerSize(gameWidth, gameHeight, gameBorderLeftRight, gameBorderTopBottom, occupiedHeight){
                var result = { width: 0, height: 0 };

                var gameHeightWithBorder = gameHeight + gameBorderTopBottom;
                var gameWidthWithBorder = gameWidth + gameBorderLeftRight;

                if (gameMode.Current == gameModes.Single){
                    result.width = gameWidthWithBorder;
                    result.height = gameHeightWithBorder + occupiedHeight;
                }else if (gameMode.Current == gameModes.Double){
                    result.width = 2 * gameWidthWithBorder;
                    result.height = gameHeightWithBorder + occupiedHeight;
                }else if (gameMode.Current == gameModes.Fourth){
                    result.width = 2 * gameWidthWithBorder;
                    result.height = 2 * gameHeightWithBorder + occupiedHeight;
                }

                return result;
            }

            function calculateGameSize(containerWidth, containerHeight){
                var result = { width: 0, height: 0 };

                for (var i = 0; i < games.length; i++) {
                    var game = games[i];
                    var gameWidth = game.find('iframe').data('width');
                    var gameHeight = game.find('iframe').data('height');

                    var proportionWidthToHeight = gameWidth / gameHeight;
                    if(games.length>1){
                        proportionWidthToHeight=proportionWidthToHeight<1.33?1.33:proportionWidthToHeight;
                    }

                    var step = 0.5;

                    gameWidth = 0;
                    gameHeight = 0;

                    while (gameWidth < containerWidth && gameHeight < containerHeight) {
                        gameWidth += step;
                        gameHeight = gameWidth / proportionWidthToHeight;
                    }

                    if (result.width < gameWidth || result.height < gameHeight){
                        result.width = gameWidth;
                        result.height = gameHeight;
                    }
                }

                return result;
            }

            function addToFav(gameIndex){
                var gameId = $('#iframeGame_' + gameIndex).data('gameid');

                var url = '/Casino/Lobby/AddToFavorites';

                $.getJSON(url, { gameID : gameId }, function(){
                    $(document).trigger('GAME_ADDED_TO_FAV', gameId);
                    $('.GameLoaderMenu.index' + gameIndex + ' .game-menu .CB.CBFav').addClass('Actived').attr("title",removeFromFavText);
                    $('.GameLoaderMenu.index' + gameIndex + ' .game-menu .CB.CBFav span').text(removeFromFavText);
                });
            }

            function removeFromFav(gameIndex){
                var gameId = $('#iframeGame_' + gameIndex).data('gameid');

                var url = '/Casino/Lobby/RemoveFromFavorites';

                $.getJSON(url, { gameID : gameId }, function(){
                    $(document).trigger('GAME_REMOVE_FROM_FAV', gameId);
                    $('.GameLoaderMenu.index' + gameIndex + ' .game-menu .CB.CBFav').removeClass('Actived').attr("title",addToFavText);
                    $('.GameLoaderMenu.index' + gameIndex + ' .game-menu .CB.CBFav span').text(addToFavText);
                });
            }

            function showGameInfo(gameIndex){
                var slug = $('#iframeGame_' + gameIndex).data('slug');

                if (!slug){
                    slug = $('#iframeGame_' + gameIndex).data('gameid');
                }

                var url = '/Casino/Game/Rule/' + slug;

                window.open(url
                    , 'game_rule'
                    , 'width=300,height=200,menubar=0,toolbar=0,location=0,status=1,resizable=1,centerscreen=1'
                    );
            }

            function showGameMenu(gameIndex){
                $('#gameWrapper_' + gameIndex +' .GameLoaderMenu').show();
            }

            function hideGameMenu(gameIndex){
                $('#gameWrapper_' + gameIndex +' .GameLoaderMenu').hide();
            }
        }

        $(function () {
            var gameMOWidget = new gameMultiOpenerWidget();

            $(document).trigger('GAME_MULTI_POPUP_INITIALIZED', gameMOWidget);
        });
</script>
