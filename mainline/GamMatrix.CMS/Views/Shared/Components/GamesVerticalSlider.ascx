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
    private string GetGamesDataFun
    {
        get
        {
            if (ViewData["GetGamesDataFun"] != null)
                return ViewData["GetGamesDataFun"] as string;

            return "(return function(callBack){;})();";
        }
    }

    /// <summary>
    /// compute the size of the widget's function dynamically
    /// the only parameter is widget id named "containerId"
    /// </summary>
    private string ComputeSizeFun
    {
        get
        {
            if (ViewData["ComputeSizeFun"] != null)
                return ViewData["ComputeSizeFun"] as string;

            return "cumputeSize";
        }
    }
    protected override void OnPreRender(EventArgs e)
    {
        base.OnPreRender(e);
        ID = string.Format(System.Globalization.CultureInfo.InvariantCulture, "_{0}", Guid.NewGuid().ToString("N").Truncate(6));
    }

</script>

<div class="GamesSlider VerticalSlider <%=ContainerClass %>" id="<%=ID %>" style="display:none;">
            <div class="Container Buttons VerticalSliderBTNs">
                <a class="Max" href="javascript:void(0);">Max</a>
                <a class="Min" href="javascript:void(0);">Min</a>
                <a class="Close" href="javascript:void(0);">Close</a>
            </div>
    <div class="CatSlider">
        <div class="header">
            <h3 class="AdditionalTitle"> <span class="CatIcon">&para;</span> <span class="CatText"> <%=this.GetMetadata(".VerticalTitle") %> </span>  </h3>
        </div>
        <div class="Slider" id="slider_<%=ID %>">
            <ul class="SlideList Container" id="gamesList_<%=ID %>"></ul>
        </div>
    </div>

</div>
<style type="text/css">
    <%=this.GetMetadata(".CSS") %>
