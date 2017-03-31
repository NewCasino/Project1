<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="System.Xml" %>
<%@ Import Namespace="CasinoEngine.Controllers" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmGamingAPI" %>

<script language="C#" type="text/C#" runat="server">

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        string skinCode = Domain.GetCfg(IGT.CasinoGameSkinCode);
        string userName = Domain.GetCfg(IGT.UserName);
        string password = Domain.GetCfg(IGT.Password);
        string uri = Domain.GetCfg(IGT.GameListV2URL);

        Dictionary<string, IGTIntegration.Game> games = GamMatrixClient.GetIGTGames(DomainManager.CurrentDomainID, skinCode, uri, userName, password);
        IGTIntegration.Game game;
        if (!games.TryGetValue(this.Model.GameID, out game))
            throw new CeException("Error: Can't find the game [{0}]!", this.Model.GameID);

        if (game.Configurations.Count == 0)
            throw new CeException("Error: No currency found for the game [{0}]!", this.Model.GameID);

        bool isMobileGame = false;
        switch (Request.GetTerminalType())
        {
            case TerminalType.iPad:
            case TerminalType.iPhone:
            case TerminalType.Android:
                isMobileGame = true;
                break;

            default:
                break;
        }

        StringBuilder url = new StringBuilder();

        if (!isMobileGame)
        {
            url.Append(Domain.GetCfg(IGT.CasinoGameBaseURL));

            if (!game.Url.StartsWith("/"))
                url.Append("/");
            url.Append(game.Url);
        }
        else
        {
            url.Append(Domain.GetCfg(IGT.MobileGameBaseURL));
        }

        // Check the supported languages for this game
        if (game.LanguageCodes != null && game.LanguageCodes.Length > 0)
        {
            if (game.LanguageCodes.FirstOrDefault(l => l == Language) == null)
                Language = game.LanguageCodes.FirstOrDefault(l => l == "en");

            if (Language == null)
                Language = game.LanguageCodes[0];
        }


        url.AppendFormat("?softwareid={0}", HttpUtility.UrlEncode(game.SoftwareID));
        url.AppendFormat("&language={0}", HttpUtility.UrlEncode(Language));
        url.AppendFormat("&nscode={0}", HttpUtility.UrlEncode(Domain.GetCfg(IGT.CasinoGameNSCode)));
        url.AppendFormat("&skincode={0}", HttpUtility.UrlEncode(Domain.GetCfg(IGT.CasinoGameSkinCode)));
        url.AppendFormat("&E024_domainid={0:D}", Domain.DomainID);


        // Play for free
        if (UserSession == null || FunMode)
        {
            url.Append("&currencycode=FPY");
            url.AppendFormat("&uniqueid={0}", Guid.NewGuid().ToString("N"));

            string ip = Request.GetRealUserAddress();
            if (!string.IsNullOrWhiteSpace(ip))
            {
                IPLocation ipLocation = IPLocation.GetByIP(ip);
                if (ipLocation != null)
                {
                    url.AppendFormat("&countrycode={0}", HttpUtility.UrlEncode(ipLocation.CountryCode));
                }
            }
            else
            {
                url.AppendFormat("&countrycode=GB");
            }

            if (isMobileGame)
            {
                url.Append("&minbet=1.0");
                url.Append("&denomamount=1.0");
            }
        }
        // Real Money
        else
        {
            string casinoUserID = string.Empty;
            string token = string.Empty;
            string currency = UserSession.Currency;
            if (UseGmGaming)
            {
                TokenResponse response = GetToken();
                if (response.AdditionalParameters.Exists(a => a.Name == "UserCasinoCurrency"))
                {
                    currency = response.AdditionalParameters.First(a => a.Name == "UserCasinoCurrency").Value;
                }
                
                if (response.AdditionalParameters.Exists(a => a.Name == "CasinoUserID"))
                    casinoUserID = response.AdditionalParameters.First(a => a.Name == "CasinoUserID").Value;

                token = response.TokenKey;
            }
            else
                using (GamMatrixClient client = new GamMatrixClient())
                {
                    IGTGetSessionRequest request;
                    request = new IGTGetSessionRequest()
                    {
                        UserID = UserSession.UserID,
                    };
                    request = client.SingleRequest<IGTGetSessionRequest>(UserSession.DomainID, request);
                    LogGmClientRequest(request.SESSION_ID, request.Token);

                    casinoUserID = request.CasinoUserID;
                    token = request.Token;
                }

            url.AppendFormat("&uniqueid={0}", casinoUserID);
            url.AppendFormat("&countrycode={0}", HttpUtility.UrlEncode(UserSession.UserCountryCode));
            url.AppendFormat("&securetoken={0}", HttpUtility.UrlEncode(token));

            string affiliateMarker = UserSession.AffiliateMarker;
            if (!string.IsNullOrWhiteSpace(affiliateMarker))
                url.AppendFormat("&affiliateid={0}", HttpUtility.UrlEncode(affiliateMarker));

            //
            // [07:00:44 PM] Oleg Shema: as a hot solution, please do always send EUR on PLayAdjara
            List<IGTIntegration.Configuration> configs = null;
            if (!game.Configurations.TryGetValue(currency, out configs))
            {
                currency = "EUR";
                if (!game.Configurations.TryGetValue(currency, out configs))
                {
                    currency = game.Configurations.First().Key;
                    configs = game.Configurations.First().Value;
                }
            }
            url.AppendFormat("&currencycode={0}", HttpUtility.UrlEncode(currency));

            if (isMobileGame)
            {
                IGTIntegration.Configuration config = configs.OrderBy(c => c.DenomAmount).FirstOrDefault();
                if (config == null)
                    throw new CeException("Error: No configuration found for the game [{0}] in {1} currency!", this.Model.GameID, currency);

                url.AppendFormat("&minbet={0:f2}", config.MinBet);
                url.AppendFormat("&denomamount={0:f2}", config.DenomAmount);
            }
        }

        string lobbyUrl = isMobileGame ? Domain.MobileLobbyUrl : Domain.LobbyUrl;
        url.AppendFormat("&{0}_lobbyurl={1}", Domain.GetCfg(IGT.CasinoGameSkinCode), HttpUtility.UrlEncode(lobbyUrl));

        string cashierUrl = isMobileGame ? Domain.MobileCashierUrl : Domain.CashierUrl;
        url.AppendFormat("&{0}_cashierurl={1}", Domain.GetCfg(IGT.CasinoGameSkinCode), HttpUtility.UrlEncode(cashierUrl));

        this.LaunchUrl = url.ToString();
        if (isMobileGame)
        {
            Response.Redirect(this.LaunchUrl);
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
    <meta http-equiv="X-UA-Compatible" content="requiresActiveX=true" /> 
    <style type="text/css">
    html, body { width:100%; height:100%; padding:0px; margin:0px; background:#E9E9E9; overflow:hidden; }
    #ifmGame { width:100%; height:100%; border:0px; }
    </style>
</head>
<body>
    <iframe id="ifmGame" allowTransparency="true" frameborder="0" scrolling="no" src="<%= this.LaunchUrl.SafeHtmlEncode() %>"></iframe>
    <% Html.RenderPartial("GoogleAnalytics", this.Domain, new ViewDataDictionary()
           {
               { "Language", this.Language},
               { "IsLoggedIn", this.ViewData["UserSession"] != null },
           }
           ); %>
    <%=InjectScriptCode(IGT.CELaunchInjectScriptUrl) %>
</body>
</html>