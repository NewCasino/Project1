<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>
<%@ Import Namespace="CE.db" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmGamingAPI" %>

<script language="C#" type="text/C#" runat="server">
    /// <summary>
    /// Get the supported locale ID for Live Casino
    /// </summary>
    /// <param name="lang">language codes</param>
    /// <returns>LCID in DEC</returns>
    public override string GetLanguage(string lang)
    {
        string langugeCulture = "en-GB";
        if (!string.IsNullOrWhiteSpace(lang))
        {
            if (string.Equals(lang.Truncate(2), "en", StringComparison.InvariantCultureIgnoreCase))
            {
                langugeCulture = "en-GB";
            }
            else if (string.Equals(lang.Truncate(2), "fr", StringComparison.InvariantCultureIgnoreCase))
            {
                langugeCulture = "fr-FR";
            }
            else
            {
                switch (lang.ToLowerInvariant())
                {
                    case "hu":
                        langugeCulture = "hu-HU";
                        break;
                    case "tr":
                        langugeCulture = "hu-HU";
                        break;
                    case "it":
                        langugeCulture = "it-IT";
                        break;
                    case "el":
                        langugeCulture = "el-GR";
                        break;
                    case "es":
                        langugeCulture = "es-ES";
                        break;
                    case "de":
                        langugeCulture = "de-DE";
                        break;
                    case "pt":
                        langugeCulture = "pt-PT";
                        break;
                    case "ru":
                        langugeCulture = "ru-RU";
                        break;
                    case "ja":
                        langugeCulture = "ja-JP";
                        break;
                    case "th":
                        langugeCulture = "th-TH";
                        break;
                    default:
                        langugeCulture = "en-GB";
                        break;
                }
            }
        }
        CultureInfo ci = new CultureInfo(langugeCulture);
        return ci.LCID.ToString();
    }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        if (UserSession == null || FunMode)
            throw new CeException("XProGaming game is only available in real money mode.");

        Dictionary<string, ceLiveCasinoTableBaseEx> tables = global::CacheManager.GetLiveCasinoTableDictionary(Domain.DomainID);
        ceLiveCasinoTableBaseEx table;
        if (!tables.TryGetValue(TableID, out table))
            throw new CeException("Invalid table id [{0}]", TableID);

        bool isLobbyMode;
        bool.TryParse(Domain.GetCfg(CE.DomainConfig.XProGaming.LiveCasinoShowMiniLobby), out isLobbyMode);

        if (UseGmGaming)
        {
            List<NameValue> addParams = new List<NameValue>()
            {
                new NameValue { Name = "UserLanguage", Value = this.Language },
                new NameValue { Name = "GameType", Value = ((int)XProGaming.GameType.AllGames).ToString() },
                new NameValue { Name = "IncludeOnlineOnlyLimits", Value = "0" },
                new NameValue { Name = "LimitSetIdPerGame", Value = GetLimitSetIdForGame(table)},
            };

            TokenResponse response = GetToken(addParams);

            XElement gameNode;
            XNamespace ns;

            string currency = UserSession.Currency;
            if (response.AdditionalParameters.Exists(a => a.Name == "UserCasinoCurrency"))
            {
                currency = response.AdditionalParameters.First(a => a.Name == "UserCasinoCurrency").Value;
            }

            if (response.AdditionalParameters.Exists(a => a.Name == "GamesListWithLimitsResponse"))
            {
                string gamesListWithLimitsResponse = response.AdditionalParameters.First(a => a.Name == "GamesListWithLimitsResponse").Value;
                CheckIfLimitSetIdInResponse(table, currency, gamesListWithLimitsResponse, out ns, out gameNode);
            }
            else
            {
                throw new CeException("No GamesListWithLimitsResponse was provided on GetToken() for XProGaming: userId {0}, domainId:{1} ", UserSession.UserID, UserSession.DomainID);
            }

            if (response.AdditionalParameters.Exists(a => a.Name == "LaunchUrl"))
            {
                this.LaunchUrl = response.AdditionalParameters.First(a => a.Name == "LaunchUrl").Value;
            }

        }
        else
        {
            XProGamingAPIRequest request = new XProGamingAPIRequest()
            {
                GetGamesListWithLimits = true,
                GetGamesListWithLimitsGameType = (int)XProGaming.GameType.AllGames,
                GetGamesListWithLimitsOnlineOnly = 0,
                GetGamesListWithLimitsUserName = UserSession.Username,
                GetUserCurrency = true,
                GetUserCurrencyUserName = UserSession.Username,
            };

            using (GamMatrixClient client = new GamMatrixClient())
            {
                request = client.SingleRequest<XProGamingAPIRequest>(UserSession.DomainID, request);
                LogGmClientRequest(request.SESSION_ID, request.GetGamesListWithLimitsResponse, "GamesWithLimits");
            }

            /*
            <response xmlns="apiGamesLimitsListData" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <gamesList>
                    <game>
                        <limitSetList>
                        <limitSet>
                        <limitSetID>1</limitSetID>
                        <minBet>0.50</minBet>
                        <maxBet>20.00</maxBet>
                        </limitSet>
                        <limitSet>
                        <limitSetID>4</limitSetID>
                        <minBet>0.00</minBet>
                        <maxBet>400000.00</maxBet>
                        </limitSet>
                        </limitSetList>
                        <gameID>1</gameID>
                        <gameType>1</gameType>
                        <gameName>Europe Test 1 LCPP</gameName>
                        <dealerName>Dealer</dealerName>
                        <dealerImageUrl>
                        http://lcpp.xprogaming.com/LiveGames/Games/dealers/1.jpg
                        </dealerImageUrl>
                        <isOpen>1</isOpen>
                        <connectionUrl>
                        https://lcpp.xprogaming.com/LiveGames/GeneralGame.aspx?audienceType=1&gameID=1&operatorID=135&languageID={1}&loginToken={2}&securityCode={3}
                        </connectionUrl>
                        <winParams>
                        'width=955,height=690,menubar=no, scrollbars=no,toolbar=no,status=no,location=no,directories=no,resizable=yes,left=' + (screen.width - 955) / 2 + ',top=20'
                        </winParams>
                        <openHour>00:00</openHour>
                        <closeHour>00:00</closeHour>
                        <PlayersNumber xsi:nil="true"/>
                        <PlayersNumberInGame xsi:nil="true"/>
                    </game>
                </gamesList>
            </response>
                * */

            XElement gameNode;
            XNamespace ns;

            CheckIfLimitSetIdInResponse(table, request.GetUserCurrencyResponse, request.GetGamesListWithLimitsResponse, out ns, out gameNode);

            string connectionUrl = gameNode.Parent.Element(ns + "connectionUrl").Value;

            using (GamMatrixClient client = new GamMatrixClient())
            {
                XProGamingGameLaunchRequest launchRequest = new XProGamingGameLaunchRequest
                {
                    UserID = UserSession.UserID,
                    GameURL = connectionUrl,
                    LanguageID = Language,

                };
                // seems not used
                /*
                 if (!string.IsNullOrWhiteSpace(limitSetID))
                    request.RegisterTokenProps = string.Format(CultureInfo.InvariantCulture, "LimitSetID:{0}", limitSetID);
                */

                launchRequest = client.SingleRequest<XProGamingGameLaunchRequest>(UserSession.DomainID, launchRequest);
                LogGmClientRequest(request.SESSION_ID, launchRequest.RedirectURL, "RedirectURL");
                this.LaunchUrl = launchRequest.RedirectURL;
            }
        }

        if(isLobbyMode) 
        {
            this.LaunchUrl = GetLobbyLaunchUrl(this.LaunchUrl);
        }

        Response.Redirect(this.LaunchUrl);
    }

    private string GetLobbyLaunchUrl(string gameLaunchUrl)
    {
        Uri gameUrl = new Uri(gameLaunchUrl);
        NameValueCollection gameUrlParams = HttpUtility.ParseQueryString(gameUrl.Query);
        string operatorId = gameUrlParams.Get("operatorID");
        string token = gameUrlParams.Get("loginToken");
        string languageId = gameUrlParams.Get("languageID");

        string lobbyUrl = string.Format(Domain.GetCfg(CE.DomainConfig.XProGaming.MiniLobbyBaseURL), operatorId, token, languageId);
        return lobbyUrl;
    }

    private string GetLimitSetIdForGame(ceLiveCasinoTableBaseEx table)
    {
        string limitSetIdList = string.Empty;
        StringBuilder listBuilder = new StringBuilder();

        if (!string.IsNullOrWhiteSpace(table.ExtraParameter2))
        {
            JavaScriptSerializer jss = new JavaScriptSerializer();
            Dictionary<string, string> limitSetIDPerCurrency = null;
            try
            {
                limitSetIDPerCurrency = jss.Deserialize<Dictionary<string, string>>(table.ExtraParameter2);
            }
            catch
            {
            }

            if (limitSetIDPerCurrency != null)
            {
                foreach( var item in limitSetIDPerCurrency)
                {
                    if (!string.IsNullOrEmpty(item.Value))
                    {
                        listBuilder.AppendFormat("{0}:{1};", item.Key, item.Value);
                    }
                }
            }
        }
        listBuilder.AppendFormat("Default:{0}", table.ExtraParameter1);

        limitSetIdList = listBuilder.ToString();

        return limitSetIdList;
    }

    private void CheckIfLimitSetIdInResponse(ceLiveCasinoTableBaseEx table, string currency, string gamesListWithLimitsResponse,out XNamespace ns, out XElement gemeNode)
    {
        string limitSetID = null;
        // get the limitsetid for specific currency
        if (!string.IsNullOrWhiteSpace(table.ExtraParameter2))
        {
            JavaScriptSerializer jss = new JavaScriptSerializer();
            Dictionary<string, string> limitSetIDPerCurrency = null;
            try
            {
                limitSetIDPerCurrency = jss.Deserialize<Dictionary<string, string>>(table.ExtraParameter2);
            }
            catch
            {
            }

            if (limitSetIDPerCurrency != null)
            {
                limitSetIDPerCurrency.TryGetValue(currency, out limitSetID);
            }
        }

        // if no specific limitsetid, get the default one
        if (string.IsNullOrWhiteSpace(limitSetID))
        {
            limitSetID = table.ExtraParameter1;
        }

        // if no default limit set id, throw an exception
        if (string.IsNullOrWhiteSpace(limitSetID))
        {
            throw new CeException("No limit set id is configured for XProGaming table [{0}].", table.ID);
        }

        XDocument xDoc = XDocument.Parse(gamesListWithLimitsResponse);
        XNamespace nspace = xDoc.Root.GetDefaultNamespace();
        gemeNode = xDoc.Descendants().SingleOrDefault(p => p.Name == nspace + "gameID" && string.Equals(p.Value, this.Model.GameID));
        if (gemeNode == null)
        {
            throw new CeException("There is no table whose gameID is [{0}] in XProGaming's raw feeds. (UserID = {1}; Currency = {2})"
                , this.Model.GameID
                , UserSession.UserID
                , currency
                );
        }

        // check if limitsetid exists
        XElement limitSetNode = gemeNode.Parent.Element(nspace + "limitSetList").Descendants()
            .SingleOrDefault(p => p.Name == nspace + "limitSetID" && string.Equals(p.Value, limitSetID));
        if (limitSetNode == null)
        {
            throw new CeException("Limit set ID [{0}] is not found in XProGaming's raw feeds for table [{1}]."
                , limitSetID
                , this.Model.GameID
                );
        }
        ns = nspace;
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
</body>
</html>