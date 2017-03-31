<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>

<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GmGamingAPI" %>

<script language="C#" type="text/C#" runat="server">


    protected bool IsMobile { get; set; }
    protected int RealityCheckTimeout { get; set; }

    private string SearchLanguageCulture(string langCode)
    {
        foreach (CultureInfo ci in CultureInfo.GetCultures(CultureTypes.SpecificCultures))
        {
            if (String.Compare(langCode, ci.TwoLetterISOLanguageName, StringComparison.InvariantCultureIgnoreCase) == 0)
            {
                return ci.Name;
            }
        }

        return langCode;
    }


    private string GetLanguageLocale()
    {
        string langCode = Language;
        if (UserSession != null && !String.IsNullOrWhiteSpace(UserSession.UserCountryCode))
        {
            langCode = String.Format("{0}-{1}", langCode, UserSession.UserCountryCode);
        }
        string locale;
        try
        {
            CultureInfo culture = CultureInfo.GetCultureInfo(langCode);
            locale = langCode;
        }
        catch // no regional culture for language
        {
            locale = SearchLanguageCulture(Language);
        }
        return locale.Replace('-', '_');
    }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        IsMobile = CE.Utils.PlatformHandler.IsMobile;
        bool supportMobile = Model.ClientCompatibility.SplitToList(",").Any(ci => ci.Equals("ipad", StringComparison.OrdinalIgnoreCase) ||
                                                                             ci.Equals("iphone", StringComparison.OrdinalIgnoreCase) ||
                                                                             ci.Equals("android", StringComparison.OrdinalIgnoreCase) ||
                                                                             ci.Equals("wf", StringComparison.OrdinalIgnoreCase));

        if (IsMobile && !supportMobile)
        {
            GmLogger.Instance.Warn(String.Format("Game {0} for vendor {1} launched on mobile but is not configured for mobile.", Model.GameID, Model.VendorID));
        }

        string startUrl;
        string urlTemplate = string.Empty;
        
        if (IsMobile)
        {
            if (!string.IsNullOrEmpty(this.Model.MobileGameLaunchUrl))
            {
                urlTemplate = this.Model.MobileGameLaunchUrl;
            }
            else
            {
                urlTemplate = (UserSession != null) ? Domain.GetCountrySpecificCfg(QuickSpin.GameMobileBaseURL, UserSession.UserCountryCode, UserSession.IpCountryCode) :
                Domain.GetCfg(QuickSpin.GameMobileBaseURL);                
            }

            urlTemplate += "&partnerid={1}&mode={2}&clientid={3}&moneymode={4}";
            startUrl = String.Format(urlTemplate, this.Model.GameID, Domain.GetCfg(QuickSpin.PartnerID),
               Domain.GetCfg(QuickSpin.Mode),
               Domain.GetCfg(QuickSpin.ClientID), FunMode ? "fun" : "real");
        }
        else
        {
            if (!string.IsNullOrEmpty(this.Model.GameLaunchUrl))
            {
                urlTemplate = this.Model.GameLaunchUrl;
            }
            else
            {
                urlTemplate = (UserSession != null) ? Domain.GetCountrySpecificCfg(QuickSpin.GameBaseURL, UserSession.UserCountryCode, UserSession.IpCountryCode) :
                    Domain.GetCfg(QuickSpin.GameBaseURL);
            }
            
            StringBuilder url = new StringBuilder();
            if (urlTemplate.Contains("?") && urlTemplate.Contains("{0}"))
            {
                url.AppendFormat(urlTemplate, this.Model.GameID);
            }
            else
            {
                url.Append(urlTemplate);
                url.AppendFormat("?gameid={0}", this.Model.GameID);
            }

            url.AppendFormat("&partnerid={0}&mode={1}&clientid={2}&moneymode={3}",
                    Domain.GetCfg(QuickSpin.PartnerID), Domain.GetCfg(QuickSpin.Mode), Domain.GetCfg(QuickSpin.ClientID), FunMode ? "fun" : "real");

            startUrl = url.ToString();
        }

        startUrl += String.Format("&language={0}", GetLanguageLocale());

        if (!FunMode)
        {
            TokenResponse response = GetToken();
            startUrl += String.Format("&ticket={0}", response.TokenKey);
            if (response.AdditionalParameters != null && response.AdditionalParameters.Exists(a => a.Name == "RealityCheckSec"))
            {
                RealityCheckTimeout = int.Parse(response.AdditionalParameters.First(a => a.Name == "RealityCheckSec").Value);
            }

            if (RealityCheckTimeout > 0 && IsMobile)
            {

                var pluginConfigUrl = this.Url.RouteUrl("Loader", new
                {
                    @action = "RealityCheckConfig",
                    @domainID = this.Model.DomainID,
                    @id = ((int)GamMatrixAPI.VendorID.QuickSpin).ToString(),
                    @realityCheckTimeout = RealityCheckTimeout
                });

                pluginConfigUrl = String.Format("{0}://{1}{2}", "https", "casino.gm.stage.everymatrix.com", pluginConfigUrl);
                startUrl += String.Format("&rciframeurl={0}", HttpUtility.UrlEncode(pluginConfigUrl));

            }

        }
        //RealityCheckTimeout = 60;
        //this.LaunchUrl ="https://d2drhksbtcqozo.cloudfront.net/casino/jetbull/flashTest/index.html?gameid=flashTest&partnerid=35&mode=prod&clientid=35&moneymode=real&language=en_029&ticket=ur52wC1yVkqHXn1hphtmhgMbwqxWDt~6";

        this.LaunchUrl = startUrl;

    }

</script>

