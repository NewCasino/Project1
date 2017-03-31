<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmGamingAPI" %>

<script language="C#" type="text/C#" runat="server">
    private string TargetServer { get; set; }

    public override string GetLanguage(string lang)
    {
        if (string.IsNullOrWhiteSpace(lang))
            return "en";

        lang = lang.ToLowerInvariant();
        switch (lang)
        {
            case "zh-cn":
                lang = "zh";
                break;
        }

        if (ISoftBetIntegration.GameMgt.SupportedLanguages.Contains(lang))
            return lang;

        return "en";
    }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        bool isMobileGame = !this.Model.ClientCompatibility.ToLowerInvariant().Contains(",pc,");
        string ipCountryCode = null;
        ISoftBetIntegration.GameModel iGame = null;

        if (UserSession == null)
        {
            FunMode = true;

            ipCountryCode = IPLocation.GetByIP(Request.GetRealUserAddress()).CountryCode;
            TargetServer = Domain.GetCountrySpecificCfg(ISoftBet.TargetServer, ipCountryCode);
            //iGame = ISoftBetIntegration.GameMgt.Get(domain, this.Model.GameID, funMode, true, this.Language, ipCountryCode);
            iGame = ISoftBetIntegration.GameManager.Get(Domain, this.Model.GameID, true, this.Language, ipCountryCode);
        }
        else
        {
            TargetServer = Domain.GetCountrySpecificCfg(ISoftBet.TargetServer, UserSession.UserCountryCode, UserSession.IpCountryCode);
            //iGame = ISoftBetIntegration.GameMgt.Get(domain, this.Model.GameID, funMode, true, this.Language, session.UserCountryCode, session.IpCountryCode);
            iGame = ISoftBetIntegration.GameManager.Get(Domain, this.Model.GameID, true, this.Language, UserSession.UserCountryCode, UserSession.IpCountryCode);
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

        StringBuilder sbUrl = new StringBuilder();
        sbUrl.AppendFormat("{0}html/{1}/{2}/{2}.html"
            , TargetServer
            , iGame.MainCategory
            , iGame.Identifier);
        sbUrl.AppendFormat("?lang={0}", HttpUtility.UrlEncode(this.Language));
        sbUrl.AppendFormat("&name={0}", HttpUtility.UrlEncode(string.Format("{0},{1}"
            , Domain.GetCfg(ISoftBet.LicenseID)
            , FunMode ? "fun" : UserSession.UserID.ToString())));
        
        string iSessionID = null;
        if (!FunMode)
        {
            string cur = string.Empty;
            if (UseGmGaming)
            {
                TokenResponse response = GetToken();

                if (response.AdditionalParameters.Exists(a => a.Name == "UserCasinoCurrency"))
                    cur = response.AdditionalParameters.First(a => a.Name == "UserCasinoCurrency").Value;

                iSessionID = response.TokenKey;
            }
            else
            {
                throw new CeException("GmGaming only valid to get token");
            }
            
            sbUrl.AppendFormat("&funmode=false&currency={0}", HttpUtility.UrlEncode(cur));
            sbUrl.AppendFormat("&password={0}", HttpUtility.UrlEncode(string.Format("{0},{1},{2},{3},real"
            , iSessionID
            , UserSession.Username
            , cur
            , UserSession.UserCountryCode)));
        }
        else
        {
            sbUrl.Append("&currency=EUR&password=fun&funmode=true");
        }

        sbUrl.AppendFormat("&lobbyUrl={0}", HttpUtility.UrlEncode(Domain.MobileLobbyUrl));
        
        this.LaunchUrl = sbUrl.ToString();
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
    <%=InjectScriptCode(ISoftBet.CELaunchInjectScriptUrl) %>
</body>
</html>