<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="CasinoEngine" %>

<script type="text/C#" runat="server">
    private string ID { get; set; }

    private string PropertiesPath
    {
        get { return this.ViewData["Path"] != null ? this.ViewData["Path"].ToString() : "/Casino/GameBarWidget/Properties"; }
    }

    private string JsonUrl
    {
        get
        {
            return string.Format(System.Globalization.CultureInfo.InvariantCulture
                , "/Casino/Hall/GameData?maxNumOfNewGame={0}&maxNumOfPopularGame={1}&_={2}"
                , 0
                , this.MaxNumOfPopularGames
                , DateTime.Now.Ticks
                );
        }
    }

    private int MaxNumOfPopularGames
    {
        get
        {
            int maxNumOfPopularGames = 0;
            try
            {
                maxNumOfPopularGames = (int)this.ViewData["MaxNumOfPopularGames"];
            }
            catch
            {
                maxNumOfPopularGames = 40;
            }
            return maxNumOfPopularGames;
        }
    }
    private string PrepareCategories()
    {
        var result = new StringBuilder("[");

        var categoriesPaths = Metadata.GetChildrenPaths("/Casino/GameBarWidget/Categories");

        var arrCategories = new List<string>();

        foreach (var path in categoriesPaths)
        {
            var name = this.GetMetadata(path + "/.Name").SafeJavascriptStringEncode();
            var displayName = this.GetMetadata(path + "/.DisplayName").SafeJavascriptStringEncode();

            arrCategories.Add("{" + string.Format("name: '{0}', displayName: '{1}'", name, displayName) + "}");
        }

        result.Append(string.Join(",", arrCategories.ToArray()));

        result.Append("]");

        return result.ToString();
    }

    protected override void OnPreRender(EventArgs e)
    {
        this.ID = string.Format(System.Globalization.CultureInfo.InvariantCulture, "_{0}", Guid.NewGuid().ToString("N").Truncate(6));
        base.OnPreRender(e);
    }
</script>

<%-- Note: Please don't change class names --%>
<div id="gameBarWidgetContainer<%= ID %>" class="gamebarwidget-container">
    <div id="gameBarWidgetButtonsContainer<%= ID %>" class="gamebarwidget-buttons-container">
        <div id="gameBarWidgetButtonsContainerMain<%= ID %>" class="gamebarwidget-buttons-wrapper"></div>
        <div class="bottomMenuButtClose">
            <div id="gameBarWidgetClose<%= ID %>" class="gamebarwidget-button f-left" data-closed="true"></div>
        </div>
    </div>
    <div id="gameBarWidgetGamesHolder<%= ID %>" class="games-holder">
    </div>
</div>

<script type="text/javascript" src="/js/jquery/jquery.mousewheel.js"></script>