<html xmlns="http://www.w3.org/1999/xhtml" lang="<%= this.Language %>">
<head>
    <title><%= this.Model.GameName.SafeHtmlEncode()%></title>
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" />
    <meta name="keywords" content="<%= this.Model.Tags.SafeHtmlEncode() %>" />
    <meta name="description" content="<%= this.Model.Description.SafeHtmlEncode() %>" />
    <meta http-equiv="pragma" content="no-cache" />
    <meta http-equiv="content-language" content="<%= this.Language %>" />
    <meta http-equiv="cache-control" content="no-store, must-revalidate" />
    <meta http-equiv="expires" content="Wed, 26 Feb 1997 08:21:57 GMT" />
    <style type="text/css">
        html, body {
            width: 100%;
            height: 100%;
            padding: 0px;
            margin: 0px;
            background: #E9E9E9;
            overflow: hidden;
        }

        #ifmGame {
            width: 100%;
            height: 100%;
            border: 0px;
        }
    </style>
    
    <% if (!IsMobile && RealityCheckTimeout > 0)
       { %>
    
    <script src="https://code.jquery.com/jquery-latest.min.js" type="text/javascript"></script>
    <script type="text/javascript" src="<%= Url.Content("~/js/realityCheck.js") %>"></script>
    
    <script type="text/javascript">

        // This script assumes that a server session duration time has been retrieved, and is set in duration parameter.
        // The duration is displayed using setter "inGameMessage" to the player in-game.
        // Time until reality check message, in seconds. In the example, it is every five minutes.
        
        var GAME_URL = "https://d2drhksbtcqozo.cloudfront.net/casino/jetbull/flashTest/index.html";
        var config = {
            beforeShowMessageFunction: beforeMessageShow,
            messageAcknowlegeFunction: afterMessageShow,
            realitychecktimeout: <%=RealityCheckTimeout%>,
            historyLink: '<%=Domain.LobbyUrl%>',
            lobbyLink: '<%=Domain.LobbyUrl%>'
        }
        
        window.addEventListener("message", function(event) {
            var fn = window[event.data.method];
            var parameters;
		
            if (event.data["params"]) {
                parameters = event.data.params;
            }
		
            if (isFunction(fn)) {
                fn.apply(null, [parameters]);
            }
        }, false);
	   
        // this method will be called when the game has been loaded
        function gameLoadedHandler() {
            startHandshake();
        }
        function gameLoaded() {
            startHandshake();
        }
   
        // starting the handshake process to make the game install the Reality check logic
        function startHandshake() {
            notifyGame('confirmHandshake', {success:'handshakeSuccess', fail:'handshakeFail'});    
        }

        // Handshake has been confirmed, means that the entire flow has been set and you can pause and resume the game when you want
        function handshakeSuccess() {
            console.log('handshake success');
            emrc.init(config);
        }
        
        // Handshake failed probably some issues during your setup (better to contact us to understand the reason)
        function handshakeFail() {
            console.log('handshake fail');
        }

        function beforeMessageShow() {
            console.log('requesting to pause the game, requesting the session_id return_data');
            notifyGame('pauseGame', {callback:"gamePausedHandler", return_data:['session_id']});
        }

        // The game received the pause request, has been paused and is displaying your iFrame right now. Do what is necessary in your side.
        function gamePausedHandler(params) {
            console.log('game paused:', params);
            console.log('game session_id:', params.session_id);
            emrc.show();
        }

        function afterMessageShow() {
            // Telling the game to close the iFrame and resume the paused game
            notifyGame('resumeGame');
        }
        
        function notifyGame(method, params) {
            document.getElementById('ifmGame').contentWindow.postMessage({method: method, params:params}, GAME_URL);
        }

        function isFunction(func) {
            return (typeof func === 'function');
        }

        window.onload = function () {
            // letting the game know that you are ready
            notifyGame("operatorLoaded");
        }

    
</script>	

    <% } %>

</head>
<body>

    <% if (IsMobile)
       { %>

    <script type="text/javascript">
        
        <%if (RealityCheckTimeout > 0)
          { %>

        //alert('Realitycheck alert...');

        if (typeof (Storage) !== "undefined") {

            // Store 
            localStorage.setItem("RealityCheckTimeout", <%=RealityCheckTimeout%> );
            localStorage.setItem("UserId", <%=UserSession.UserID%> );
            localStorage.setItem("DomainId", <%=Domain.DomainID%> );
            localStorage.setItem("LobbyUrl", '<%=Domain.MobileLobbyUrl%>' );
            localStorage.setItem("AccountUrl", '<%=Domain.MobileLobbyUrl%>' );
            localStorage.setItem("QuickSpinGameUrl", '<%=LaunchUrl%>' );
        }
        else
        {
            console.log('error - localstorage is not supported...');
        }
        
        <% } %>

        function __redirect() {
            try {
                self.location.replace('<%= this.LaunchUrl.SafeJavascriptStringEncode() %>');
            }
            catch (e) {
                self.location = '<%= this.LaunchUrl.SafeJavascriptStringEncode() %>';

             }
         }
         setTimeout(2000, __redirect());
    </script>

    <% }
       else
       { %>

    <iframe id="ifmGame" allowtransparency="true" frameborder="0" scrolling="no" src="<%= this.LaunchUrl %>"></iframe>
    <% Html.RenderPartial("GoogleAnalytics", this.Domain, new ViewDataDictionary()
       {
           {"Language", this.Language},
           {"IsLoggedIn", this.ViewData["UserSession"] != null},
       }
           ); %>
    <%= InjectScriptCode(QuickSpin.CELaunchInjectScriptUrl) %>
    
    
    <% } %>
</body>
</html>
