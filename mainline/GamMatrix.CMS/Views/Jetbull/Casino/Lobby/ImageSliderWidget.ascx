<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="CasinoEngine" %>
<%@ Import Namespace="Finance" %>
<script type="text/C#" runat="server">

private sealed class SliderGame
{
    public Game Game { get; set; }
    public string BackgroundImageUrl { get; set; }
    public string Title { get; set; }
    public string Text { get; set; }
    public string Url { get; set; }
    public string ButtonTitle { get; set; }
    public string ButtonHtml { get; set; }
    public string Target { get; set; }
    public string ShortName {get;set;}
}
private List<SliderGame> Games { get; set; }

private int _Frequency = 5000;
private int Frequency {
    get {
        if (this.ViewData["Frequency"] != null)
        {
            int.TryParse(this.ViewData["Frequency"].ToString(), out _Frequency);
        }
        return _Frequency;
    }
}

/// <summary>
/// Get the games for the slider
/// </summary>
/// <returns></returns>
private List<SliderGame> GetGames()
{
    Dictionary<string, Game> allGames = CasinoEngineClient.GetGames();

    List<SliderGame> games = new List<SliderGame>();
        
    string [] paths = Metadata.GetChildrenPaths( (this.ViewData["Path"] as string).DefaultIfNullOrEmpty("/Casino/GameSlider") );
    string gameID, backgroundImage, title, text, url, target, buttonTitle, buttonHtml,shortName;
    Game game;
    foreach (string path in paths)
    {
        gameID = Metadata.Get(path + ".GameID");

        game = null;
        if (!allGames.TryGetValue(gameID, out game))
            continue;

        SliderGame sliderGame = new SliderGame() { Game = game };
        backgroundImage = Metadata.Get(path + ".BackgroundImage");
        if (!string.IsNullOrWhiteSpace(backgroundImage))
        {
            string backgroundImageUrl = ContentHelper.ParseFirstImageSrc( Metadata.Get(path + ".BackgroundImage") );
            if (!string.IsNullOrWhiteSpace(backgroundImageUrl))
                sliderGame.BackgroundImageUrl = backgroundImageUrl;
            else
                sliderGame.BackgroundImageUrl = backgroundImage;
        }
        else
        {
            sliderGame.BackgroundImageUrl = game.BackgroundImageUrl;
        }

        title = Metadata.Get(path + ".Title");
        if (!string.IsNullOrWhiteSpace(title))
        {
            sliderGame.Title = title.Replace("&nbsp;","");
        }
        else
            sliderGame.Title = game.Name;


        shortName = Metadata.Get(path + ".ShortName");
        if (!string.IsNullOrWhiteSpace(shortName))
        {
            sliderGame.ShortName = shortName;
        }
        else
            sliderGame.ShortName = game.ShortName;
            
        text = Metadata.Get(path + ".Text");
        if (!string.IsNullOrWhiteSpace(text))
        {
            sliderGame.Text = text;
        }
        else
            sliderGame.Text = game.Description;
        
        url = Metadata.Get(path + ".Url");
        if (!string.IsNullOrWhiteSpace(url))
        {
            sliderGame.Url = url;
        }
        else
            sliderGame.Url = this.Url.RouteUrl("CasinoGame", new { @action = "Index", @gameID = gameID });

        target = Metadata.Get(path + ".Target");
        if (!string.IsNullOrWhiteSpace(target))
        {
            sliderGame.Target = target;
        }
            
        buttonTitle = Metadata.Get(path + ".Button_Tooltip");
        if (!string.IsNullOrWhiteSpace(buttonTitle))
        {
            sliderGame.ButtonTitle = buttonTitle;
        }
        else
            sliderGame.ButtonTitle = sliderGame.Game.Name;
        
        buttonHtml = Metadata.Get(path + ".Button_Html");
        if (!string.IsNullOrWhiteSpace(buttonHtml))
        {
            sliderGame.ButtonHtml = buttonHtml;
        }
        games.Add(sliderGame);
    }

    return games;
}

