<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script language="C#" type="text/C#" runat="server">
    private bool IsMobile { get; set; }

    public override string GetLanguage(string lang)
    {
        if (string.IsNullOrWhiteSpace(lang))
            return "en";

        switch (lang.Truncate(2).ToLowerInvariant())
        {
            case "cs": lang = "cz"; break;
            case "sv": lang = "se"; break;
            case "zh": lang = "zh"; break;
            case "en": lang = "en"; break;
        }

        return lang.ToLowerInvariant();
    }

    protected string GetDesktopLaunchUrl()
    {
        //http://89.151.126.7/f1x2gamesEM/loadGame.jsp?lang={0}&token=aaaaaabbbbbbbbbbbb&gameID=1001&siteId=1&playmode=fun
        StringBuilder url = new StringBuilder(Domain.GetCfg(OneXTwoGaming.CasinoGameBaseURL));
        url.AppendFormat("?lang={0}", this.Language);
        url.AppendFormat("&gameID={0}", HttpUtility.UrlEncode(this.Model.GameID));
        url.AppendFormat("&siteId={0}", Domain.DomainID);
        url.AppendFormat("&playmode={0}", FunMode ? "fun": "real");

        if (!FunMode)
        {
            string token;
            if (UseGmGaming)
            {
                token = GetToken().TokenKey;
            }
            else
            {
                throw new CeException("GmGaming only valid to get token");
            }

            url.AppendFormat("&token={0}", HttpUtility.UrlEncode(token));
        }

        return url.ToString();
    }

    protected string GetMobileLaunchUrl()
    {
        //http://89.151.126.7/f1x2gamesEM/loadMobileGame.jsp?lang={0}&token=aaaaaabbbbbbbbbbbb&gameID=1001&siteId=1&playmode=fun&lobbyurl=
        StringBuilder url = new StringBuilder(Domain.GetCfg(OneXTwoGaming.MobileCasinoGameBaseURL));
        url.AppendFormat("?lang={0}", this.Language);
        url.AppendFormat("&gameID={0}", HttpUtility.UrlEncode(this.Model.GameID));
        url.AppendFormat("&siteId={0}", Domain.DomainID);
        url.AppendFormat("&site={0}", Domain.DomainID);
        url.AppendFormat("&playmode={0}", FunMode ? "fun": "real");
        if (!string.IsNullOrWhiteSpace(Domain.MobileLobbyUrl))
            url.AppendFormat("&lobbyurl={0}", HttpUtility.UrlEncode(Domain.MobileLobbyUrl));

        if (!FunMode)
        {
            string token;
            if (UseGmGaming)
            {
                token = GetToken().TokenKey;
            }
            else
            {
                throw new CeException("GmGaming only valid to get token");
            }

            url.AppendFormat("&token={0}", HttpUtility.UrlEncode(token));
            url.AppendFormat("&acc_id={0}", HttpUtility.UrlEncode(token));
        }

        return url.ToString();
    }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        IsMobile = CE.Utils.PlatformHandler.IsMobile;

        if (IsMobile)
        {
            this.LaunchUrl = GetMobileLaunchUrl();
        }
        else
        {
            this.LaunchUrl = GetDesktopLaunchUrl();
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
    <%if (!IsMobile) { %>
    <iframe id="ifmGame" allowTransparency="true" frameborder="0" scrolling="no" src="<%= this.LaunchUrl.SafeHtmlEncode() %>"></iframe>
    <%} else {%>
    <script type="text/javascript">
        function __redirect() {
            try {
                self.location.replace('<%= this.LaunchUrl.SafeJavascriptStringEncode() %>');
            }
            catch (e) {
                self.location = '<%= this.LaunchUrl.SafeJavascriptStringEncode() %>';
            }
        }
        setTimeout(3000, __redirect());
    </script>
    <%}%>
    <% Html.RenderPartial("GoogleAnalytics", this.Domain, new ViewDataDictionary()
           {
               { "Language", this.Language},
               { "IsLoggedIn", this.ViewData["UserSession"] != null },
           }
           ); %>
    <%=InjectScriptCode(OneXTwoGaming.CELaunchInjectScriptUrl) %>
</body>
</html>