<script type="text/javascript">
    function log(l){
        if(!!console.log)
            console.log(l);
    }
    var GameDataManager=(function(){
        var _LogFlag='<%=Profile.IsAuthenticated?"1":"0" %>',
            JsonUrl = '<%= JsonUrl.SafeJavascriptStringEncode() %>',
            _IsLargeData = false,_DataSource = null;
        
        function updateLocalStorge(data){                 
            if(data !=null){
                _IsLargeData = false;
                _DataSource = {source:data,flag:_LogFlag};
                try{
                    localStorage.setItem("__allGameList",JSON.stringify(_DataSource));
                }catch(e){
                    _IsLargeData = true;
                }
            }
        }
        function getDataFromLocalStorge(){
            var cacheData=null;
            if(_IsLargeData)
                cacheData = _DataSource;
            else
                cacheData = JSON.parse(localStorage.getItem("__allGameList"));
            if( cacheData != null && cacheData != 'null' && cacheData.length != 0){
                if(cacheData.flag==_LogFlag){
                    return cacheData.source;
                }
            }
            return null;
        }
        function onGameLoadByJson(callback){
            if(_DataSource && _DataSource.flag==_LogFlag){
                callback(_DataSource.source);
                return;
            }
            $.getJSON(JsonUrl, function(data){
                callback(data);
                _DataSource = {source:data,flag:_LogFlag};
            });
        }
        function onGameLoadByLocalStorage(callback){
            if($(".localstorage").length>0 && $(".ie7").length == 0 &&  $(".ie8").length == 0 )   {
                try{
                    var lsData = getDataFromLocalStorge();
                    if( lsData != null && lsData != 'null' && lsData.length != 0 ){ 
                        callback(lsData);
                    }else{                        
                        $.getJSON(JsonUrl,function(data){ 
                            updateLocalStorge(data);
                            callback(data); 
                        } ); 
                    } 
                }catch(err){
                    onGameLoadByJson(callback); 
                }
            }else{
                onGameLoadByJson(callback);
            }  
        }
        function setFlagStatus(status){
            _LogFlag = status;
        }
        function getDataSource(){
            return _DataSource;
        }
        
        return{
            GameLoadByLocalStorage:onGameLoadByLocalStorage,
            SetFlag:setFlagStatus,
            GetDataSource:getDataSource,
            updateLocalStorge:updateLocalStorge
        }
    })();
    function GameNavBarWidget(){
        var self = this,o_t=-1;

        self.container = null;
        
        self.Properties = {
            jsonUrl: '<%= JsonUrl.SafeJavascriptStringEncode() %>',
            animationDuration: <%= this.GetMetadata(PropertiesPath +".AnimationDuration") %>,
            animationEasing: <%= this.GetMetadata(PropertiesPath + ".AnimationEasing") %>,
            animationProperty: <%= this.GetMetadata(PropertiesPath + ".AnimationProperty") %>,
            animationDefaultValue: <%= this.GetMetadata(PropertiesPath + ".AnimationDefaultValue") %>,
            animationValue: <%= this.GetMetadata(PropertiesPath + ".AnimationValue") %>,
            noImageThumbnailUrl: '<%= this.GetMetadata(PropertiesPath + ".NoImageThumbnailUrl") %>',
            isForGameOpenerWidget: <% = Settings.SafeParseBoolString(this.GetMetadata(PropertiesPath + ".IsForGameOpenerWidget"), true) ? "true" : "false" %>,
            gameOpenerWidgetCssUrl: '<%= this.GetMetadata(PropertiesPath + ".GameOpenerWidgetCssUrl") %>'
        };

        self.GameLoaded = null;
        self.GamesHiding = null;
        self.GamesHided = null;
        self.GamesShowing = null;
        self.GamesShowed = null;
        self.CloseGameBarOnClickAgain = false;
        self.GameSelected = null;

        self.isGamesFooterOpened = false;

        self.hideGames = function (){
            if (self.GamesHiding){
                self.GamesHiding();
            }

            var animationProperty = {};
            animationProperty[self.Properties.animationProperty] = self.Properties.animationDefaultValue;

            self.container.animate(
                animationProperty,
                { 
                    duration: self.Properties.animationDuration,
                    easing: self.Properties.animationEasing, 
                    complete: function () { 
                        self.container.find('#gameBarWidgetClose<%= ID %>').hide();

                        if(self.GamesHided){
                            self.GamesHided();
                        }
                        $("#gamesHolder").css("top",o_t);
                        self.container.find('.gamebarwidgetMenuButt.gameBarWidget-butt-selected').removeClass('gameBarWidget-butt-selected');
                    }
                });

            self.isGamesFooterOpened = false;
        };

            self.showGames = function (){
                if (self.GamesShowing){
                    self.GamesShowing();
                }
                if(o_t===-1)
                    o_t = $("#gamesHolder").css("top");
                $("#gamesHolder").css("top","-9999px");
                var animationProperty = {};
                animationProperty[self.Properties.animationProperty] = self.Properties.animationValue;

                self.container.animate(
                    animationProperty,
                    { 
                        duration: self.Properties.animationDuration, 
                        easing: self.Properties.animationEasing, 
                        complete: function () { 
                            self.container.find('#gameBarWidgetClose<%= ID %>').show();
                        
                            if(self.GamesShowed){
                                self.GamesShowed();
                            }
                        }
                    });

                self.isGamesFooterOpened = true;
            };
         var categories = <%= PrepareCategories() %>;
                init();

                function init(){
                    $(function () {
                        //setTimeout(function(){GameDataManager.GameLoadByLocalStorage(onGameLoad)},100);
                        setTimeout(function(){
                            initControls();
                            //the bar display,then request games data
                            GameDataManager.GameLoadByLocalStorage(onGameLoad);
                        },100);
                        
                       
                        $(document).bind('mousewheel', function (event, delta) {
                            var element = $(event.target);

                            var parentClass = element.parent().attr('class');
                            var parentParentClass = element.parent().parent().attr('class');

                            if (checkMouseWheelForGamesContainers(parentClass) ||
                                checkMouseWheelForGamesContainers(parentParentClass)) {
                                scrollGamesContainers(delta);

                                event.preventDefault(event);

                                return false;
                            }
                        });

                        $(".CasinoGameOverlay.Multi").bind('click', function (event) {
                            if (self.isGamesFooterOpened == true && !event.isTrigger) {
                                self.hideGames();
                            }
                        });
                    });
                }
        function initControls(){
            self.container = $('#gameBarWidgetContainer<%= ID %>');

            if (self.Properties.isForGameOpenerWidget){
                var newElement = $('#gameBarWidgetContainer<%= ID %>');
                //$('#gameBarWidgetContainer<%= ID %>').remove();
                $('#gameBarWidgetIframe').css('visibility','hidden');

                function setContent(content){
                    var c = $(content);
                    c.find('html').attr('class', 'gameBarWidgetIframeHtml');
                    c.find('head').append('<link rel="stylesheet" type="text/css" href="' + self.Properties.gameOpenerWidgetCssUrl + '" />');
                    c.find('body').append(newElement);
                   
                    log(  $("#gameBarWidgetButtonsContainerMain<%=ID%>",c));
                }

                var iframe = document.getElementById('gameBarWidgetIframe');
                if($.browser.msie || $.browser.safari){  //IE
                    try{
                        iframe.contentWindow.document;
                        setContent(iframe.contentWindow.document)
                    }catch(e){
                        $(iframe).bind("load",function(){
                            if(typeof console != 'undefined') {
                                log(iframe.contentWindow.document.location);
                            } 
                            setContent(iframe.contentWindow.document);
                            iframe.onload = null;
                        });
                        iframe.src = "javascript:void((function(){document.open();document.domain='"+ document.domain + "';document.close()})())";
                    }
                }else{
                    setContent($(iframe).contents());
                }

                
             

                self.container = newElement;  
                setTimeout(function() {$('#gameBarWidgetIframe').css('visibility','visible');}, 2000); 
            }

            log('before init');
            initGameCategories();
      
            self.container.css('display', 'block');

            initDomEventsBefore();

            
           
        }
        function initDomEventsBefore(){
             self.container.find('#gameBarWidgetClose<%= ID %>').click(function (e) {
                e.preventDefault();

                if (self.isGamesFooterOpened == true) {
                    self.hideGames();
                }

                return false;
             });
            
            self.container.find('.gamebarwidgetMenuButt').click(function (e) {
                var element = $(this);

                var containerId = element.attr('data-containerId');

                if (containerId) {
                    self.container.find('.gameBarWidget-games-container.current').removeClass('current');
                    self.container.find('#' + containerId).addClass('current');
                }

                if(element.hasClass("gameBarWidget-butt-selected")){
                    element.removeClass('gameBarWidget-butt-selected');
                    self.hideGames();
                }else{
                    self.container.find('.gamebarwidgetMenuButt.gameBarWidget-butt-selected').removeClass('gameBarWidget-butt-selected');
                    element.addClass('gameBarWidget-butt-selected');
                    self.showGames();
                }
            });
        }
        function onGameLoad(data) {
            initGames(data);
            setWidthForGamesContainers();
            log(self.container);
            log(self.container.find('.gamebarwidget-game-title'));
            self.container.find('.gamebarwidget-game-title').click(function (event) {
                event.preventDefault();

                var gameId = $(this).attr('gameid');

                if (self.GameSelected){
                    self.GameSelected(self);
                }

                _openCasinoGame(gameId, <%= Profile.IsAuthenticated ? "true" : "false"%>);

                return false;
            });

            self.container.find('#gameBarWidgetGamesHolder<%= ID %>').click(function (event) {
                    event.preventDefault();
                    return false;
                });

            if (self.GameLoaded){
                self.GameLoaded();
            }
        }

            function initGameCategories() {
                var buttonsContainer =self.container.find('.gamebarwidget-buttons-wrapper'); //self.container.find('#gameBarWidgetButtonsContainerMain<%= ID %>');
                log(self);
                log(self.container);
                log(buttonsContainer.length);
                log(self.container.find('.gamebarwidget-buttons-wrapper'));
                log(' init...');

            for (var categoryIndex = 0; categoryIndex < categories.length; categoryIndex++) {
                var currentCategory = categories[categoryIndex];

                var button = $('<div class="gamebarwidgetMenuButt" />')
                    .attr('data-containerid', 'gamesFooter' + currentCategory.name + 'Container<%= ID %>')
                    .append($('<div class="gamebarwidget-button f-left"/>').addClass(currentCategory.name).attr('id', 'gameBarWidget-' + currentCategory.name + '<%= ID %>'))
                    .append($('<div class="f-left text"/>').text(currentCategory.displayName))
                    .attr("title",currentCategory.displayName);
                buttonsContainer.append(button);

 

                var categoryContainer = $('<div id="gamesFooter' + currentCategory.name + 'Container<%= ID %>" class="gameBarWidget-games-container '+currentCategory.name+'">'
                    +'<div style="padding:20px"><img src="/images/ajax-loader.gif" /></div>'
                    +'</div>');

                self.container.find('.games-holder').append(categoryContainer);
      
            }

                log('after init');
        }
        function initGames(data){
            log('initGames:'+data);
            log(categories);
            for (var categoryIndex = 0; categoryIndex < categories.length; categoryIndex++) {
                var currentCategory = categories[categoryIndex];
                var categoryItems = data[currentCategory.name.toLowerCase()];
                var categoryContainer = self.container.find('#gamesFooter' + currentCategory.name + 'Container<%= ID %>');
                log(self.container);
                log(categoryItems);
                log(categoryContainer);
                categoryContainer.html("");  //clear loading 
                if (currentCategory.name.toLowerCase() == 'favourites') {
                    addFavourites(data, categoryContainer);
                } else if (categoryItems) {
                    for (var i = 0; i < categoryItems.length; i++) {
                        addGameToContainer(categoryContainer, categoryItems[i]);
                    }
                }
            }

            if (!($(document).data("events")["GAME_ADDED_TO_FAV"])) {
                $(document).on( 'GAME_ADDED_TO_FAV', function(e, gid){ 
                    //removeFavGame(gid);
                    if($.inArray( gid, data['favorites']) == -1)
                        data['favorites'].push(gid.toString());
                    addFavourites(data, self.container.find('#gamesFooterFavouritesContainer<%= ID %>'));
                    setWidthForGamesContainers();

                    setTimeout(function(){ GameDataManager.updateLocalStorge(data)},1000);
                });
            }

            if (!($(document).data("events")["GAME_REMOVE_FROM_FAV"])) {
                $(document).on( 'GAME_REMOVE_FROM_FAV', function(e, gid){ 
                    removeFavGame(gid); 
                    addFavourites(data, self.container.find('#gamesFooterFavouritesContainer<%= ID %>'));
                    setWidthForGamesContainers();
                    setTimeout(function(){ GameDataManager.updateLocalStorge(data)},1000);
                });
            }

            function removeFavGame(gid){
                var favorites = data['favorites'];
                for( var i = favorites.length - 1; i >= 0; i--){
                    if( favorites[i] == gid )
                        favorites.splice(i, 1);
                }
            }
        }

        function addFavourites(data, favoritesContainer){
            var favorites = data['favorites'];
            var favoritesArray = {};
            favoritesContainer.html('');
            for (var category in data) {
                for (var gameIndex = 0; gameIndex < data[category].length; gameIndex++) {
                    for (var favoriteIndex = 0; favoriteIndex < favorites.length; favoriteIndex++) {
                        if (data[category][gameIndex].ID == favorites[favoriteIndex] && !favoritesArray[favorites[favoriteIndex]]) {
                            favoritesArray[favorites[favoriteIndex]] = true;

                            addGameToContainer(favoritesContainer, data[category][gameIndex]);
                            //console.log(favorites[favoriteIndex]);
                            break;
                        }
                    }
                }
            }
          
        }

        function addGameToContainer(container, game) {
            var thumbnailUrl = game.I ? game.I : self.Properties.noImageThumbnailUrl;

            container.append(
            $('<div class="gamebarwidget-game-title" />').attr('gameid', game.ID).attr('title', game.G)
                .append($('<img class="gameBarWidget-games-img" />').attr('title', game.G).attr('src', thumbnailUrl))
                .append($('<div class="gameTileName" />').text(game.G))
                );
        }

        function scrollGamesContainers(delta) {
            if (self.isGamesFooterAnimated) {
                return;
            }

            var documentWidth = $(window).width();
            var gameTitleWidth = parseInt(self.container.find('.gamebarwidget-game-title').outerWidth(true));

            var currentContainer = self.container.find('.gameBarWidget-games-container.current');
            var marginLeft = parseInt(currentContainer.css('margin-left'));
            var gamesCount = currentContainer.find('.gamebarwidget-game-title').length;

            var rightMargin = 50;

            if ((delta < 0 && (gamesCount * gameTitleWidth + rightMargin + marginLeft) < documentWidth) ||
                (delta > 0 && marginLeft >= 0)) {
                return;
            } else {
                isGamesFooterAnimated = true;

                if (delta < 0) {
                    currentContainer.animate(
                        { 'marginLeft': marginLeft + (-2 * gameTitleWidth) },
                        { 
                            duration: self.Properties.animationDuration, 
                            easing: 'linear', 
                            complete: function () { self.isGamesFooterAnimated = false; }
                        });
                } else {
                    var newMargin = marginLeft + (2 * gameTitleWidth);

                    newMargin = newMargin > 0 ? 0 : newMargin;

                    currentContainer.animate(
                        { 'marginLeft': newMargin },
                        { 
                            duration: self.Properties.animationDuration, 
                            easing: 'linear', 
                            complete: function () { self.isGamesFooterAnimated = false; } 
                        });
                }
            }
        }

        function checkMouseWheelForGamesContainers(text) {
            if (!text) {
                return;
            }

            var arr = ['gamebarwidget-game-title', 'gameBarWidget-games-container current', 'gamebarwidget-container'];

            for (var i = 0; i < arr.length; i++) {
                if (arr[i].indexOf(text) >= 0) {
                    return true;
                }
            }

            return false;
        }

        function setWidthForGamesContainers() {
            var gameTitleWidth = parseInt(self.container.find('.gamebarwidget-game-title').outerWidth(true));

            var gamesContainers = self.container.find('.gameBarWidget-games-container');
            var currentContainer = null;

            var rightMargin = 50;

            for (var i = 0; i < gamesContainers.length; i++) {
                currentContainer = $(gamesContainers[i]);

                var gamesCount = currentContainer.find('.gamebarwidget-game-title').length;

                currentContainer.width(gamesCount * gameTitleWidth + rightMargin);
            }
            $(window).trigger("resize");
        }
    }

    window.gameNavBarWidget<%= ID %> = new GameNavBarWidget();
</script>
