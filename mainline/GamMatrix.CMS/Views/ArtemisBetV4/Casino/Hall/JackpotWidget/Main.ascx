<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="CasinoEngine" %>
<%@ Import Namespace="Finance" %>


<script type="text/C#" runat="server">
    private string ClientID { get; set; }

    protected override void OnPreRender(EventArgs e) {
        base.OnPreRender(e);
        this.ClientID = string.Format("_{0}", Guid.NewGuid().ToString("N").Truncate(5));
    }

    private string GetUrl() {
        return string.Format("/Casino/Hall/GetJackpotJson?currency={0}", this.ViewData["Currency"]);
    }

    private string ContainerSelector {
        get { return ViewData["ContainerSelector"] != null ? ViewData["ContainerSelector"].ToString() : string.Empty; }
    }
    
</script>

<div class="Box Jackpots" id="<%= ClientID %>">
    <h2 class="BoxTitle JackpotsTitle">
        <a href="/casino/jackpots" class="TitleLink" title="<%= this.GetMetadata(".All_Jackpots_Link_Tip").SafeHtmlEncode()%>">
            <%= this.GetMetadata(".All_Jackpots_Link").SafeHtmlEncode()%> <span class="ActionSymbol">&#9658;</span>
        </a>
        <strong class="TitleText"><%= this.GetMetadata(".Title").SafeHtmlEncode() %></strong>
    </h2>
    <div class="JackpotCanvas">
        <ul class="JackpotList">
            <%= this.PopulateTemplate("JackpotItem", this.Model)%>
        </ul>
    </div>
</div>

<%= this.ClientTemplate( "JackpotItem", "jackpot-item-template") %>

<ui:MinifiedJavascriptControl runat="server" AppendToPageEnd="true" Enabled="true">

<script type="text/javascript">
    $(function () {
        $.getJSON('<%= GetUrl().SafeJavascriptStringEncode() %>', function (json) {
            if (!json.success) {
                alert(json.error);
                return;
            }

            var _games = json.data;
            var $container = $('#<%= ClientID %>');

            var containerSelector = '<%= ContainerSelector %>';

            if (containerSelector) {
                var newContainer = $container.clone();

                $container.remove();
                $container = newContainer;
                $(containerSelector).append(newContainer);
            }

            var _currentLeftIndex = 0;
            var _currentRightIndex = 0;
            var _lastDirection = 1;
            var _isAnimating = false;
            var _itemWidth = 0;
            var $prev = $('a.PrevLink', $container);
            var $next = $('a.NextLink', $container);
            var $list = $('ul.JackpotList', $container);


            function createItem(index, append) {
                var index = index % _games.length;
                if (index < 0)
                    index = _games.length + index;
                var g = _games[index];

                var $item = $($('#jackpot-item-template').parseTemplate([g]));
                if (append)
                    $item.appendTo($list);
                else
                    $item.prependTo($list);

                $('a', $item).data('game', g).click(function (e) {
                    e.preventDefault();
                    var game = $(this).data('game');
                    if (game.E)
                        _openCasinoGame(game.S, game.M);
                    else                        
                        $(document).trigger('OPEN_OPERATION_DIALOG',{'returnUrl':'/Casino/Game/Info/'+ game.S} );
                });
                return $item;
            }

            var funResize = function () {
                var $canvas = $('div.JackpotCanvas', $container);
                $list.empty();
                var right = $canvas.offset().left + $canvas.width();


                for (var i = 0; i < _games.length; i++) {
                    var $item = createItem(i, true);
                    _currentRightIndex = i;
                    if ($item.offset().left > right)
                        break;
                }
                var $items = $('ul.JackpotList > li', $container);
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
                            _currentRightIndex -= 1;
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
            }, 3000);
        });
    });
</script>   

</ui:MinifiedJavascriptControl>