</script>

<% this.Games = GetGames(); %>

<div id="casino_game_slider" class="Box Slider">
    <ol class="SliderContent">
<%
    List<JackpotInfo> jackpots = CasinoEngineClient.GetJackpots();
    int index = 0;
    string currency, url;
    foreach (SliderGame sliderGame in this.Games)
    {
        JackpotInfo jackpot = jackpots.FirstOrDefault(j => j.Games.Exists(g => g.ID == sliderGame.Game.ID));
        currency = "EUR";
        if( Profile.IsAuthenticated )
            currency = Profile.UserCurrency;
        if( jackpot != null && !jackpot.Amount.ContainsKey( currency ) )
            currency = "EUR";
        index++;
        %>
        <li class="SCItem SCItemId_<%=index.ToString()%>  SCItemGameId_<%=sliderGame.Game.ID.SafeHtmlEncode()%> <%= (index == 1) ? "Active" : "" %>" data-gameID="<%= sliderGame.Game.ID.SafeHtmlEncode() %>"
            style="background-image:url(&quot;<%= sliderGame.BackgroundImageUrl.SafeHtmlEncode() %>&quot;)"
            data-isFunModeEnabled="<%= sliderGame.Game.IsFunModeEnabled ? "1" : "0" %>">
            <h2 class="SCTitle">
                <a<%= !string.IsNullOrWhiteSpace(sliderGame.Target) ? string.Format(@" target=""{0}"" ", sliderGame.Target) : string.Empty %> href="<%= sliderGame.Url.SafeHtmlEncode() %>" class="SCLink" title="<%= sliderGame.ButtonTitle.SafeHtmlEncode() %>"><%= sliderGame.Title.HtmlEncodeSpecialCharactors() %></a>
            </h2>
            <p class="NormalInfo"><%= sliderGame.Text.HtmlEncodeSpecialCharactors() %></p>
            <a <%= !string.IsNullOrWhiteSpace(sliderGame.Target) ? string.Format(@" target=""{0}"" ", sliderGame.Target) : string.Empty %>href="<%= sliderGame.Url.SafeHtmlEncode() %>" class="Button BigButton" title="<%= sliderGame.ButtonTitle.SafeHtmlEncode() %>">
                <%if (string.IsNullOrWhiteSpace(sliderGame.ButtonHtml))
                  { %>
                <%= this.GetMetadata(".Button_Play").SafeHtmlEncode() %>
                <span class="ActionSymbol">&#9658;</span>
                <%}
                  else { %>
               <%=sliderGame.ButtonHtml.HtmlEncodeSpecialCharactors() %>    
               <%}%>
            </a>
            <% if( jackpot != null )
               { %>
                <p class="FeaturedInfo"><%= this.GetMetadata(".Jackpot").SafeHtmlEncode() %>
                    <span class="Cash"><%= MoneyHelper.FormatWithCurrencySymbol( currency, jackpot.Amount[currency])  %></span> 
                </p>
                <%-- <p class="FeaturedInfo">Record Payout: <span class="Cash">&euro;56.997</span> </p> --%>
            <% } %>
        </li>
        <%
    }
%>
    </ol>
    <ol class="SliderMenu Tabs Tabs-<%= this.Games.Count %> Container">

<%
    for (int i = 0; i < this.Games.Count; i++)
    {
        SliderGame sliderGame = this.Games[i];
        string cssClass = null;
        if (i == 0)
            cssClass = "First";
        else if (i == this.Games.Count - 1)
            cssClass = "Last";
         %>
        <li class="TabItem  TabItemId_<%=(i+1).ToString()%> <%= cssClass %>" data-gameID="<%= sliderGame.Game.ID.SafeHtmlEncode() %>">
            <a href="#" class="TabLink" title="<%= sliderGame.Title.SafeHtmlEncode() %>"><%=(i+1).ToString()%></a>
        </li>

<%  } %>
    </ol>