</style>
<script type="text/javascript">
    (function(global){
        global.gameRecommendSizeFuns = global.gameRecommendSizeFunsb || {};
        global.gameRecommendSizeFuns["sizeRule"] = global.gameRecommendSizeFuns["sizeRule"] || function(){
            return {
                max : {
                        w: 232,
                        h: (function(c,n){
                            var winHeight = $(window).height(),
                                top =   $('div.VerticalSliderBTNs',c).height(),
                                bottom = parseFloat( c.css('bottom'));
                            if(winHeight - bottom - top >= n)
                                return n;
                            else
                                return winHeight - bottom - top;
                        })($("#<%=ID %>").parent(),640)
                },
                min : {
                        w: 136,
                        h: 200
                },
                close : {
                        w: 100,
                        h: 'auto'
                }
            };
        };
        global.gameRecommendSizeFuns['gammingpop'] = global.gameRecommendSizeFuns['gammingpop'] || (function(){
            var gameFrame = $('.iframe-container'),
                rightBar = $('.ControlBar.right'),
                closeBtn = $('.ClosePopup'),
                
                win = $(window);

            var widgetContainer;
            
            return function(containerId){
                var winRec = {w: win.width(),h: win.height() },
                    rightBarVisible = rightBar.is(":visible"),
                    widgetContainer = widgetContainer || $("#"+containerId).parent(),
                    actionWrap = $('div.VerticalSliderBTNs',widgetContainer);

                var sizeRule = global.gameRecommendSizeFuns["sizeRule"].call(this);

                var leftSpace = 0; 
                if(rightBarVisible){
                    leftSpace = rightBar.offset().left + rightBar.width();
                }else{
                    leftSpace =  gameFrame.offset().left + gameFrame.width();
                }

                var freeWidth = winRec.w - leftSpace,
                    freeHeight = winRec.h - parseFloat( widgetContainer.css('bottom')  ) 
                    - closeBtn.offset().top - closeBtn.height()
                    - actionWrap.height();

                if(freeWidth >= sizeRule.max.w && freeHeight >= sizeRule.max.h){
                    return {
                        max:{
                            useSize : false,
                            w:freeWidth,
                            h:freeHeight
                        }
                    };
                }else if(freeWidth >= sizeRule.min.w && freeHeight >= sizeRule.min.h){
                    return {
                        min:{
                            useSize : true,
                            w:freeWidth,
                            h:freeHeight
                        }
                    };
                }else{
                    return {
                        close:true,
                        w:freeWidth,
                        h:freeHeight
                    };
                }

            };
        })();
    })(window);
    (function () {
        function cumputeSize(containerId){
            return {
                max : {
                    useSize : true,
                    w: 200,
                    h: 400,
                    use:false,
                },
                min : false,
                close : false
            };
        }
        function verticalSlider(container, games,autoScroll,autoInterval) {
            this.container = $(container);
            this.slider = $("#gamesList_<%=ID %>");
            this.games = games;
            this.autoInterval = autoInterval;

            this.populateView = function () {
                this.slider.empty();
                this._currentLeftIndex = 0;
                for (var i = 0; i < this.games.length; i++) {
                    var $item = this.createItem(i).appendTo(this.slider);
                    this._currentRightIndex = i;
                }
                var $items = $('> li', this.slider);
                if ($items.length > 1)
                    this._height = $items.eq(1).offset().top - $items.eq(0).offset().top;

            };

            this.createItem = function (index, append) {
                index = index % this.games.length;
                if (index < 0)
                    index = this.games.length + index;
                var g = this.games[index];
                if (this.games.length == 0) {
                    return null;
                }
                var $item = $($('#casino-game-item').parseTemplate([g]));
                if (append)
                    $item.appendTo(this.slider);
                else
                    $item.prependTo(this.slider);
                bindPopupEvent($item);
                $item.addClass('SlideItem');
                return $item;
            };

            function bindPopupEvent($container) {
                $('a.GameThumb,a.Game', $container).click(function (e) {
                    e.preventDefault();
                    var $anchor = $(this).parents('.GLItem');
                    var game = _game_map[$anchor.data('gameid')];
                    if (!!game)
                        _openCasinoGame(game.ID, true);
                    else
                        alert("game:" + $anchor.data('gameid') + " is not exit");
                    return;
                });
            }

            this.startAnimation = function () {
                if (this._direction == 0)
                    return;

                if (this._isAnimating)
                    return;

                this._isAnimating = true;

                if (this._direction < 0) {
                    var $first = $('> li:first', this.slider);
                    if($first.length == 0)
                        return;

                    var fun = (function (o) {
                        return function () {
                            o._currentLeftIndex += 1;
                            o._isAnimating = false;
                            $('> li:first', o.slider).remove();
                        };
                    })(this);

                    this._currentRightIndex += 1;
                    this.createItem(this._currentRightIndex, true);
                    $first.animate({ 'marginTop': -1 * this._height }
                    , {
                        duration: 300,
                        easing: 'linear',
                        complete: function () { fun(); }
                    });
                }
                else {
                    this._currentLeftIndex -= 1;
                    var $first = this.createItem(this._currentLeftIndex, false);
                    if($first.length == 0)
                        return;
                    $first.css('marginTop', -1 * this._height);

                    var fun = (function (o) {
                        return function () {
                            o._currentRightIndex -= 1;
                            o._isAnimating = false;
                            $('> li:last', o.slider).remove();
                        };
                    })(this);

                    $first.animate({ 'marginTop': 0 }
                    , {
                        duration: 300,
                        easing: 'linear',
                        complete: function () { fun(); }
                    });
                }
            };

            var fun2 = (function (o) {
                return function () {
                    o._direction = 1;
                    o.startAnimation();
                };
            })(this);

            var scrollInterval;

            var startAuto = function () {
                autoInterval = autoInterval || 5;
                scrollInterval = setInterval(fun2, autoInterval * 1000);
            };
            var stopAuto = function () {
                if (scrollInterval)
                    clearInterval(scrollInterval);
            };

            this.start = startAuto;
            this.stop = stopAuto;
        }

        $(function () {
             
            var fun = <%=GetGamesDataFun %>,
                //resizeFun = <%=ComputeSizeFun %>,
                container = $('#<%=ID %>').parent(),
                btns = $('#<%=ID %> > div.VerticalSliderBTNs a'),
                sliderContainer = $("#slider_<%=ID %>");

            var classes = ["Maximize","Minimize","Closed"];
            var inChanging = false;
            function calculateWidgetSize(){
                if(inChanging)
                    return;

                var result = gameRecommendSizeFuns['gammingpop'].call(this,'<%=ID %>');
                console.log(result);
                var finalSize,
                    closed = false,
                    key = 'max',
                    index;
                if(!!result.max){
                    finalSize = result.max;
                    key = 'max';
                    index = 0;
                }else if(!!result.min){
                    finalSize = result.min;
                    key = 'min';
                    index = 1;
                }else{
                    finalSize = result.close;
                    key = 'close';
                    closed = true;
                    index = 2;
                }

                var sizeRule = window.gameRecommendSizeFuns["sizeRule"].call(this),
                    currentRule = !!sizeRule[key] ? sizeRule[key]:sizeRule.max;

                onSizeChanged( classes[index],finalSize,currentRule,key,false );
               
                console.log(finalSize);
            }

            function onSizeChanged(className,finalSize,ruleSize,key,isClicking){

                inChanging = true;

                for(var i = 0; i< classes.length;i++){
                    container.removeClass( classes[i] );
                }
                container.addClass(className);
                var getSize = function(size){
                    if(typeof size == 'string')
                        return size;
                    else
                        return size + 'px';
                };
                var w = getSize(ruleSize.w),
                    h = getSize(ruleSize.h);
              
                container.animate({
                    'width': w ,
                    'height': h ,
                },'fast',function(){
                    inChanging = false;
                });

                if(key == 'close'){
                    sliderContainer.hide();
                }else{
                    sliderContainer.show();
                }
                changeButtonStatus(key);
                if(isClicking){
                    container.addClass('Important');
                }else{
                    container.removeClass('Important');
                }

            }

            function changeButtonStatus(key){
                btns.removeClass('Current');
                $.each(btns,function(){
                    var btn = $(this);
                    if(btn.attr('class').toLowerCase() == key){
                        btn.addClass('Current');
                        return false;
                    }
                });
            }

            btns.click(function(){
                if(inChanging)
                    return ;

                var btn = $(this),
                    key = btn.attr('class').toLowerCase(),
                    className = '';
                for(var i= 0; i < classes.length;i++){
                    if(classes[i].toLowerCase().indexOf( key ) == 0){
                        className = classes[i];
                        break;
                    }
                }

                var sizeRule = window.gameRecommendSizeFuns["sizeRule"].call(this),
                    currentRule = !!sizeRule[key] ? sizeRule[key]:sizeRule.max;

                changeButtonStatus(key);

                onSizeChanged(className,null,currentRule,key,true);
                if(logged){
                    $.cookie(cookieKey,btn.attr('class').split(' ')[0],{'expires':365});
                }
            });

            var logged = <%=Profile.IsAuthenticated.ToString().ToLower() %>;
            var cookieKey = "_gamerecommandstatus_";
            if(logged && !!$.cookie(cookieKey)){
                var status = $.cookie(cookieKey),
                    currentBtn = (function(){
                        var btn;
                        $.each(btns,function(){
                            var $btn = $(this);
                            if($btn.attr('class').indexOf(status) == 0){
                                btn = $btn;
                                return false;
                            }
                        });
                        return btn;
                    })();

                if(currentBtn){
                    $(currentBtn).trigger('click');
                }
            }else{
                
            }

            $(window).resize( function(){
                setTimeout(function(){ calculateWidgetSize();},200);
            });


            fun.call(this,function(json){
                var slider = new verticalSlider($("#slider_<%=ID %>"), json.data,<%=AutoScroll.ToString().ToLower() %>, <%=AutoTimeInterval %>);
                slider.populateView();
                slider.start();
                $("#<%=ID %>").removeAttr('style');
                calculateWidgetSize();
            });
        });
    })();
</script>
