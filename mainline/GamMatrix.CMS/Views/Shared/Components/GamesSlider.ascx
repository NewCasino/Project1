<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<script runat="server">
    private string ID { get; set; }
    private string ContainerClass
    {
        get
        {
            if (ViewData["ContainerClass"] != null)
                return ViewData["ContainerClass"] as string;
            return string.Empty;
        }
    }

    private bool AutoScroll
    {
        get
        {
            if (ViewData["AutoScroll"] == null)
                return true;

            return ViewData["AutoScroll"].ToString().Equals("true", StringComparison.InvariantCultureIgnoreCase);
        }
    }
    private int AutoTimeInterval
    {
        get
        {
            int secs = 5;
            if (ViewData["AutoTimeInterval"] == null)
            {
                ;
            }
            else
            {
                int.TryParse(ViewData["AutoTimeInterval"].ToString(), out secs);
            }
            return secs;
        }
    }
    private string Title
    {
        get
        {
            if (ViewData["Title"] != null)
                return ViewData["Title"] as string;
            return string.Empty;
        }
    }

    private bool OpenGameDirectly
    {
        get
        {
            return ViewData["OpenGameDirectly"] != null && ViewData["OpenGameDirectly"].ToString().Equals("true", StringComparison.InvariantCulture);
        }
    }

    private string GetGamesDataFun
    {
        get
        {
            if (ViewData["GetGamesDataFun"] != null)
                return ViewData["GetGamesDataFun"] as string;

            return "(return function(callBack){;})();";
        }
    }

    protected override void OnPreRender(EventArgs e)
    {
        base.OnPreRender(e);
        ID = string.Format(System.Globalization.CultureInfo.InvariantCulture, "_{0}", Guid.NewGuid().ToString("N").Truncate(6));
    }
    private bool IsEmailVerified()
    {
        bool isEmailVerified = false;
        if (Profile.IsAuthenticated)
        {
            isEmailVerified = Profile.IsEmailVerified;
            if (!Profile.IsEmailVerified)
            {
                CM.db.Accessor.UserAccessor ua = CM.db.Accessor.UserAccessor.CreateInstance<CM.db.Accessor.UserAccessor>();
                CM.db.cmUser user = ua.GetByID(Profile.UserID);
                if (user.IsEmailVerified)
                {
                    isEmailVerified = true;
                    Profile.IsEmailVerified = true;
                }
            }
        }

        return isEmailVerified;
    }

</script>
<div class="GamesSlider <%=ContainerClass %>" id="<%=ID %>">
    <div class="CatSlider">
    	    <h3 class="AdditionalTitle">
    		    <span class="CatIcon">&para;</span>
    		    <span class="CatText"><%=Title %></span>
    	    </h3>
    
    	    <div class="Slider" id="slider_<%=ID %>">
    		    <ul class="SlideList Container" id="gamesList_<%=ID %>">
    		    </ul>
    	    </div>
            <ul class="SliderControls">
    			<li class="SCArrows SCPrev">
    				<a class="SCLink PrevLink" href="#">
    					<span class="SIcon">&#8249;</span>
    				</a>
    			</li>
    			<li class="SCArrows SCNext">
    				<a class="SCLink NextLink" href="#">
    					<span class="SIcon">&#8250;</span>
    				</a>
    			</li>
    		</ul>
    
    </div>
</div>
<style type="text/css">
    <%=this.GetMetadata(".CSS") %>
