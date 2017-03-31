<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>

<%@ Import Namespace="System.Web.Script.Serialization" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Extensions" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmGamingAPI" %>

<script language="C#" type="text/C#" runat="server">

    private string TargetServer { get; set; }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        string ipCountryCode = null;
        ISoftBetIntegration.GameModel iGame = null;

        bool mobileDevice = CE.Utils.PlatformHandler.IsMobile;

        bool htmlGame = Model.GameID.EndsWith("_html", StringComparison.InvariantCultureIgnoreCase) || Model.GameID.EndsWith("_html5", StringComparison.InvariantCultureIgnoreCase);
        
        if (UserSession == null)
        {
            FunMode = true;

            ipCountryCode = IPLocation.GetByIP(Request.GetRealUserAddress()).CountryCode;

            //AlwaysLoadSettingsFormTargetServer = Domain.GetCountrySpecificCfg(ISoftBet.AlwaysLoadSettingsFormTargetServer, ipCountryCode).SafeParseToBool(false);

            TargetServer = Domain.GetCountrySpecificCfg(ISoftBet.TargetServer, ipCountryCode);
            iGame = ISoftBetIntegration.GameManager.Get(Domain, this.Model.GameID, htmlGame, this.Language, ipCountryCode);
        }
        else
        {
            //AlwaysLoadSettingsFormTargetServer = Domain.GetCountrySpecificCfg(ISoftBet.AlwaysLoadSettingsFormTargetServer, UserSession.UserCountryCode, UserSession.IpCountryCode).SafeParseToBool(false);

            TargetServer = Domain.GetCountrySpecificCfg(ISoftBet.TargetServer, UserSession.UserCountryCode, UserSession.IpCountryCode);
            iGame = ISoftBetIntegration.GameManager.Get(Domain, this.Model.GameID, htmlGame, this.Language, UserSession.UserCountryCode, UserSession.IpCountryCode);
        }

        if (iGame == null)
            throw new CeException("Error, failed to find the Casino Game [{0}].", this.Model.GameID);

        if (!TargetServer.EndsWith("/", StringComparison.InvariantCultureIgnoreCase))
            TargetServer += "/";

        if (FunMode)
        {
            if (!iGame.FunModel)
                throw new CeException("Error, The Game [{0}] can't be played in fun mode.", this.Model.GameID);
        }
        else
        {
            if (!iGame.RealModel)
                throw new CeException("Error, The Game [{0}] can't be played in real mode.", this.Model.GameID);
        }

        if (!FunMode && iGame.UserIDs != null && iGame.UserIDs.Length > 0)
        {
            if (!iGame.UserIDs.Contains(UserSession.UserID.ToString()))
                throw new CeException("Error, You are not allowed to play the Game [{0}].", this.Model.GameID);
        }

        string iSessionID = null;
        string currency = "EUR";
        int realityCheck = 0;
        
        if (!FunMode && UserSession != null)
        {
            if (UseGmGaming)
            {
                TokenResponse response = GetToken();

                if (response.AdditionalParameters.Exists(a => a.Name == "UserCasinoCurrency"))
                    currency = response.AdditionalParameters.First(a => a.Name == "UserCasinoCurrency").Value;

                if (response.AdditionalParameters.Exists(a => a.Name == "RealityCheckSec"))
                    realityCheck = int.Parse(response.AdditionalParameters.First(a => a.Name == "RealityCheckSec").Value) / 60;

                iSessionID = response.TokenKey;
            }
            else
            {
                throw new CeException("GmGaming only valid to get token");
            }
        }
        //http://<launcher_url>/{LICENSEE_ID}/{SKIN_ID}?lang={LANGUAGE}&cur={CURRENCY}&mode={GAME_MODE}&user={USER_NAME}&uid={USER_ID}&token={SESSION_ID}

        string playUrlTemplate = TargetServer;
        
        StringBuilder url = new StringBuilder();
        url.Append(playUrlTemplate);
        url.AppendFormat("{0}/{1}?lang={2}&cur={3}&mode={4}",
             Domain.GetCfg(ISoftBet.LicenseID), iGame.GameID, this.Language, currency, FunMode ? "0" : "1");

        if (!FunMode && UserSession != null)
        {
            url.AppendFormat("&user={0}&uid={1}&token={2}", this.UserSession.Username, UserSession.UserID, iSessionID);
        }
        
        url.AppendFormat("&table={0}", 0);
       
        if (mobileDevice)
        {            
            url.AppendFormat("&lobbyUrl={0}", HttpUtility.UrlEncode(Domain.MobileLobbyUrl));
            AddRealityCheckParameters(url, realityCheck, HttpUtility.UrlEncode(Domain.MobileAccountHistoryUrl));
            
            this.LaunchUrl = url.ToString();
            Response.Redirect(LaunchUrl);
        }
        else
        {
            url.AppendFormat("&lobbyUrl={0}", HttpUtility.UrlEncode(Domain.LobbyUrl));
            AddRealityCheckParameters(url, realityCheck, HttpUtility.UrlEncode(Domain.MobileAccountHistoryUrl));
            
            this.LaunchUrl = url.ToString();
        }
    }
    
    private void AddRealityCheckParameters( StringBuilder url, int realityCheck, string historyLink)
    {
        if (realityCheck > 0)
        {
            // link to send player to game history page
            string history = HttpUtility.UrlEncode(historyLink);
            url.AppendFormat("&historyURL={0}&rci={1}", history, realityCheck);
        }
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
</head>
<body>
    
    <iframe id="ifmGame" allowtransparency="true" frameborder="0" scrolling="no" src="<%= this.LaunchUrl %>"></iframe>
    <% Html.RenderPartial("GoogleAnalytics", this.Domain, new ViewDataDictionary()
           {
               { "Language", this.Language},
               { "IsLoggedIn", this.ViewData["UserSession"] != null },
           }
           ); %>
    <%=InjectScriptCode(ISoftBet.CELaunchInjectScriptUrl) %>

</body>
</html>
