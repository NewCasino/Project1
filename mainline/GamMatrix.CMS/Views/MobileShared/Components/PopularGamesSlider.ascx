<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<List<Game>>" %>
<%@ Import Namespace="CasinoEngine" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script type="text/C#" runat="server">
    private string ID { get; set; }
    private List<Game> GameList { get; set; }
    private int CountryId;

    protected override void OnInit(EventArgs e)
    {
        int CountryId = Profile.IpCountryID;
        if (Profile.IsAuthenticated)
            CountryId = Profile.UserCountryID;

        if (this.Model != null)
            GameList = this.Model.GroupBy(g => g.ID).Select(g => g.First()).ToList();
        else
            GameList = CasinoEngineClient.GetPopularityGamesInCountry(Platform.Android, CountryId);

        if (GameList.Count == 0 && Debug)
        {
            GameList = CasinoEngineClient.GetGames().Values.GroupBy(g => g.ID).Select(g => g.First()).Where(g => !string.IsNullOrEmpty(g.IconUrlFormat)).Take(20).ToList();
        }


        ID = string.Format(System.Globalization.CultureInfo.InvariantCulture, "_{0}", Guid.NewGuid().ToString("N").Truncate(6));

        base.OnInit(e);
    }

    private string GetIconUrl(Game game, int size = 44)
    {
        if (!string.IsNullOrEmpty(game.IconUrlFormat))
            return string.Format(game.IconUrlFormat, size);
        return string.Empty;
    }

    private bool Debug
    {
        get
        {
            return ViewData["Debug"] != null && ViewData["Debug"].ToString().Equals("true", StringComparison.InvariantCultureIgnoreCase);
        }
    }

    private string Title
    {
        get
        {
            if (ViewData["Title"] != null)
                return ViewData["Title"] as string;

            var countryName = string.Empty;

            var country = CountryManager.GetAllCountries().FirstOrDefault(c => c.InternalID == CountryId);
            if (country != null)
                countryName = country.DisplayName;

            return string.Format(this.GetMetadata(".Title_Format"), countryName);
        }
    }
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
</script>

<div class="Box NewSlider GamesSlider <%=ContainerClass %>" id="<%=ID %>">
    <h3 class="GameCatText">
    	<span class="CatIcon">&para;</span>
    	<span class="CatText"><%=Title %></span>
    </h3>
    <ul class="NewSliderControls">
        <li class="NSPrev">
            <a class="NSLink PrevLink" href="javascript:void(0);">›</a>
        </li>
        <li class="NSNext">
            <a class="NSLink NextLink" href="#">›</a>
        </li>
    </ul>
    <ul class="GameList GamesSliderList IconList Cols-2 Cols-X-2 L Container">
    <% 
        foreach (Game game in GameList)
        {
    %>
        <li class="GameItem Col X" data-vendor="<%= game.VendorID.ToString().SafeHtmlEncode()%>">
            <a class="GameLink B Container" href="<%= Url.RouteUrl("CasinoGame", new { @gameID = game.ID }).SafeHtmlEncode()%>"> 
            <span class="Icon">
            <span class="IconWrapper"> 
            <span class="Game I" style="background-image:url('<%= GetIconUrl(game, 114).SafeHtmlEncode() %>');"></span>
            <% 
                if (game.IsNewGame)
                {
            %> 
            <span class="LiveUpdate Updates"><%= this.GetMetadata(".New").SafeHtmlEncode() %></span> 
            <% 
                }
            %>  
            </span> 
            </span> 
            <span class="GameName N"><%= game.ShortName.SafeHtmlEncode()%></span> 
            </a>
        </li>
    <%
        }
    %>
    </ul>
</div>

<script type="text/javascript">
    (function () {
        function GameSlider(el, autoScroll, interval) {
            this._slider = $(el);
            this._container = $('ul.GameList', el);
            this._prevButton = $('ul.NewSliderControls a.PrevLink', el);
            this._nextButton = $('ul.NewSliderControls a.NextLink', el);
            this._currentLeftIndex = 0;
            this._currentRightIndex = 0;
            this._width = 0;
            this._direction = 0;
            this._isAnimating = false;
            this._isVisible = false;

            this.show = function () {
                this._isVisible = true;
                this._slider.fadeIn();
            };

            this.init = function () {
                var $items = $('> li', this._container);
                this._currentLeftIndex = 0;
                this._currentRightIndex = $items.length - 1;
                if ($items.length > 1)
                    this._width = $items.eq(1).offset().left - $items.eq(0).offset().left;
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
                    //this.createItem(this._currentRightIndex, true);
                    $('> li:first', this._container).clone().appendTo(this._container)
                    $first.animate({ 'marginLeft': -1 * this._width }
                    , {
                        duration: 300,
                        easing: 'linear',
                        complete: function () { fun(); }
                    });
                }
                else {
                    this._currentLeftIndex -= 1;
                    var $first = $('> li:last', this._container).clone(); //this.createItem(this._currentLeftIndex, false);
                    $first.prependTo(this._container);
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
            var stopAuto = function () {
                if (!autoScroll)
                    return;

                clearInterval(autoInterval);
            };
            var btnNext = this._nextButton;
            var startAuto = function () {
                if (!autoScroll)
                    return;
                interval = interval || 5;
                autoInterval = setInterval(function () { btnNext.click(); }, interval * 1000);
            };

            this._prevButton.click(function (e) {
                e.preventDefault();
                fun2();
            }).attr('href', 'javascript:void(0)').mouseover(stopAuto).mouseout(startAuto);

            this._nextButton.click(function (e) {
                e.preventDefault();
                fun1();
            }).attr('href', 'javascript:void(0)').mouseover(stopAuto).mouseout(startAuto);

            startAuto();
        }

        $(function () {
            var slider = new GameSlider($("#<%=ID %>"),<%=AutoScroll.ToString().ToLower() %>, <%=AutoTimeInterval %>);
            slider.init();
            slider.show();
        });
    })();
</script>