</div>

<script type="text/javascript">
    var GamesSlider = function(){
        self.GamesSlider = this;
        this.sliderHolder = $("#casino_game_slider");
        this.sliderContent =  this.sliderHolder.find(".SliderContent");       
        this.slideFrequency = <%=Frequency%>;

        this.slide = function(_currentGameID){                          
            if(_currentGameID)
            {
                this.currentControl = this.sliderHolder.find('ol.SliderMenu li[data-gameID="' + _currentGameID.scriptEncode() + '"]');
                this.currentSlide = this.sliderHolder.find('ol.SliderContent li[data-gameID="' + _currentGameID.scriptEncode() + '"]');
             }
             else
             {
                this.currentControl = this.lastControl.next("li.TabItem");
                if(this.currentControl.length>0)
                {
                    _currentGameID = this.currentControl.data('gameID') || this.currentControl.attr('data-gameID');                    
                    this.currentSlide = this.sliderHolder.find('ol.SliderContent li[data-gameID="' + _currentGameID.scriptEncode() + '"]');
                }
                else
                {
                    this.currentControl = this.sliderHolder.find('ol.SliderMenu > li.TabItem:first');
                    this.currentSlide = this.sliderHolder.find('ol.SliderContent > li.SCItem:first');
                }
             }
            
            this.sliderHolder.find(".SliderMenu").find("li.TabItem ").removeClass("Active");
            this.currentControl.addClass('Active');
            
            this.sliderContent.height(this.currentSlide.height());
                    
            this.lastSlide.fadeOut("fast","linear");
            this.currentSlide.fadeIn("normal","linear");            

            this.lastControl = this.currentControl;
            this.lastSlide = this.currentSlide;

            clearTimeout(this.slideTimer);
            this.slideTimer = window.setTimeout(function(){self.GamesSlider.slide();}, this.slideFrequency);   
        };

        this.init = function(){            
            this.lastControl = this.sliderHolder.find('ol.SliderMenu > li.TabItem:first');                  
            this.lastControl.addClass("Active");
            this.lastSlide = this.sliderHolder.find('ol.SliderContent > li.SCItem:first').show();            
            this.sliderContent.css("overflow","hidden");

            $('#casino_game_slider').find('ol.SliderMenu').find('li.TabItem a').click(function (e) {
                e.preventDefault();
                clearTimeout(self.GamesSlider.slideTimer);
                var $this = $(this)
                $this.blur();
                var currentGameID = $this.parent('li').data('gameID') || $this.parent('li').attr('data-gameID');                
                self.GamesSlider.slide(currentGameID);
            });
   
            this.slideTimer = window.setTimeout(function(){self.GamesSlider.slide();}, this.slideFrequency);    
        };

        this.init();
    };


    $(function () {        
        new GamesSlider();

        // <%-- click event to play --%>
        $('#casino_game_slider ol.SliderContent li a').click(function (e) {
            var $this = $(this);
            if($this.attr("target") && $this.attr("target").trim() != "")
            {
                return true;
            }
            var $li = $this.parents('li.SCItem');
<% if( !Profile.IsAuthenticated )
   { %>
            var isFunModeEnabled = ($li.data('isFunModeEnabled') || $li.attr('data-isFunModeEnabled')) == 1;
            if( !isFunModeEnabled ){
                e.preventDefault();
                alert('<%= this.GetMetadata(".AnonymousMessage").SafeJavascriptStringEncode() %>');
                return;
            }
<% } %>

            var gameID = $li.data('gameID') || $li.attr('data-gameID');
            
            try {
                var playForFun = <%= (!Profile.IsAuthenticated).ToString().ToLowerInvariant() %>;
                __loadGame(gameID, playForFun);
                e.preventDefault();
            }
            catch (e) {
                
            }
        });
    });

</script>