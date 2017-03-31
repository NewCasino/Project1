<%@ Page Language="C#" PageTemplate="/Casino/CasinoMaster.master" Inherits="CM.Web.ViewPageEx<CasinoEngine.Game>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>

<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>
<script type="text/C#" runat="server">
    private bool GetAvailablity()
    {
        if (!Profile.IsAuthenticated)
            return false;
        if (!Profile.IsEmailVerified)
        {
            UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
            cmUser user = ua.GetByID(Profile.UserID);
            if (!user.IsEmailVerified)
                return false;
            else if (!Profile.IsEmailVerified)
                Profile.IsEmailVerified = true;
        }
        return true;
    }

    private string GetCategory() {
        string requestPath = Request.RawUrl;
        string category = "";
        if (requestPath.Contains("/Index/")) {
            category = requestPath.Substring(requestPath.IndexOf("/Index/"));
            return category;
        } else if (requestPath.Contains("/Info/")) {
            category = requestPath.Substring(requestPath.IndexOf("/Info/"));
            return category;
        } else {
            return string.Empty;
        }
    }
    private string GetCategoryName() {
        string requestPath = Request.RawUrl;
        if (requestPath.Contains("/Index/")) {
            string category = requestPath.Substring(requestPath.IndexOf("/Index/") + 7);
            string categoryName = category.Replace("_", " ");
            return categoryName;
        } else if (requestPath.Contains("/Info/")) {
            string category = requestPath.Substring(requestPath.IndexOf("/Info/") + 6);
            string categoryName = category.Replace("_", " ");
            return categoryName;
        } else {
            return string.Empty;
        }
    }
</script>

<asp:content contentplaceholderid="cphHead" runat="Server">
<title><%= this.Model.Name.SafeHtmlEncode()%></title>
<meta name="keywords" content="<%= string.Join( ",", this.Model.Tags ).SafeHtmlEncode() %>" />
<meta name="description" content="<%= this.Model.Description.SafeHtmlEncode() %>" /> 
<meta http-equiv="pragma" content="no-cache" /> 
<meta http-equiv="cache-control" content="no-store, must-revalidate" /> 
<meta http-equiv="expires" content="Wed, 26 Feb 1997 08:21:57 GMT" /> 
</asp:content>

<asp:content contentplaceholderid="cphMain" runat="Server">

<div class="Breadcrumbs" role="navigation">
    <ul class="BreadMenu Container" role="menu">
        <li class="BreadItem" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
            <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Title") %>">
                <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/.Name") %></span>
            </a>
        </li>
        <li class="BreadItem" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
            <a class="BreadLink url" href="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/Casino/.Url") %>" itemprop="url" title="<%= this.GetMetadata("/Metadata/Breadcrumbs/Home/Casino/.Title") %>">
                <span itemprop="title"><%= this.GetMetadata("/Metadata/Breadcrumbs/Home/Casino/.Name") %></span>
            </a>
        </li>
        <li class="BreadItem BreadCurrent" role="menuitem" itemtype="http://data-vocabulary.org/Breadcrumb" itemscope="itemscope">
            <a class="BreadLink url" href="/Casino/Game<%=GetCategory() %>" itemprop="url" title="<%=GetCategoryName() %>">
                <span itemprop="title"><%=this.Model.Name %></span>
            </a>
        </li>
    </ul>
</div>

