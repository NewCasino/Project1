<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmGamingAPI" %>
<script language="C#" type="text/C#" runat="server">
    public override string GetLanguage(string lang)
    {
        switch (lang.ToLowerInvariant())
        {
            case "sv":
            case "es":
            case "it":
            case "fi":
            case "de":
            case "fr":
            case "pt":
            case "bg":
            case "pl":
            case "ro":
            case "cs":
            case "hu":
            case "sk":
            case "da":
            case "el":
                return lang;

            case "no":
                return "nn";

            case "en-gb":
                return "gb";

            case "zh":
            case "zh-cn":
            case "zh-sg":
                return "zh-chs";

            case "zh-hk":
            case "zh-mo":
            case "zh-tw":
                return "zh-cht";

            default:
                return "en";
        }
    }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        bool isMobileGame = !this.Model.ClientCompatibility.ToLowerInvariant().Contains(",pc,");
        StringBuilder url = new StringBuilder();
        if (isMobileGame)
            url.Append(Domain.GetCfg(BallyGaming.MobileGameBaseURL));
        else
            url.Append(Domain.GetCfg(BallyGaming.CasinoGameBaseURL));
        
        Dictionary<string, BallyIntegration.Game> games = GamMatrixClient.GetBallyGames(DomainManager.CurrentDomainID);
        BallyIntegration.Game ballyGame;
        if (!games.TryGetValue(this.Model.GameID, out ballyGame))
            throw new CeException("Error: Can't find the game [{0}]!", this.Model.GameID);

        if (ballyGame.CurrencyCode.Count == 0)
            throw new CeException("Error: No currency found for the game [{0}]!", this.Model.GameID);
        
        
        url.AppendFormat("?softwareId={0}", HttpUtility.UrlEncode(this.Model.GameID));
        url.AppendFormat("&operatorid={0}", HttpUtility.UrlEncode(Domain.GetCfg(BallyGaming.OperatorID)));
        url.AppendFormat("&skinid={0}", HttpUtility.UrlEncode(Domain.GetCfg(BallyGaming.SkinID)));
        url.AppendFormat("&language={0}", this.Language);
        
        if (UserSession == null || FunMode)
        {
            //url
            url.AppendFormat("&DemoMode=True&RealPlay=0");
        }
        else
        {
            string currency = string.Empty;
            string token = string.Empty;
            if (UseGmGaming)
            {
                TokenResponse response = GetToken();

                if (response.AdditionalParameters.Exists(a => a.Name == "UserCasinoCurrency"))
                    currency = response.AdditionalParameters.First(a => a.Name == "UserCasinoCurrency").Value;

                token = response.TokenKey;
            }
            else
            {
                throw new CeException("GmGaming only valid to get token");
            }

            // url
            if (!ballyGame.CurrencyCode.Exists( c=>c.Equals(currency, StringComparison.InvariantCultureIgnoreCase)))
            {
                currency = "EUR";
            }
            
            url.AppendFormat("&playerid={0}", HttpUtility.UrlEncode(UserSession.UserID.ToString()));
            url.AppendFormat("&currencycode={0}", HttpUtility.UrlEncode(currency));
            url.AppendFormat("&countrycode={0}", HttpUtility.UrlEncode(UserSession.UserCountryCode));

            url.AppendFormat("&authtype=Token&authtoken={0}", HttpUtility.UrlEncode(token));

            url.Append("&DemoMode=False&RealPlay=1");

            string affiliateMarker = UserSession.AffiliateMarker;
            if (!string.IsNullOrWhiteSpace(affiliateMarker))
                url.AppendFormat("&affiliateid={0}", HttpUtility.UrlEncode(affiliateMarker));
        }
        
        this.LaunchUrl = url.ToString();
        if (isMobileGame)
        {
            string mobileUrl = this.LaunchUrl;
            if (!string.IsNullOrWhiteSpace(Domain.MobileLobbyUrl))
                mobileUrl = mobileUrl + "&lobbyUrl=" + HttpUtility.UrlEncode(Domain.MobileLobbyUrl);
            Response.Redirect(mobileUrl);
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
    <%=InjectScriptCode(BallyGaming.CELaunchInjectScriptUrl) %>
</body>
</html>