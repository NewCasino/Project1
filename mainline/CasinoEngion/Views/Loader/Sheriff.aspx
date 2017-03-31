<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmGamingAPI" %>

<script language="C#" type="text/C#" runat="server">
    public override string GetLanguage(string lang)
    {
        if (lang == null)
            return "en_US";

        switch (lang.ToLowerInvariant())
        {
            case "bg": return "bg_BG";
            case "cs": return "cs_CZ";
            case "da": return "da_DK";
            case "de": return "de_DE";
            case "el": return "el_GR";
            case "es": return "es_ES";
            case "fi": return "fi_FI";
            case "fr": return "fr_FR";
            case "hr": return "hr_HR";
            case "hu": return "hu_HU";
            case "it": return "it_IT";
            case "nl": return "nl_NL";
            case "no": return "nn_NO";
            case "pl": return "pl_PL";
            case "pt": return "pt_PT";
            case "ru": return "ru_RU";
            case "sv": return "sv_SE";
            case "tr": return "tr_TR";
            case "uk": return "uk_UA";
           
            default: return "en_US";
        }
    }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        Random rand = new Random();

        string playerReference = rand.Next().ToString();
        string sessionID = Guid.NewGuid().ToString("N");
        string mode = "free";
        string currency = "EUR";

        if (!FunMode)
        {
            mode = "real";
            playerReference = UserSession.UserID.ToString();

            if (UseGmGaming)
            {
                List<NameValue> addParams = new List<NameValue>()
                {
                    new NameValue {Name = "GameCode", Value = this.Model.GameCode}
                };

                TokenResponse response = GetToken(addParams);

                if (response.AdditionalParameters.Exists(a => a.Name == "UserCasinoCurrency"))
                    currency = response.AdditionalParameters.First(a => a.Name == "UserCasinoCurrency").Value;

                sessionID = response.TokenKey;
            }
            else
            {
                throw new CeException("GmGaming only valid to get token");
            }
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

        // http://games.sheriffgaming.com/loader/?site_id=4&amp;locale={0}&amp;game_id={1}&amp;mode={2}&amp;player_reference={3}&amp;currency={4}&amp;session_id={5}
        LaunchUrl = string.Format(CultureInfo.InvariantCulture, Domain.GetCfg(Sheriff.CasinoGameURL)
            , HttpUtility.UrlEncode(Language)
            , HttpUtility.UrlEncode(this.Model.GameID)
            , HttpUtility.UrlEncode(mode)
            , HttpUtility.UrlEncode(playerReference)
            , HttpUtility.UrlEncode(currency)
            , HttpUtility.UrlEncode(sessionID)
            );

        if (isMobileGame)
        {
            this.LaunchUrl = string.Format("{0}&lobby_url={1}", this.LaunchUrl, HttpUtility.UrlEncode(Domain.MobileLobbyUrl));
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
    <%=InjectScriptCode(Sheriff.CELaunchInjectScriptUrl) %>
</body>
</html>