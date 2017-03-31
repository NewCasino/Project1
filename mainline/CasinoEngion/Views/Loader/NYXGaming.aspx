<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmGamingAPI" %>

<script language="C#" type="text/C#" runat="server">
    public override string GetLanguage(string lang)
    {
        switch (lang.ToLowerInvariant())
        {
            case "en": return "en_us";
            case "sv": return "sv_se";
            case "fi": return "fi_sf";
            case "es": return "es_es";
            case "fr": return "fr_fr";
            case "de": return "de_de";
            case "it": return "it_it";
            case "nl": return "nl_nl";
            case "el": return "el_gr";
            case "ja": return "ja_jp";
            case "ko": return "ko_kp";
            case "no": return "no_no";
            case "pt": return "pt_pt";
            case "ru": return "ru_ru";
            case "tr": return "tr_tr";
            case "dk": return "dk_dk";
            case "pl": return "pl_pl";
            case "bg": return "bg_bg";
            case "hr": return "hr_hr";
            case "cs": return "cs_cz";
            case "hu": return "hu_hu";
            case "uk": return "uk_ua";
            case "zh": return "zh_cn";
            case "zh-cn": return "zh_cn";
            case "zh-tw": return "zh_tw";
			case "da": return "da_dk";
            default: return "en_us";
        }
    }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        string url;
        int realityCheck = 0;
        // Play for free
        if (UserSession == null || FunMode)
        {
            string currency = string.IsNullOrEmpty(Domain.DomainDefaultCurrencyCode) ? "EUR" : Domain.DomainDefaultCurrencyCode;
			if (Language.Equals("da_dk", StringComparison.InvariantCultureIgnoreCase))
                currency = "DKK";
            if (UserSession != null && !string.IsNullOrEmpty(UserSession.Currency))
                currency = UserSession.Currency;

            // http://nogs-gl-stage.nyxinteractive.eu/game/?nogsgameid={0}&nogslang={1}&nogscurrency={2}&nogsmode=demo&nogsoperatorid=1
            url = string.Format(CultureInfo.InvariantCulture, Domain.GetCfg(NYXGaming.CasinoGameFunModeURL)
                , this.Model.GameID
                , Language
                , currency
                );
        }
        else // real mode
        {
            string currency = string.Empty, accountId = string.Empty, sessionId = string.Empty;
            
            if (UseGmGaming)
            {
                TokenResponse response = GetToken();

                if (response.AdditionalParameters.Exists(a => a.Name == "UserCasinoCurrency"))
                    currency = response.AdditionalParameters.First(a => a.Name == "UserCasinoCurrency").Value;

                if (response.AdditionalParameters.Exists(a => a.Name == "AccountId"))
                    accountId = response.AdditionalParameters.First(a => a.Name == "AccountId").Value;

                if (response.AdditionalParameters.Exists(a => a.Name == "RealityCheckSec"))
                    realityCheck = int.Parse(response.AdditionalParameters.First(a => a.Name == "RealityCheckSec").Value);

                sessionId = response.TokenKey;
            }
            else
            {
                throw new CeException("GmGaming only valid to get token");
            }

            // http://nogs-gl-stage.nyxinteractive.eu/game/?nogsgameid={0}&nogslang={1}&nogscurrency={2}&accountid={3}&&sessionid={4}&nogsmode=real&nogsoperatorid=1
            url = string.Format(CultureInfo.InvariantCulture, Domain.GetCountrySpecificCfg(NYXGaming.CasinoGameRealMoneyModeURL, UserSession.UserCountryCode, UserSession.IpCountryCode)
                , this.Model.GameID
                , Language
                , currency
                , accountId
                , sessionId
                );
            
        }

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

        if (!isMobileGame)
        {
            this.LaunchUrl = string.Format(CultureInfo.InvariantCulture, "{0}&clienttype=flash", url);
            AddRealityCheckParameters(realityCheck, Domain.LobbyUrl, Domain.AccountHistoryUrl);
        }
        else
        {
            this.LaunchUrl = string.Format(CultureInfo.InvariantCulture, "{0}&clienttype=html5&lobbyurl={1}"
                , url
                , HttpUtility.UrlEncode(Domain.MobileLobbyUrl)
                );
            AddRealityCheckParameters(realityCheck, Domain.MobileLobbyUrl, Domain.MobileAccountHistoryUrl);
            Response.Redirect(this.LaunchUrl);
        }
    }

    private void AddRealityCheckParameters(int realityCheck, string lobbyUrl, string historyLink)
    {

        if (realityCheck > 0)
        {
            string realityTemplate = "&jurisdiction=uk&realitycheck_uk_elapsed={0}&realitycheck_uk_limit={1}&realitycheck_uk_proceed={2}&realitycheck_uk_exit={3}&realitycheck_uk_history={4}";
            string elapsed = "0";
            string proceed = "";
            // link for player to come back to lobby
            string exit = HttpUtility.UrlEncode(lobbyUrl);
            // link to send player to game history page
            string history = HttpUtility.UrlEncode(historyLink);

            this.LaunchUrl += string.Format(realityTemplate, elapsed, realityCheck, proceed, exit, history);
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
    <%=InjectScriptCode(NYXGaming.CELaunchInjectScriptUrl) %>
</body>
</html>