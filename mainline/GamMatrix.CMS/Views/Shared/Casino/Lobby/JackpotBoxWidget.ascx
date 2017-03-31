<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<List<CasinoEngine.JackpotInfo>>" %>
<%@ Import Namespace="CasinoEngine" %>
<%@ Import Namespace="Finance" %>

<%
    string currency = "EUR";
    if (Profile.IsAuthenticated && !string.IsNullOrWhiteSpace(Profile.UserCurrency))
    {
        if( this.Model.Count > 0 && this.Model[0].Amount.ContainsKey(Profile.UserCurrency) )
            currency = Profile.UserCurrency;
    }

    decimal totalAmount = this.Model.Where( j => j.Games.Count > 0 && j.Amount.ContainsKey(currency) ).Sum(j => j.Amount[currency]);
 %>
<div class="Box Jackpots">
	<h2 class="BoxTitle JackpotsTitle">
		<span class="TitleIcon">&sect;</span>

        <% if (!string.IsNullOrWhiteSpace(this.ViewData["AllJackpotsPageUrl"] as string))
           { %>
		<a href="<%= (this.ViewData["AllJackpotsPageUrl"] as string).SafeHtmlEncode() %>" 
            class="TitleLink" title="<%= this.GetMetadata(".All_Jackpots_Link_Tip").SafeHtmlEncode()%>">
            <%= this.GetMetadata(".All_Jackpots_Link").SafeHtmlEncode()%> <span class="ActionSymbol">&#9658;</span>
        </a>
        <% } %>

		<strong class="TitleText">
            <%= this.GetMetadata(".Title").SafeHtmlEncode() %>
            <span class="TitleDeemphasized">
                <%= this.GetMetadataEx(".Subtitle_Format"
                , MoneyHelper.FormatWithCurrencySymbol( currency, totalAmount)
                ).SafeHtmlEncode() %>
            </span>
        </strong>
	</h2>
	<ul class="JackpotsControl Controls">
		<li class="Prev">
			<a href="#" class="PreviousLink" title="<%= this.GetMetadata(".Previous_Jackpot_Tip").SafeHtmlEncode()%>">&#9668;</a>
		</li>
		<li class="Next">
			<a href="#" class="NextLink" title="<%= this.GetMetadata(".Next_Jackpot_Tip").SafeHtmlEncode()%>">&#9658;</a>
		</li>
	</ul>
	<div class="JackpotCanvas">
		<ul class="JackpotList">

    <%
        string currencySymbol = Metadata.Get(string.Format("Metadata/Currency/{0}.Symbol", currency));
        foreach (JackpotInfo jackpotInfo in this.Model)
        {
            if (!jackpotInfo.Amount.ContainsKey(currency))
                continue;
            
            foreach (Game game in jackpotInfo.Games)
            {
                string money = string.Format("{0} {1:n0}"
                    , currencySymbol.DefaultIfNullOrEmpty(currency)
                    , jackpotInfo.Amount[currency]
                    );
                %>
                
            
			<li class="JLItem" data-gameID="<%= game.ID.SafeHtmlEncode() %>" 
                data-isFunModeEnabled="<%= game.IsFunModeEnabled ? "1" : "0" %>"
                data-isAnonymousFunModeEnabled="<%= game.IsAnonymousFunModeEnabled ? "1" : "0" %>">
				<h3 class="JLTitle">
					<a href="<%= this.Url.RouteUrl("CasinoGame", new { @action = "Index", @gameID = game.ID }).SafeHtmlEncode() %>" class="JLLink" title="<%= this.GetMetadataEx(".Play_Now_Format", game.ShortName).SafeHtmlEncode() %>">
						<img class="GameIcon" src="<%= game.LogoUrl.SafeHtmlEncode() %>" width="120" height="120" alt="<%= game.ShortName.SafeHtmlEncode() %>" />
						<strong class="JLGame"><%= game.ShortName.SafeHtmlEncode() %></strong>
						<span class="JLMoney Cash"><%= money.SafeHtmlEncode() %></span>
					</a>
				</h3>
			</li>


<%
            }
        }
            %>

		</ul>
	</div>
</div>

<ui:MinifiedJavascriptControl runat="server" Enabled="true" AppendToPageEnd="true">
<script type="text/javascript">
    $(function () {
        $('div.Jackpots ul.JackpotsControl a.PreviousLink').click(function (e) {
            e.preventDefault();
        });

        $('div.Jackpots ul.JackpotsControl a.NextLink').click(function (e) {
            e.preventDefault();
        });

        var direction = 0;
        $('div.Jackpots ul.JackpotsControl a.PreviousLink').mouseover(function (e) {
            direction = -1;
            startAnimation();
        });

        $('div.Jackpots ul.JackpotsControl a.NextLink').mouseover(function (e) {
            direction = 1;
            startAnimation();
        });

        $('div.Jackpots ul.JackpotsControl a.NextLink,div.Jackpots ul.JackpotsControl a.PreviousLink').mouseout(function (e) {
            direction = 0;
        });

        function startAnimation(){
            if( $('div.Jackpots ul.JackpotList li:animated').length > 0 )
                return;
            
            if( direction == 0 ){
                return;
            }
            if( direction < 0 ){
                var $first = $('div.Jackpots ul.JackpotList > li:first');
                $first.clone(true).appendTo($('div.Jackpots ul.JackpotList'));
                $first.animate({ 'marginLeft': -1 * $first.width() }
                , {
                    duration: 500,
                    easing: 'linear',
                    complete: function () { $(this).remove(); $('div.Jackpots ul.JackpotList li:animated').stop(); startAnimation(); }
                });
            }
            else {
                var $last = $('div.Jackpots ul.JackpotList > li:last');
                var $first = $last.clone(true).prependTo($('div.Jackpots ul.JackpotList'));
                $first.css('marginLeft', -1 * $last.width());
                $first.animate({ 'marginLeft': 0 }
                , {
                    duration: 500,
                    easing: 'linear',
                    complete: function () { $('div.Jackpots ul.JackpotList > li:last').remove(); $('div.Jackpots ul.JackpotList li:animated').stop(); startAnimation(); }
                });
            }
        }




        // <%-- click event to play --%>
        $('div.Jackpots ul.JackpotList li[data-gameID]').click(function (e) {
<% if( !Profile.IsAuthenticated )
   { %>            
            var isFunModeEnabled = ($(this).data('isFunModeEnabled') || $(this).attr('data-isFunModeEnabled')) == 1;
            if( !isFunModeEnabled ){
                alert('<%= this.GetMetadata(".AnonymousMessage").SafeJavascriptStringEncode() %>');
                e.preventDefault();
                return;
            }
            
            var isAnonymousFunModeEnabled = ($(this).data('isAnonymousFunModeEnabled') || $(this).attr('data-isAnonymousFunModeEnabled')) == 1;
            if( !isAnonymousFunModeEnabled ){
                alert('<%= this.GetMetadata(".AnonymousFunModeDisabledMessage").SafeJavascriptStringEncode() %>');
                e.preventDefault();
                return;
            }
<% } %>

            var gameID = $(this).data('gameID') || $(this).attr('data-gameID');
            
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
</ui:MinifiedJavascriptControl>