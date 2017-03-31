<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<List<CasinoEngine.JackpotInfo>>" %>
<%@ Import Namespace="CasinoEngine" %>
<%@ Import Namespace="Finance" %>

<script type="text/C#" runat="server">
    protected bool IsHall { get {
            bool _isHall = false;
            if (this.ViewData["IsHall"] != null) {
                bool.TryParse(this.ViewData["IsHall"].ToString(), out _isHall);
            }
            return _isHall;
        }
    }
    
    private bool? _FilterRepeatedGame = null;
    public bool FilterRepeatedGame {
        get {
            if (!_FilterRepeatedGame.HasValue) {
                if (this.ViewData["FilterRepeatedGame"] != null) {
                    _FilterRepeatedGame = (bool)this.ViewData["FilterRepeatedGame"];
                }

                if (!_FilterRepeatedGame.HasValue) {
                    _FilterRepeatedGame = false;
                }
            }
            
            return _FilterRepeatedGame.Value;
        }
    }    
</script>

<%
    string currency = "EUR";
    if (Profile.IsAuthenticated && !string.IsNullOrEmpty(Profile.UserCurrency) )
        currency = Profile.UserCurrency;

    decimal totalAmount = this.Model.Where(j => j.Games.Count > 0 && j.Amount.Keys.Contains(currency)).Sum(j => j.Amount[currency]);
 %>
<div class="Box Jackpots Jackpots-Page">
    <h2 class="BoxTitle JackpotsTitle">
        <strong class="TitleText"> <%= this.GetMetadataEx(".Subtitle_Format", MoneyHelper.FormatWithCurrencySymbol( currency, totalAmount)).SafeHtmlEncode() %></strong>
    </h2>
    <div class="JackpotCanvas">
        <ul class="JackpotList">
            <%
                List<string> jackpotGameIDs = new List<string>(); 
                foreach (JackpotInfo jackpotInfo in this.Model) {
                    foreach (Game game in jackpotInfo.Games)     {
                        if (FilterRepeatedGame && jackpotGameIDs.Exists(i => i.Equals(game.ID, StringComparison.InvariantCultureIgnoreCase)))
                            continue;
                        if (!jackpotInfo.Amount.Keys.Contains(currency))
                            continue;        
                        
                        jackpotGameIDs.Add(game.ID);
                        
                        string currencySymbol = Metadata.Get(string.Format("Metadata/Currency/{0}.Symbol", currency));
                        string money = string.Format("{0} {1:n0}", currencySymbol.DefaultIfNullOrEmpty(currency), jackpotInfo.Amount[currency]);
                        string url = this.Url.RouteUrl("CasinoGame", new { @action = "Index", @gameID = game.ID }).SafeHtmlEncode();
            %>
            <li class="JLItem ChampionOfTheTrack">
                <img width="120" height="120" class="GameIcon" src="<%= game.LogoUrl.SafeHtmlEncode() %>" alt="<%= game.Name.SafeHtmlEncode() %>" />
                <div class="JI-GameTitle">
                    <span class="JLMoney Cash"><%= money.SafeHtmlEncode() %></span>
                    <h3 class="JLGame"><%= game.Name.SafeHtmlEncode() %></h3>
                    <p class="JI-GameDesc"><%= game.Description.SafeHtmlEncode() %></p>
                    <a href="<% =url.SafeHtmlEncode() %>" title="<%= game.Name.SafeHtmlEncode() %>" class="JLItem-Link Button" data-gameID="<%= game.ID.SafeHtmlEncode() %>" data-isFunModeEnabled="<%= game.IsFunModeEnabled ? "1" : "0" %>">
                        <%= this.GetMetadata(".Play_Now").SafeHtmlEncode() %>
                        <span class="ActionSymbol">&#9658;</span>
                    </a>
                </div>
            </li>
            <%
            }
        }
        %>
        </ul>
    </div>
</div>

<script type="text/javascript">
    $(function () {
        // <%-- click event to play --%>
        $('div.Jackpots ul.JackpotList li a.JLItem-Link').click(function (e) {
            <% if( !Profile.IsAuthenticated ) { %>
                e.preventDefault();
                var isFunModeEnabled = ($(this).data('isFunModeEnabled') || $(this).attr('data-isFunModeEnabled')) == 1;
                if( !isFunModeEnabled ){
                    alert('<%= this.GetMetadata(".AnonymousMessage").SafeJavascriptStringEncode() %>');
                    return;
                }
            <% } %>

            var gameID = $(this).data('gameID') || $(this).attr('data-gameID');
            
            try {
                var playForFun = <%= (IsHall ? Profile.IsAuthenticated : !Profile.IsAuthenticated).ToString().ToLowerInvariant() %>;
                __loadGame(gameID, !playForFun);//the parameter is gameID and real, not gameID and funMode
                e.preventDefault();
            }
            catch (ex) { }
        });
    });
</script>