<div class="CasinoGameContent" id="casinoGameContent">

    <main class="CasinoMain">
        <% Html.RenderPartial("/Casino/Hall/GameOpenerWidget/Game", this.Model, this.ViewData); %>
    </main>
    
    <aside class="CasinoAside">

        <div class="HomeWidget">
            <% if (!Profile.IsAuthenticated)
               {
                   Html.RenderPartial("/QuickRegister/RegisterWidget");
               }
               else
               {
                   Html.RenderPartial("/Home/DepositWidget");
               } %>
        </div>
        <div class="HomeWidget SearchWidget" id="gameInfoSearchWrap">
            <form class="FilterForm SearchFilterForm" id="gameSearch" action="#" onsubmit="return false">
                <fieldset>
                    <label class="hidden" for="txtGameSearchKeywords"><%= this.GetMetadata(".Search").SafeHtmlEncode() %></label>
                    <input class="FilterInput" type="search" id="txtGameSearchKeywords" name="txtGameSearchKeywords" accesskey="g" maxlength="50" value="" placeholder="<%= this.GetMetadata(".Search_PlaceHolder").SafeHtmlEncode() %>" />
                    <button type="submit" class="Button SearchButton" name="gameSearchSubmit" id="btnSearchGame">
                        <span class="ButtonText"><%= this.GetMetadata(".Search").SafeHtmlEncode() %></span>
                    </button>
                </fieldset>
            </form>
        </div>
        <% if (Profile.IsAuthenticated) { Html.RenderPartial("../Lobby/CashRewardsWidget", this.ViewData.Merge(new { @AboutUrl = "/Casino/FPPLearnMore" })); } %>
    
        <% Html.RenderPartial("../Lobby/RecentWinnersWidget", this.ViewData.Merge(new { })); %>
    
    </aside>

    <%-- Html.RenderPartial("/Deposit/QuickDepositWidget/QuickDepositWidget", this.ViewData.Merge(new { })); --%>

    <div class="Zone"></div>

</div>

    <script type="text/html" id="searchgame-template">
