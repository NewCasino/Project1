<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CasinoEngine.Game>" %>
<%@ Import Namespace="CasinoEngine" %>
<%@ Import Namespace="System.Globalization" %>
<script runat="server" type="text/C#">
    private string GetLicensesTypeJson()
    {
        string[] paths = Metadata.GetChildrenPaths("/Metadata/Casino/GameLicenses");
        StringBuilder sb = new StringBuilder();
        sb.Append("{");
        string value;
        
        for(int i =0; i < paths.Length; i++)
        {
            value = this.GetMetadata(paths[i] + ".Value");
            if (!string.IsNullOrEmpty(value))
            {
                sb.AppendFormat(CultureInfo.InvariantCulture, @" ""{0}"" : ""{1}"" ", paths[i].Substring(paths[i].LastIndexOf("/") + 1).ToLowerInvariant(), value.SafeJavascriptStringEncode());
                if (i < paths.Length-1)
                {
                    sb.Append(", ");
                }
            }
        }
        sb.Append("}");
        return sb.ToString();
    }
    private string GetVenderIDs() {
        Type w = typeof(GamMatrixAPI.VendorID);
        Array a = Enum.GetValues(w);
        StringBuilder sb = new StringBuilder();
        sb.Append("{");
        for (int i = 0; i < a.Length; i++) {
            sb.AppendFormat(CultureInfo.InvariantCulture, @" ""{0}"" : ""{1}"" ", a.GetValue(i).ToString().ToLowerInvariant(), this.GetMetadata("/Casino/Hall/GameOpenerWidget/_GameFrame_snippet.License_" + a.GetValue(i)).SafeJavascriptStringEncode());
            if (i < a.Length - 1)
            {
                sb.Append(", ");
            }
        }
        sb.Append("}");
        return sb.ToString();
    }
</script>
<div class="GameArea">
	<div class="GameBody">
		<div class="GameContainer" align="center" style="min-height:400px">
			
		</div>
		<div class="Incentive">
			<p class="IncentiveParagraph"><%= this.GetMetadata(".Incentive_Without_Jackpot_HTML") %></p>
		</div>
		<div class="controller Container">
            <h2 class="GameTitle"></h2>
			<ul class="ControllerButtons Container">
				<li class="CB CBBack">
					<a class="Button" >
                        <span class="InfoIcon GameBack"><%= this.GetMetadata(".Button_Back").SafeHtmlEncode() %></span>
                        <span><%= this.GetMetadata(".Button_Back").SafeHtmlEncode() %></span>
                    </a>
				</li>
				<li class="CB CBFull">
					<a class="Button">
                        <span class="InfoIcon FullGame"><%= this.GetMetadata(".Button_Fullscreen").SafeHtmlEncode()%></span>
                        <span><%= this.GetMetadata(".Button_Fullscreen").SafeHtmlEncode()%></span>
                    </a>
				</li>
				<li class="CB CBRules">
					<a class="Button" target="_blank">
                    <span class="InfoIcon GameInfo"><%= this.GetMetadata(".Button_Rules").SafeHtmlEncode()%></span>
                    <span><%= this.GetMetadata(".Button_Rules").SafeHtmlEncode()%></span>
                    </a>
				</li>
                <li class="CB CBFavorite">
					<a class="Button" target="_blank">
                    <span class="InfoIcon Favorite"><%= this.GetMetadata(".Button_Favorite").SafeHtmlEncode()%></span>
                    <span><%= this.GetMetadata(".Button_Favorite").SafeHtmlEncode()%></span>
                    </a>
				</li>
			</ul>		
		</div>   
        <div class="License Container hide"></div> 
	</div>