</style>
<script type="text/javascript">
    (function () {
        var isAvailableLogin = <%= (Profile.IsAuthenticated && Profile.IsEmailVerified).ToString().ToLowerInvariant() %>;
        function GameSlider(el, games,autoScroll,interval) {

            if ($('#casino-game-item').length == 0) {
                alert("no casino game template!");
                return;
            }

            this._slider = $(el);
            this._container = $('ul.SlideList', el);
            var btnWrap = el.next();
            this._prevButton = $('a.PrevLink', btnWrap);
            this._nextButton = $('a.NextLink', btnWrap);
            this._orginalGames = games;
            this._filteredGames = [];
            this._currentLeftIndex = 0;
            this._currentRightIndex = 0;
            this._width = 0;
            this._direction = 0;
            this._isAnimating = false;
            this._isVisible = false;

            this.show = function () {
                this._isVisible = true;
                this._slider.parents('div.CatSlider').fadeIn();
            };

            this.populateView = function () {
                var callback = (function (o) {
                    return function () {
                        o.populateViewCompleted(arguments[0]);
                    };
                })(this);

                callback(games);
            };

            this.populateViewCompleted = function (result) {
                this._filteredGames = result;
                this._container.empty();
                this._currentLeftIndex = 0;
                var r = this._slider.offset().left + this._slider.width();

                for (var i = 0; i < this._filteredGames.length; i++) {
                    var $item = this.createItem(i).appendTo(this._container);
                    this._currentRightIndex = i;
                    if ($item.offset().left > r)
                        break;
                }
                var $items = $('> li', this._container);
                if ($items.length > 1)
                    this._width = $items.eq(1).offset().left - $items.eq(0).offset().left;

                if (!this._isVisible)
                    this._slider.parents('div.CatSlider').hide();
            };

            this.createItem = function (index, append) {
                index = index % this._filteredGames.length;
                if (index < 0)
                    index = this._filteredGames.length + index;
                var g = this._filteredGames[index];
                if (this._filteredGames.length == 0) {
                    return null;
                }
                var $item = $($('#casino-game-item').parseTemplate([g]));
                if (append)
                    $item.appendTo(this._container);
                else
                    $item.prependTo(this._container);
                bindPopupEvent($item);
                $item.addClass('SlideItem');
                return $item;
            };

            function closeAllPopups() {
                $('.ActiveDrop').removeClass('ActiveDrop');
                $('.ActiveSummaryDrop').removeClass('ActiveSummaryDrop');
                $('.Popup').hide();
            }
            function bindPopupEvent($containers){
            
                var leftOffset = 0;
                if(arguments.length > 1)
                    leftOffset = arguments[1];
                $('a.GameThumb,a.Game', $containers).click( function(e){
                    e.preventDefault();
                    var $anchor = $(this).parents('.GLItem');
                    var game = _game_map[$anchor.data('gameid')];
                    if(!game)
                        return;

                    <%if (OpenGameDirectly) { %>
                    _openCasinoGame( game.ID, true);
                    return;
                    <%}%>
                    var $popup = $('#casino-game-popup');
                    var html = $('#casino-game-popup-template').parseTemplate(game);
                
                    $popup.empty().html( html );
                    $popup.show();
                    positionPopup( $popup, $anchor,leftOffset);

                    $('#casino-game-popup a.Close').click( function(e){
                        e.preventDefault();
                        $('#casino-game-popup').hide();
                        $(document).trigger('Game_Popup_Closed');
                    });

                

                    $('#casino-game-popup .AddFav a').click( function(e){
                        e.preventDefault();
                        var url = '/Casino/Lobby/AddToFavorites';

                        $.getJSON( url, { gameID : game.ID }, function(){
                            $('#casino-game-popup .AddFav').addClass('Hidden');
                            $('#casino-game-popup .RemoveFav').removeClass('Hidden');
                            $('#casino-game-popup span.GTfav').removeClass('Hidden');

                            $(document).trigger( 'GAME_ADDED_TO_FAV', game.ID);
                        
                        });
                    });

                    $('#casino-game-popup .RemoveFav a').click( function(e){
                        e.preventDefault();
                        var url = '/Casino/Lobby/RemoveFromFavorites';
                        $.getJSON( url, { gameID : game.ID }, function(r){
                            $('#casino-game-popup .AddFav').removeClass('Hidden');
                            $('#casino-game-popup .RemoveFav').addClass('Hidden');
                            $('.GLItem[data\-gameid="' + game.ID + '"] span.GTfav').addClass('Hidden');
                            $('#casino-game-popup span.GTfav').addClass('Hidden');
                            game.Fav = 0;
                            removeFavGame(game);
                            $(document).trigger( 'GAME_REMOVE_FROM_FAV', game.ID);
                        });
                    });

                    $('#casino-game-popup li.Info.GOItem a').click( function(e){
                        e.preventDefault();
                        var url = '/Casino/Game/Rule/' + game.S;
                        window.open(url
                            , 'game_rule'
                            , 'width=300,height=200,menubar=0,toolbar=0,location=0,status=1,resizable=1,centerscreen=1'
                            );
                    });

                    // 
                    function showAdditional(real){
                        if( (!isAvailableLogin && real) ||
                            (game.C == null && real && game.R != 1) ||
                            (game.C == null && !real && game.F != 1) ){
                            //{'a':'c'}
                        
                            var gameid = game.S;
                            if(game.S == undefined){try{gameid = game.C[0].S;}catch(err){}} 
                            var gameurl = gameid == undefined ? "/Casino/" : '/Casino/Game/Info/'+ gameid;
                            $(document).trigger( 'OPEN_OPERATION_DIALOG',{'returnUrl':gameurl} );
    
                            $.cookie("_lg_slug",gameid);
                            return;
                        }

                        if (real == true) {
                            var isEmailVerified = '<%=IsEmailVerified() %>';
                            if (!isEmailVerified.toLowerCase() == 'true') {
                                window.location = "/EmailNotVerified";
                                return;
                            } else {
                                var isIncompleteProfile = 'False';
                                if (isIncompleteProfile.toLowerCase() == 'true') {
                                    window.location = "/IncompleteProfile";
                                    return;
                                }
                            }
                        }

                        var $extra = $('#casino-game-popup .PopupAdditional');
                        if( $extra.length == 0 ){
                            _openCasinoGame( game.S, real == true);
                        }
                        else{
                            $extra.show();
                            $('ol.GameVariants a.GVLink').off( 'click' );
                            $('ol.GameVariants a.GVLink').on( 'click', function(e){
                                e.preventDefault();
                                _openCasinoGame( $(this).data('gameid'), real == true);
                            });
                        }
                    }

                    $('#casino-game-popup .Fun a').click( function(e){
                        e.preventDefault();
                        showAdditional(false);
                    });

                    $('#casino-game-popup a.CTAButton').click( function(e){
                        e.preventDefault();
                        showAdditional(true);
                    });

                    $(document).trigger('Game_Popup_Opened');
                });
            }
            function positionPopup( $popup, $anchor ) {
                var pos = $anchor.offset();
                var left = Math.floor(pos.left);

                if ( left + $popup.width() > $(document.body).width() ) {
                    var dx = ( $popup.width() + left ) - $(document.body).width();
                    left = left - dx;
                }
                if(arguments.length > 2)
                    left = left + arguments[2];

                var top = Math.floor(pos.top);

                $popup.css({ 'left' : left + 'px', 'top' : top+'px' });

                pos = $popup.offset();
                pos.right = pos.left + $popup.width();
                pos.maxRight = $(window).scrollLeft() + $(window).width();
                pos.bottom = pos.top + $popup.height();
                pos.maxBottom = $(window).scrollTop() + $(window).height();

                if( pos.maxRight < pos.right ){
                    $(window).scrollLeft( pos.right - $(window).width() );
                }

                if( pos.maxBottom < pos.bottom ){
                    $(window).scrollTop( pos.bottom - $(window).height() );
                }
            }

            this.startAnimation = function () {
                if (this._direction == 0)
                    return;

                if (this._isAnimating)
                    return;
                //closeAllPopups();
                this._isAnimating = true;

                if (this._direction < 0) {
                    var $first = $('> li:first', this._container);

                    var fun = (function (o) {
                        return function () {
                            o._currentLeftIndex += 1;
                            o._isAnimating = false;
                            $('> li:first', o._container).remove();
                            //o.startAnimation();
                        };
                    })(this);

                    this._currentRightIndex += 1;
                    this.createItem(this._currentRightIndex, true);
                    $first.animate({ 'marginLeft': -1 * this._width }
                    , {
                        duration: 300,
                        easing: 'linear',
                        complete: function () { fun(); }
                    });
                }
                else {
                    this._currentLeftIndex -= 1;
                    var $first = this.createItem(this._currentLeftIndex, false);
                    $first.css('marginLeft', -1 * this._width);

                    var fun = (function (o) {
                        return function () {
                            o._currentRightIndex -= 1;
                            o._isAnimating = false;
                            $('> li:last', o._container).remove();
                            //o.startAnimation();
                        };
                    })(this);

                    $first.animate({ 'marginLeft': 0 }
                    , {
                        duration: 300,
                        easing: 'linear',
                        complete: function () { fun(); }
                    });
                }
            };

            var fun1 = (function (o) {
                return function () {
                    o._direction = -1;
                    o.startAnimation();
                };
            })(this);
            var fun2 = (function (o) {
                return function () {
                    o._direction = 1;
                    o.startAnimation();
                };
            })(this);
            var fun3 = (function (o) {
                return function () {
                    o._direction = 0;
                    o.startAnimation();
                };
            })(this);

            var autoInterval;
            var stopAuto = function(){
                if(!autoScroll)
                    return;

                clearInterval(autoInterval);
            };
            var btnNext = this._nextButton;
            var startAuto = function(){
                if(!autoScroll)
                    return;
                interval = interval || 5;
                autoInterval = setInterval( function(){ btnNext.click(); }, interval * 1000);
            };

            this._prevButton.click(function(e){
                e.preventDefault();
                fun2();
            }).attr('href', 'javascript:void(0)').mouseover(stopAuto).mouseout(startAuto);
            //this._prevButton.mousedown(fun2).mouseup(fun3).mouseout(fun3).attr('href', 'javascript:void(0)');
            this._nextButton.click(function(e){
                e.preventDefault();
                fun1();
            }).attr('href', 'javascript:void(0)').mouseover(stopAuto).mouseout(startAuto);
            //this._nextButton.mousedown(fun1).mouseup(fun3).mouseout(fun3).attr('href', 'javascript:void(0)');

           
            startAuto();
        }
        $(function () {
            var fun = <%=GetGamesDataFun %>;
            fun.call(this,function(json){
                var slider = new GameSlider($("#slider_<%=ID %>"), json.data,<%=AutoScroll.ToString().ToLower() %>, <%=AutoTimeInterval %>);
                slider.populateView();
                slider.show();
            });
        });
    })();
</script>