<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="CasinoEngine" %>
<%@ Import Namespace="Finance" %>


<script type="text/C#" runat="server">
    private string ClientID { get; set; }

    protected override void OnPreRender(EventArgs e)
    {
        base.OnPreRender(e);
        this.ClientID = string.Format("_{0}", Guid.NewGuid().ToString("N").Truncate(5));
    }


    private string GetUrl()
    {
        return string.Format("/Casino/Hall/GetSimilarGames?gameid={0}&maxCount=20", this.ViewData["GameID"]);
    }
    
</script>





<div class="Box SimilarGames" id="<%= ClientID %>">
	<ul class="SimilarGamesControl Controls">
		<li class="Prev">
			<a href="#" class="PrevLink" title="<%= this.GetMetadata(".Previous_Tip").SafeHtmlEncode()%>">&#9668;</a>
		</li>
		<li class="Next">
			<a href="#" class="NextLink" title="<%= this.GetMetadata(".Next_Tip").SafeHtmlEncode()%>">&#9658;</a>
		</li>
	</ul>
	<div class="SimilarGamesCanvas">
		<ul class="SimilarGameList">
            

		</ul>
	</div>
</div>


<%= this.ClientTemplate("GameItem", "similar-game-item-template")%>

<ui:MinifiedJavascriptControl runat="server" >

<script type="text/javascript">
    $(function () {


        $.getJSON('<%= GetUrl().SafeJavascriptStringEncode() %>', function (json) {
            if (!json.success) {
                alert(json.error);
                return;
            }
            var _games = json.games;
            var $container = $('#<%= ClientID %>');
            var _currentLeftIndex = 0;
            var _currentRightIndex = 0;
            var _lastDirection = 1;
            var _isAnimating = false;
            var _itemWidth = 0;
            var $prev = $('a.PrevLink', $container);
            var $next = $('a.NextLink', $container);
            var $list = $('ul.SimilarGameList', $container);


            function createItem(index, append) {
                var index = index % _games.length;
                if (index < 0)
                    index = _games.length + index;
                var g = _games[index];

                var $item = $($('#similar-game-item-template').parseTemplate([g]));
                if (append)
                    $item.appendTo($list);
                else
                    $item.prependTo($list);

                $('a', $item).data('game', g).click(function (e) {
                    e.preventDefault();
                    var game = $(this).data('game');
                    _openCasinoGame(game.S, <%= this.ViewData["realMoney"].ToString().ToLowerInvariant() %>);
                });
                return $item;
            }

            var funResize = function () {
                var $canvas = $('div.SimilarGamesCanvas', $container);
                $list.empty();
                var right = $canvas.offset().left + $canvas.width();


                for (var i = 0; i < _games.length; i++) {
                    var $item = createItem(i, true);
                    _currentRightIndex = i;
                    if ($item.offset().left > right)
                        break;
                }
                var $items = $('ul.SimilarGameList > li', $container);
                if ($items.length > 1)
                    _itemWidth = $items.eq(1).offset().left - $items.eq(0).offset().left;
            };
            funResize();
            $(window).bind('resize', funResize);

            function startAnimation(dir) {
                if (isNaN(dir))
                    return;

                if (_isAnimating)
                    return;

                _isAnimating = true;

                if (dir < 0) {
                    var $first = $('> li:first', $list);

                    var fun = (function (o) {
                        return function () {
                            $('> li:first', o).remove();
                            _currentLeftIndex += 1;
                            _isAnimating = false;
                        };
                    })($list);

                    _currentRightIndex += 1;
                    createItem(_currentRightIndex, true);
                    $first.animate({ 'marginLeft': -1 * _itemWidth }
                    , {
                        duration: 300,
                        easing: 'linear',
                        complete: function () { fun(); }
                    });
                }
                else {
                    _currentLeftIndex -= 1;
                    var $first = createItem(_currentLeftIndex, false);
                    $first.css('marginLeft', -1 * _itemWidth);

                    var fun = (function (o) {
                        return function () {
                            _currentRightIndex += 1;
                            _isAnimating = false;
                            $('> li:last', o).remove();
                        };
                    })($list);

                    $first.animate({ 'marginLeft': 0 }
                    , {
                        duration: 300,
                        easing: 'linear',
                        complete: function () { fun(); }
                    });
                }
            };

            $prev.click(function (e) {
                e.preventDefault();
                _lastDirection = 1;
                startAnimation(_lastDirection);
            });
            $next.click(function (e) {
                e.preventDefault();
                _lastDirection = -1;
                startAnimation(_lastDirection);
            });


            setInterval(function () {
                startAnimation(_lastDirection);
            }, 6000);
        });
    });
</script>   

</ui:MinifiedJavascriptControl>