<#
    var data = arguments[0],g_detail=null,g_numb=0;
    var lth=data.length;
    for( var i=lth-1;i>=0;i--) {
    g_numb++;
    g_detail=data[i] || {};
 #>

<li class="GLItem Item_<#=g_numb #>" data-gameid="<#= g_detail.S #>">
    <a href="/Casino/Game/Info/?gameid=<#= g_detail.S #>" class="GameThumb">
        <# if( g_detail.I.length > 0 ) { #>
            <img class="GT" src="<#= g_detail.I.htmlEncode() #>" alt="<#= g_detail.G.htmlEncode() #>" />
        <# } #>
    </a>
    <h3 class="GameTitle">
        <a href="/Casino/Game/Info/?gameid=<#= g_detail.S #>" class="Game"><#= g_detail.G.htmlEncode() #></a>
    </h3>
</li>

<# } #>
</script>

    <div class="SearchResultsGames Hidden">
        <ol class="GamesList" id="searchGameList"></ol>
    </div>

        <script type="text/javascript">
            var _jsonDataCache = [];// {"url","isLock","data"}
            function triggerUseCacheForJson(url, callBack, checkTimeout) {
                var jd = _jsonDataCache[url];
                //someone has used !
                if (jd != undefined) {
                    //data has loaded
                    if (!jd.isLock) {
                        callBack(jd.data);
                    } else {
                        if (!!!checkTimeout)
                            checkTimeout = 50;
                        // loading ...
                        var interval = setInterval(function () {
                            if (!jd.isLock) {
                                callBack(jd.data);
                                clearInterval(interval);
                            }
                        }, checkTimeout);
                    }
                } else {
                    jd = { "url": url, "isLock": true }; //lock
                    _jsonDataCache[url] = (jd);
                    _asynTrigger(url, callBack);
                }

            }
            function _asynTrigger(url, callBack) {
                $.getJSON(url, function (json) {
                    //sure inited
                    // first set
                    _jsonDataCache[url].isLock = false;
                    _jsonDataCache[url].data = json;
                    callBack(json);

                    _jsonDataCache[url].data = json;

                });
            }
    </script>
    <script type="text/javascript">
        var GameDataManager = window.GameDataManager = window.GameDataManager || (function () {
            var _LogFlag = '0',
                JsonUrl = '/Casino/Hall/GameData?maxNumOfNewGame=0\u0026maxNumOfPopularGame=40\u0026_=635987271451966428',
                _IsLargeData = false, _DataSource = null;
            var currentLang = "da";

            function updateLocalStorge(data) {
                if (data != null) {
                    _IsLargeData = false;
                    _DataSource = { source: data, flag: _LogFlag, lang: currentLang };
                    try {
                        localStorage.setItem("__allGameList", JSON.stringify(_DataSource));
                    } catch (e) {
                        _IsLargeData = true;
                    }
                }
            }
            function getDataFromLocalStorge() {
                var cacheData = null;
                if (_IsLargeData)
                    cacheData = _DataSource;
                else
                    cacheData = JSON.parse(localStorage.getItem("__allGameList"));
                if (cacheData != null && cacheData != 'null' && cacheData.length != 0) {
                    if (cacheData.flag == _LogFlag && currentLang == cacheData.lang) {
                        return cacheData.source;
                    }
                }
                return null;
            }
            function onGameLoadByJson(callback) {
                if (_DataSource && _DataSource.flag == _LogFlag) {
                    callback(_DataSource.source);
                    return;
                }
                triggerUseCacheForJson(JsonUrl, function (data) {
                    callback(data);
                    _DataSource = { source: data, flag: _LogFlag };
                });
            }
            function onGameLoadByLocalStorage(callback) {
                if ($(".localstorage").length > 0 && $(".ie7").length == 0 && $(".ie8").length == 0) {
                    try {
                        var lsData = getDataFromLocalStorge();
                        if (lsData != null && lsData != 'null' && lsData.length != 0) {
                            callback(lsData);
                            triggerUseCacheForJson(JsonUrl, updateLocalStorge);
                        } else {
                            triggerUseCacheForJson(JsonUrl, function (data) {
                                updateLocalStorge(data);
                                callback(data);
                            });
                        }
                    } catch (err) {
                        onGameLoadByJson(callback);
                    }
                } else {
                    onGameLoadByJson(callback);
                }
            }
            function setFlagStatus(status) {
                _LogFlag = status;
            }
            function getDataSource() {
                return _DataSource;
            }

            return {
                GameLoadByLocalStorage: onGameLoadByLocalStorage,
                SetFlag: setFlagStatus,
                GetDataSource: getDataSource,
                updateLocalStorge: updateLocalStorge
            }
        })();
        var newGameManager = {
            _localGamesKey: '__allGameList',
            _tryCount: 0,
            _updateLocal: false,
            log: function (msg) {
                console.log(msg);
            },
            _loadGames: function (callBack) {
                var me = this;
                try {
                    var lsData = null;

                    if (!!me.gameData) {
                        callBack(me.gameData);
                    } else {
                        GameDataManager.GameLoadByLocalStorage(function (gData) {
                            me.gameData = gData;
                            callBack(gData);
                        });

                    }

                } catch (err) {
                    me._tryCount++;
                    if (me._tryCount < 10)
                        me._loadGames(callBack);
                    else {
                        me.log("try " + me._tryCount + " but faild!");
                    }
                }

            },
            loadGamesByCategory: function (category, callBack,begin,end,keywords) {
                var me = this;
                var resolve = function(gms){
                    gms = me._filterGames(gms,keywords);
                    if ((!!begin || !!end))
                        callBack({
                            total: gms.length,
                            games: me._page(gms, begin, end)
                        });
                    else
                        callBack(gms);
                }
                me._loadGames(function (json) {
                    var gms = json[category];
                    if(!!gms && gms.length > 0  && typeof( gms[0]) == "string"){  //only gameId  #CI-2002
                        me._getGameByIds(gms,resolve);
                    }else{
                        resolve(gms);
                    }

                });
            },
            _getGameById:function(gameId, callBack){
                var me = this;
                if(!!me.gameMaps){
                    return callBack( me.gameMaps[gameId]);
                }

                me.gameMaps = {};
                me.loadAllGames(function(allGames){
                    for(var i = 0 ; i< allGames.length ;i++){
                        me.gameMaps[allGames[i].ID ] = allGames[i];
                    }
                    callBack(me.gameMaps[gameId]);
                });
            },
            _getGameByIds:function(gameIds,callBack){
                var me = this;
                var getGames = function(gameIds){
                    if(!me.gameMaps)
                        return [];

                    if(!$.isArray( gameIds))
                        gameIds = [gameIds];
                    var games = [];
                    for(var i = 0; i< gameIds.length;i++){
                        games.push( me.gameMaps[gameIds[i]]);
                    }

                    return games;
                }
                if(!!me.gameMaps){
                    return callBack( getGames(gameIds ));
                }else{
                    me.gameMaps = {};
                    me.loadAllGames(function(allGames){
                        for(var i = 0 ; i< allGames.length ;i++){
                            me.gameMaps[allGames[i].ID ] = allGames[i];
                        }
                        callBack( getGames(gameIds ));
                    });
                }
            },
            _page: function(games, begin, end) {
                if (!games)
                    return games;
                var _b = 0,
                    _e = games.length - 1;

                if (!!begin && begin < games.length - 1 && begin >= 0)
                    _b = begin;
                if (!!end && end <= games.length - 1 && end > _b)
                    _e = end;

                return games.slice(_b, _e + 1);

            },
            /*filter games*/
            _filterGames : function(games,keywords){
                if(!keywords || keywords.length == 0 || !games)
                    return games;

                var matchGames = [];
                keywords = keywords.toUpperCase();
                for(var i = 0 ;i < games.length; i++){
                    if( !!games[i].G && games[i].G.toUpperCase().indexOf(keywords) > -1)
                        matchGames.push(games[i]);
                }

                return matchGames;

            },
            removeNoImageGames: function (games) {
                var shouldRemoveItems = [];
                for (var i = 0 ; i < games.length; i++) {
                    if (games[i].I.length <= 0) {
                        shouldRemoveItems.push(games[i]);
                    }
                }
                if (shouldRemoveItems.length > 0) {
                    for (var i = 0; i < shouldRemoveItems.length; i++) {
                        var index = games.indexOf(shouldRemoveItems[i]);
                        if (index != -1)
                            games.splice(index, 1);
                    }
                }
                return games;
            },
            removeNoImageGamesAndStay: function (games, count) {
                var me = this;
                games = me.removeNoImageGames(games);
                count = count || 12;
                if (count < 1)
                    count = 12;
                while (games.length > count)
                    games.pop();

                return games;
            },
            loadAllGames: function (callBack, begin, end, keywords) {
                var me = this;
                if (!!me.allGames){
                    var fGames = me._filterGames(me.allGames,keywords);
                    if ((!!begin || !!end)) {
                        callBack({
                            total: fGames.length,
                            games: me._page(fGames, begin, end)
                        });
                    }else{
                        callBack(fGames);
                    }

                    return;
                }
               
                var games = [];
                me._loadGames(function (json) {
                    for( var cat in json)
                    {
                        if( json[cat] && !isNaN(json[cat].length) && json[cat].length > 0 ){
                            if( cat != 'favorites' ){
                                for( var i = 0; i < json[cat].length; i++ ){
                                    var g1 = json[cat][i];
                                    games.push(g1);
                                    if (g1.C != null && g1.C.length > 0) {
                                        for( var j = 0; j < g1.C.length; j++ ){
                                            games.push( g1.C[j]);
                                        }
                                    }
                                }
                            }
                        }                
                    }
                    me.allGames = games;
                    var total = 0,
                        finalGames = me._filterGames(games,keywords);
                
                    if ((!!begin || !!end))
                        callBack({
                            total: finalGames.length,
                            games: me._page(finalGames, begin, end)
                        });
                    else
                        callBack(finalGames);
                });
                function push(arr, g) {
                    var exit = false;
                    for (var i = 0 ; i < arr.length; i++) {
                        if (arr[i].S == g.S) {
                            exit = true;
                            break;
                        }
                    }
                    if (!exit) {
                        arr.push(g);
                    }
                }
                function deepSearch(_games, loadGames) {
                    for (var j = 0; j < _games.length; j++) {
                        push(loadGames, _games[j]);
                        if (!!_games[j].C) {
                            deepSearch(_games[j].C, loadGames);
                        }
                    }

                }
            }
        };
        // search games
        var gameInfoSearchGameEngine=(function(searchBox,gamesWrap,template){
            var searchTimer;
            var clearGames = function(){
                gamesWrap.html('').parent().addClass('Hidden');
            }

            $("#txtGameSearchKeywords").keyup(function(){
                var key=$(this).val();
                var searchFun = function(){
                    if(key == '')
                        clearGames();
                    else{
                        newGameManager.loadAllGames(function(games){
                            gamesWrap.html(  template.parseTemplate(games));
                        },null,null,key);
                    }
                }
                console.log(gamesWrap.find('.GLItem').length);
                if( gamesWrap.find('.GLItem').length > 0 ) gamesWrap.parent().removeClass('Hidden');
                else gamesWrap.parent().addClass('Hidden');
                if(searchTimer != null) 
                    clearTimeout(searchTimer);
                searchTimer = setTimeout(searchFun,300);
            });
          
        })($("#txtGameSearchKeywords"),$("#searchGameList"),$("#searchgame-template"));
</script>
<ui:MinifiedJavascriptControl runat="server" AppendToPageEnd="true">
    <script type="text/javascript">
        var gametitlebar = $('.GameBody > .TitleBar');
        $('.GameBody').append(gametitlebar);
        $('.GameContainer').next('.ControlBar').prepend(jQuery('h1.GameTitle'));
        $('.TitleBar .ControllerButtons').append('<li class="CB CBFullScreen"> <a href="javascript:_openFullScreenGame()" class="Button"> <span class="InfoIcon FullScr">Fullscreen MODE</span> <span>Fullscreen MODE</span> </a> </li>');
        $('.TitleBar .ControllerButtons').append(jQuery('li.CB.CBReal'));
        function _openFullScreenGame(){
            var slug = '<%=this.Model.Slug.SafeHtmlEncode()%>';
            var real = '<%=this.Model.IsRealMoneyModeEnabled.ToString()%>';
            var w = screen.availWidth * 9 / 10;
            var h = screen.availHeight * 9 / 10;
            var l = (screen.width - w)/2;
            var t = (screen.height - h)/2;
            var params = [
                    'height=' + h,
                    'width=' + w,
                    'fullscreen=no',
                    'scrollbars=no',
                    'status=yes',
                    'resizable=yes',
                    'menubar=no',
                    'toolbar=no',
                    'left=' + l,
                    'top=' + t,
                    'location=no',
                    'centerscreen=yes'
            ].join(',');
    
            var url = '/Casino/Game/Play/?gameid=' + slug + '&realMoney=' + (real ? "True" : "False");
            window.open(url, 'casino_game_window_' + slug.replace('-','_'), params);
            return;
        }
        function _openCasinoGame(slug, real) {
            var isAvailable = <%= GetAvailablity().ToString().ToLowerInvariant() %>;
            if( real && !isAvailable ){ 
                $(document).trigger('OPEN_OPERATION_DIALOG',{'returnUrl':'/Casino/Game/Info/'+ slug});
                return false;
            }
            var url = '/Casino/Game/Info/?gameid=' + slug + '&realMoney=' + (real ? "True" : "False");
            window.location.href = (url );
        }
        $(function () {
    
            var $c = $('#casinoGameContent');
            var pfnResize = function (e) {
                var $iframe = $('iframe', $c);
                var w = parseInt($iframe.data('width'), 10);
                var h = parseInt($iframe.data('height'), 10) * 1.0;
                $iframe.css('width', '100%');
                $iframe.height($iframe.width() * h / w);
            };
            pfnResize(); 
            $('a.BackButton', $c).click(function (e) {
                e.preventDefault();
                self.location = '/Casino/Hall';
            });
            $(document).bind('OPEN_OPERATION_DIALOG', function (e, data) {
                var url = '/Casino/Hall/Dialog?_=<%= DateTime.Now.Ticks %>';
                if( data != null && data.returnUrl != null ){
                    url += "&returnUrl=" + encodeURIComponent(data.returnUrl);
                }
                $('iframe.CasinoHallDialog').remove();
                $('<iframe style="border:0px;width:350px;height:300px;display:none" frameborder="0" scrolling="no" allowTransparency="true" class="CasinoHallDialog"></iframe>').appendTo( self.document.body);
                var $iframe = $('iframe.CasinoHallDialog', self.document.body).eq(0);
                $iframe.attr('src', url);
                $iframe.modalex($iframe.width(), $iframe.height(), true, self.document.body);
            });
        });
    </script>
</ui:MinifiedJavascriptControl>
</asp:content>
