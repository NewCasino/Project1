<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="System.ComponentModel" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Diagnostics.Eventing.Reader" %>
<%@ Import Namespace="CE.db" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script language="C#" type="text/C#" runat="server">
    public override string GetLanguage(string lang)
    {
        if (string.IsNullOrWhiteSpace(lang))
            return "EN";
        /*
        DE = German
        EN = English
        ES = Spanish
        FI = Finish
        NL = Dutch
        GR = Greek
        NO = Norwich
        SE = Swedish
        FR = French
        IT = Italian
        GE = Georgian
        ID = Indonesian
        JA = Japanese
        KO = Korean
        TH = Thai
        CH = Chinese Simplified
        ZH = Chinese Traditional
        */
        lang = lang.ToUpperInvariant();
        switch (lang)
        {
            case "DE":
            case "EN":
            case "ES":
            case "FI":
            case "NL":
            case "NO":
            case "FR":
            case "IT":
            case "ID":
            case "KO":
            case "TH":
                break;

            case "JA":
                lang = "JP";
                break;

            case "EL":
                lang = "GR";
                break;

            case "SV":
                lang = "SE";
                break;

            case "KA":
                lang = "GE";
                break;

            case "ZH":
            case "ZH-CN":
                lang = "CH";
                break;

            case "ZH-TW":
            case "ZH-HK":
            case "ZH-MO":
                lang = "ZH";
                break;

            default:
                lang = "EN";
                break;
        }

        return lang;
    }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        string showLiveLobby = Domain.GetCfg(Vivo.LiveCasinoShowLobby);
        StringBuilder url = new StringBuilder();
        string token = string.Empty;
        long operatorID = 0;
        long.TryParse(Domain.GetCfg(Vivo.OperatorID), out operatorID);
        string serverID = Domain.GetCfg(Vivo.ServerID);
        bool isMobile = CE.Utils.PlatformHandler.IsMobile;

        if (this.GameID.ContainsIgnoreCase("Spinomenal") || this.GameID.ContainsIgnoreCase("Betsoft") || this.GameID.ContainsIgnoreCase("BBTECH"))
        {
            string slotOperatorID = Domain.GetCfg(Vivo.SlotOperatorId);
            string gameId = string.Empty;
            string subvendorName = string.Empty;
            var gameDetails = this.GameID.Split('~');
            if (gameDetails.Length == 2)
            {
                subvendorName = gameDetails[0];
                gameId = gameDetails[1];
            }
            else
            {
                throw new CeException("Wrong GameId for Vivo subvendor games. GameId : " + this.GameID);
            }
            bool funMode = UserSession == null || FunMode;
            token = !funMode? GetToken().TokenKey : string.Empty;
            string launchUrlTemplate = string.Empty;
            switch (subvendorName.ToLower())
            {
                case "spinomenal":
                    launchUrlTemplate = funMode ? Domain.GetCfg(Vivo.SpinomenalCasinoFunUrl) : Domain.GetCfg(Vivo.SpinomenalCasinoBaseUrl);
                    url.AppendFormat(launchUrlTemplate, token, gameId, slotOperatorID);
                    break;
                case "betsoft":
                    launchUrlTemplate = funMode ? Domain.GetCfg(Vivo.BetsoftCasinoFunUrl) : Domain.GetCfg(Vivo.BetsoftCasinoBaseUrl);
                    url.AppendFormat(launchUrlTemplate, token, gameId, slotOperatorID);
                    break;
                case "bbtech":
                    launchUrlTemplate = funMode ? Domain.GetCfg(Vivo.BBTECHCasinoFunUrl) : Domain.GetCfg(Vivo.BBTECHCasinoBaseUrl);
                    url.AppendFormat(launchUrlTemplate, token, gameId, slotOperatorID);
                    break;
                default:
                    throw new CeException("Wrong prefix for Vivo subvendor games. prefix : " + subvendorName.ToLower());
            }
        }
        else
        {
            if (UserSession == null || FunMode)
                throw new CeException("Vivo Live Casino is only available in real money mode!");

            token = GetToken().TokenKey;
            if (showLiveLobby != "true")
            {
                Dictionary<string, ceLiveCasinoTableBaseEx> tables = global::CacheManager.GetLiveCasinoTableDictionary(Domain.DomainID);
                ceLiveCasinoTableBaseEx table;
                if (!tables.TryGetValue(TableID, out table))
                    throw new CeException("Invalid table id [{0}]", TableID);

                string webServiceUrl = Domain.GetCfg(Vivo.VivoWebServiceUrl);
                List<VivoActiveTable> vivoTables;

                vivoTables = VivoAPI.LiveCasinoTable.GetActiveTables(webServiceUrl, UserSession.DomainID, operatorID, this.Model.ExtraParameter2, UserSession.Currency);

                long vivoTableID = 0;
                long.TryParse(table.ExtraParameter1, out vivoTableID);

                // check if limit id is number and use old logic GAI-1491
                VivoActiveTable vivoTable = null;
                long vivoLimitID;
                if (table.ExtraParameter2.ToLower() == "lobby")
                {
                    string currency = UserSession.Currency;

                    if (isMobile)
                        url.Append(Domain.GetCfg(Vivo.LiveCasinoLobbyMobileUrl)); 
                    else
                        url.Append(Domain.GetCfg(Vivo.LiveCasinoLobbyBaseUrl));
                    url.AppendFormat(@"?token={0}&operatorID={1}&serverID={2}&language={3}&logoSetup={4}&isPlaceBetCTA={5}&PlayerCurrency={6}",
                        HttpUtility.UrlEncode(token),
                        operatorID,
                        HttpUtility.UrlEncode(serverID),
                        HttpUtility.UrlEncode(this.Language),
                        Domain.GetCfg(Vivo.CELogoSetup),
                        false,
                        currency);
                }
                else
                {
                    if (long.TryParse(table.ExtraParameter2, out vivoLimitID))
                    {
                        if (vivoTables != null && vivoTables.Exists(t => t.TableID == vivoTableID && t.LimitID == vivoLimitID))
                        {
                            vivoTable = vivoTables.First(t => t.TableID == vivoTableID && t.LimitID == vivoLimitID);
                        }
                    }
                    else
                    {
                        if (vivoTables != null && vivoTables.Exists(t => t.TableID == vivoTableID && t.LimitName.ToLower() == table.ExtraParameter2.ToLower()))
                        {
                            vivoTable = vivoTables.First(t => t.TableID == vivoTableID && t.LimitName.ToLower() == table.ExtraParameter2.ToLower());
                        }
                    }

                    if (vivoTable == null)
                        throw new CeException("Can't find the table (table id [{0}], vivo table id[{1}])", TableID, table.ExtraParameter2);

                    if (isMobile)
                    {
                        if (this.Model.ExtraParameter2.ToLower() != "roulette" && this.Model.ExtraParameter2.ToLower() != "baccarat")
                            throw new CeException("Game is not supported as mobile version - [{0}]", this.Model.ExtraParameter2.ToLower());
                        url.AppendFormat(Domain.GetCfg(Vivo.LiveCasinoMobileUrl), this.Model.ExtraParameter2);
                    }
                    else
                        url.AppendFormat(Domain.GetCfg(Vivo.LiveCasinoBaseUrl), this.Model.ExtraParameter1);

                    url.AppendFormat(@"?token={0}&operatorID={1}&tableID={2}&LimitID={3}&serverID={4}&language={5}",
                        HttpUtility.UrlEncode(token),
                        operatorID,
                        vivoTable.TableID,
                        vivoTable.LimitID,
                        HttpUtility.UrlEncode(serverID),
                        HttpUtility.UrlEncode(this.Language));
                }
            }
            else
            {
                string currency = UserSession.Currency;
                if (isMobile)
                    url.Append(Domain.GetCfg(Vivo.LiveCasinoLobbyMobileUrl));
                else
                    url.Append(Domain.GetCfg(Vivo.LiveCasinoLobbyBaseUrl));
                url.AppendFormat(@"?token={0}&operatorID={1}&serverID={2}&language={3}&logoSetup={4}&isPlaceBetCTA={5}&PlayerCurrency={6}",
                    HttpUtility.UrlEncode(token),
                    operatorID,
                    HttpUtility.UrlEncode(serverID),
                    HttpUtility.UrlEncode(this.Language),
                    Domain.GetCfg(Vivo.CELogoSetup),
                    false,
                    currency);
            }
        }

        this.LaunchUrl = url.ToString();
        if (isMobile)
        {
            Response.Redirect(url.ToString());
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
    <%=InjectScriptCode(Vivo.CELaunchInjectScriptUrl) %>
</body>
</html>