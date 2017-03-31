<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmGamingAPI" %>

<script language="C#" type="text/C#" runat="server">
    public override string GetLanguage(string lang)
    {
        if (string.IsNullOrWhiteSpace(lang))
            return "en";
        
        switch (lang.Truncate(2).ToLowerInvariant())
        {
            case "zh":
                lang = "zh";
                break;
        }

        return lang.ToLowerInvariant();
    }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        bool isMobileGame = CE.Utils.PlatformHandler.IsMobile;
        //if(session==null)
        //    throw new CeException("Please log in first before you can play EGT game.");
        StringBuilder url = new StringBuilder();
        
        if (FunMode)
        {
            if(isMobileGame)
                url.Append(Domain.GetCfg(EGT.FunModeMobileGameBaseURL));
            else    
                url.Append(Domain.GetCfg(EGT.FunModeGameBaseURL));
        }
        else
        {
            url.Append(Domain.GetCfg(EGT.GameBaseURL));
        }
        
        url.AppendFormat("?language={0}", this.Language.ToLowerInvariant());
        if (!FunMode)
        {
            url.AppendFormat("&gameId={0}", HttpUtility.UrlEncode(this.Model.GameID));
            url.AppendFormat("&country={0}", UserSession.UserCountryCode.ToLowerInvariant());
            url.AppendFormat("&screenName={0}", HttpUtility.UrlEncode(UserSession.Username));

            string token;
            string portalCode = string.Empty;
            string playerId = string.Empty;
            if (UseGmGaming)
            {
                TokenResponse response = GetToken();

                if (response.AdditionalParameters.Exists(a => a.Name == "PortalCode"))
                    portalCode = response.AdditionalParameters.First(a => a.Name == "PortalCode").Value;

                if (response.AdditionalParameters.Exists(a => a.Name == "PlayerId"))
                    playerId = response.AdditionalParameters.First(a => a.Name == "PlayerId").Value;

                token = response.TokenKey;
            }
            else
            {
                throw new CeException("GmGaming only valid to get token");
            }

            url.AppendFormat("&defenceCode={0}", HttpUtility.UrlEncode(token));
            url.AppendFormat("&portalCode={0}", HttpUtility.UrlEncode(portalCode));
            url.AppendFormat("&playerId={0}", HttpUtility.UrlEncode(playerId));
        }
        else
        {
            if (isMobileGame)
                url.AppendFormat("&gameId={0}", HttpUtility.UrlEncode(this.Model.GameID));
            else
                url.AppendFormat("&g={0}", HttpUtility.UrlEncode(this.Model.GameID));
            
            url.AppendFormat("&screenName={0}", HttpUtility.UrlEncode( UserSession == null ? "Fun Mode" : UserSession.Username));            
        }

        if (isMobileGame)
        {
            url.Append("&client=mobile");
            url.AppendFormat("&closeurl={0}", HttpUtility.UrlEncode(Domain.MobileLobbyUrl));
            Response.Redirect(url.ToString());
        }
        
        this.LaunchUrl = url.ToString();
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

    <script type="text/javascript">
        
        function onExitGamePlatformEGT() {
            try {
                top.location.replace('<%= this.Domain.LobbyUrl.SafeJavascriptStringEncode() %>');
            }
            catch (e) {
                top.location = '<%= this.Domain.LobbyUrl.SafeJavascriptStringEncode() %>';
            }
        }

        function receiveMessage(event) {
            if (event.data && event.data.command == 'com.egt-bg.exit')
                onExitGamePlatformEGT();
        }
        window.addEventListener("message", receiveMessage, false);
    </script>

    <% Html.RenderPartial("GoogleAnalytics", this.Domain, new ViewDataDictionary()
           {
               { "Language", this.Language},
               { "IsLoggedIn", this.ViewData["UserSession"] != null },
           }
           ); %>
    <%=InjectScriptCode(Vivo.CELaunchInjectScriptUrl) %>
</body>
</html>