</div>
 
 
<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="true" AppendToPageEnd="true">
<script type="text/javascript"> 
    var gameLicenses = <%=GetLicensesTypeJson() %>; 
    var venderIDs = <%=GetVenderIDs()%>;
    function __loadCasinoGame(gameID, playForFun, height) {

        var url = '<%= this.Url.RouteUrl( "CasinoLobby", new { @action = "GetGameInfo" }).SafeJavascriptStringEncode() %>';
        $.getJSON(url, { gameID: gameID, playForFun: playForFun }, function (json) {
            if (!json.success) {
                var errorMessage = '';
                switch(json.errorCode)
                {
                    case "-1": 
                        errorMessage = '<%= this.GetMetadata(".Error_FunModeNotAvailable").SafeJavascriptStringEncode() %>';
                        alert(errorMessage); 
                        break;
                    case "-2": 
                        errorMessage = '<%= this.GetMetadata(".Error_AnonymousFunModeNotAvailable").SafeJavascriptStringEncode() %>';
                        alert(errorMessage); 
                        break;
                    case "-3": 
                        errorMessage = '<%= this.GetMetadata(".Error_RealModeNotAvailable").SafeJavascriptStringEncode() %>';
                        alert(errorMessage); 
                        break;
                    case "-4": 
                        errorMessage = '<%= this.GetMetadata(".Error_SessionTimedout").SafeJavascriptStringEncode() %>';
                        alert(errorMessage); 
                        self.location = self.location.toString().replace("realMoney=True", "realMoney=False"); 
                        return;
                    case "-5": 
                        errorMessage = '<%= this.GetMetadata(".Error_EmailNotVerified").SafeJavascriptStringEncode() %>';
                        alert(errorMessage);
                        break;
                    default: break;
                }
                var params = { GameID: gameID, ErrorCode: json.errorCode, Error: json.error, ErrorMessage: errorMessage};
                $(document).trigger("CASINOENGINE_GAME_ERROR",params);
                return;
            }

            $('div.GameArea h2.GameTitle').text(json.game.ShortName);
            $('div.GameArea div.License').html("").hide();
            if(gameLicenses[json.game.LicenseType.toLowerCase()])
            {
                var tc = venderIDs[json.game.VendorID.toLowerCase()];
                var tc_default = "<%=this.GetMetadata("/Casino/Hall/GameOpenerWidget/_GameFrame_snippet.License_Default").SafeJavascriptStringEncode()%>";
                var tc_License = json.game.LicenseType.substr(0,1).toUpperCase() +  json.game.LicenseType.substr(1,json.game.LicenseType.length - 1 );
                var tcTxt = (tc == undefined || tc == null || tc == "") ? tc_default.format(tc_License) : tc.format(tc_License)   ; 
                if(!playForFun && playForFun != "true"){
                    $('div.GameArea div.License').html(tcTxt).show();   
                }     
            } 
            // <%-- the Game Rules button --%>
            if (json.game.HelpUrl !== null && json.game.HelpUrl != '') {
                $('div.GameArea ul.ControllerButtons li.CBRules').show();
                $('div.GameArea ul.ControllerButtons li.CBRules a').attr('href', json.game.HelpUrl);
            }
            else {
                $('div.GameArea ul.ControllerButtons li.CBRules').hide();
            }

            // <%-- the Add to Favorites button --%>
            $('div.GameArea ul.ControllerButtons li.CBFavorite a').data('gameID', gameID);
            
            $('div.GameArea ul.ControllerButtons li.CBFavorite').show();
            if( typeof(GDATA) != 'undefined' ){
                for( var i = 0; i < GDATA["Favorites"].length; i++){
                    if( GDATA["Favorites"][i] == gameID ){
                        $('div.GameArea ul.ControllerButtons li.CBFavorite').hide();
                        break;
                    }
                }
            }

            $('div.GameArea div.GameContainer').empty();

            __adjustIncentiveParagraph(json.game);

            $('<iframe id="ifmCasinoGame" frameborder="0" scrolling="no" width="100%" height="100%" style="margin:0 auto;"></iframe>').attr('src', playForFun ? json.game.FunModeUrl : json.game.RealMoneyModeUrl).appendTo($('div.GameArea div.GameContainer'));

            if( json.game.Height > 0 && json.game.Width > 0){
                if(height == null || height <= 0 ){
                    height = $('#ifmCasinoGame').width() * json.game.Height / (1.0 * json.game.Width);
                    if( height > json.game.Height ){
                        height = json.game.Height;
                        $('#ifmCasinoGame').width( json.game.Width );
                    }
                    $('#ifmCasinoGame').height(height);
                }
                else if( height > 0 ) {
                    $('#ifmCasinoGame').height(height);

                    var width = height * json.game.Width / (json.game.Height * 1.0);
                    $('#ifmCasinoGame').width(width);
                    $('div.GameBody').width(width);
                }
            }

            $('<iframe src="/_session_keep_alive.ashx?duration=30" style="display:none" class="ifmKeepSessionAlive"></iframe>').appendTo(document.body);

            var params = { GameID: gameID};
            $(document).trigger("CASINOENGINE_GAME_LAUNCHED",params);
        });
    }


    $(function(){
        $('div.GameArea ul.ControllerButtons li.CBFavorite a').unbind('click').click(function(e){
            e.preventDefault();

            var gameID = $(this).data('gameID');
            var url = '<%= this.Url.RouteUrl("CasinoLobby", new { @action = "AddToFavorites" }).SafeJavascriptStringEncode()%>';
            if( typeof(GDATA) != 'undefined' ){
                GDATA["Favorites"].push(gameID);
            }
            var callback = (function (o) {
                return function () {
                    $('li.GLItem[data-gameID="' + gameID.scriptEncode() + '"] a.BtnAddFavorite').parent('li.GTPItem').fadeOut();
                    $('div.GameArea ul.ControllerButtons li.CBFavorite').fadeOut();
                };
            })(gameID);

            $.getJSON(url, { gameID: gameID }, callback);
        });
        
    });

    function __unloadCasinoGame() {
        $('div.GameArea h2.GameTitle').text('');
        $('div.GameArea div.GameContainer').empty();
        $('iframe.ifmKeepSessionAlive').remove();
    }

    function __adjustIncentiveParagraph(game) {
        var logo_html = '<%= this.GetMetadata(".Logo_HTML").SafeJavascriptStringEncode() %>';
        var showIncentiveForLogo = false;
        if(logo_html.trim() != '')
        {
            showIncentiveForLogo = true;
            var GameWindow_Logo = $('div.GameArea div.Incentive').find('.GameWindow_Logo');
            if(GameWindow_Logo.length==0)
                $('div.GameArea div.Incentive').append('<p class="GameWindow_Logo"></p><div style="clear:both"></div>');
            $('div.GameArea div.Incentive').find('.GameWindow_Logo').html(logo_html);
        }

        if (!game.PlayForFun) {
            if(showIncentiveForLogo)
            {
                $('div.GameArea .IncentiveParagraph').hide();
                $('div.GameArea div.Incentive').show();
            }
            else
                $('div.GameArea div.Incentive').hide();
            return;
        } else {
            $('div.GameArea .IncentiveParagraph').show();
            $('div.GameArea div.Incentive').show();            
            var html = '';
            if (game.JackpotAmount > 0.00) {
                html = '<%= this.GetMetadata(".Incentive_HTML").SafeJavascriptStringEncode() %>';
                html = html.replace(/(\{0\})/g, game.JackpotMoney);
            }
            else {
                html = '<%= this.GetMetadata(".Incentive_Without_Jackpot_HTML").SafeJavascriptStringEncode() %>';
            }

            $('div.GameArea div.Incentive p.IncentiveParagraph').html(html);
            $('div.GameArea div.Incentive p.IncentiveParagraph a.IncentiveButton')
                .data('gameID', game.ID)
                .click(function (e) {
                    e.preventDefault();

<% if ( !Profile.IsAuthenticated )
   { %>
            try {
                var gameid = $(this).parents(".GLItem").data("gameid");
                showAdditional(true, gameid);
            } catch(e) {
                alert( '<%= this.GetMetadata(".AnonymousMessage").SafeJavascriptStringEncode() %>' );
            }
            
            return;
<% } %>

                    __loadCasinoGame($(this).data('gameID'), false);
                });

            //$('div.GameArea div.GameContainer').height(
            //    $('div.GameArea').height() - $('div.GameArea div.Container').height() - $('div.GameArea div.Incentive').height()
            //);
        }
    }

    

</script> 
</ui:MinifiedJavascriptControl>