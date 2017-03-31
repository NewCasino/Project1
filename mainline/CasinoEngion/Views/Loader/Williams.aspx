<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script language="C#" type="text/C#" runat="server">
    private bool IsMobile { get; set; }

    public override string GetLanguage(string lang)
    {
        var dic = new Dictionary<string, string>();
        dic.Add("en", "en_GB");
        dic.Add("sv", "sv_SE");
        dic.Add("ca", "ca_ES"); //Catalan
        dic.Add("cs", "cs_CZ");
        dic.Add("da", "da_DK");
        dic.Add("de", "de_DE");
        dic.Add("el", "el_GR");
        dic.Add("es", "es_ES");
        dic.Add("et", "et_EE"); //Estonia
        dic.Add("fi", "fi_FI");
        dic.Add("fr", "fr_FR");
        dic.Add("hr", "hr_HR"); // Croatia
        dic.Add("hu", "hu_HU"); // Hungary
        dic.Add("it", "it_IT");
        dic.Add("lt", "lt_LT"); // Lithuania
        dic.Add("lv", "lv_LV");
        dic.Add("no", "no_NO");
        dic.Add("nl", "nl_NL");
        dic.Add("pl", "pl_PL");
        dic.Add("pt", "pt_PT");
        dic.Add("ro", "ro_RO");
        dic.Add("ru", "ru_RU");
        dic.Add("sk", "sk_SK");
        dic.Add("sl", "sl_SI"); // Sierra Leone
        dic.Add("tr", "tr_TR");
        
        
        if (string.IsNullOrWhiteSpace(lang))
            lang = "en";
        else
            lang = lang.Truncate(2).ToLowerInvariant();

        if (dic.Keys.Contains(lang))
            return dic[lang];
        
        return "en_GB";
    }

    private string GetTicket(ref string accountId, ref int realityCheck)
    {
        if (UseGmGaming)
        {
            GmGamingAPI.TokenResponse response = GetToken();

            if (response.AdditionalParameters.Exists(a => a.Name == "AccountId"))
            {
                accountId = response.AdditionalParameters.First(a => a.Name == "AccountId").Value;
            }

            if (response.AdditionalParameters.Exists(a => a.Name == "RealityCheckSec"))
            {
                realityCheck = int.Parse(response.AdditionalParameters.First(a => a.Name == "RealityCheckSec").Value)/60;
            }

            return response.TokenKey;
        }
        else
        {
            throw new CeException("GmGaming only valid to get token");
        }
    }

    private void AddRealityCheckParameters(int realityCheck, StringBuilder url, string historyLink)
    {
        if (realityCheck > 0)
        {
            // link to send player to game history page
            string realityLink = HttpUtility.UrlEncode(historyLink);
            int realitySessionTime = 0;
            url.AppendFormat("&realityCheck={0}", realityCheck);
            url.AppendFormat("&realityButtons={0}", "QUITCONT");

            url.AppendFormat("&realityLink={0}", realityLink);
            url.AppendFormat("&realitySessionTime={0}", realitySessionTime);
        }
    }

    private string GetDesktopLaunchUrl()
    {
        // When games will be launched in html5 mode only one link will be used for mobile and desktop version
        string launchUrlTemplate = !string.IsNullOrEmpty(this.Model.MobileGameLaunchUrl) ?
            this.Model.MobileGameLaunchUrl : Domain.GetCfg(Williams.GameBaseURL);

        StringBuilder url = new StringBuilder(launchUrlTemplate);
        url.AppendFormat("?partnerCode={0}", HttpUtility.UrlEncode(Domain.GetCfg(Williams.PartnerCode)));
        url.AppendFormat("&portal1_preload={0}", HttpUtility.UrlEncode(this.Model.GameID));
        url.AppendFormat("&languageCode={0}", HttpUtility.UrlEncode(this.Language));
        url.AppendFormat("&realMoney={0}", (!FunMode).ToString().ToLowerInvariant());
        url.AppendFormat("&context={0}", "default");

        if (!FunMode && UserSession != null)
        {
            string accountId = UserSession.UserID.ToString();
            int realityCheck = 0;
            string token = GetTicket(ref accountId, ref realityCheck);
            url.AppendFormat("&accountId={0}", accountId);
            url.AppendFormat("&ticket={0}", HttpUtility.UrlEncode(token));
            AddRealityCheckParameters(realityCheck, url, Domain.AccountHistoryUrl);
        }

        return url.ToString();
    }

    private string GetMobileLaunchUrl()
    {
        string launchUrlTemplate = !string.IsNullOrEmpty(this.Model.MobileGameLaunchUrl) ?
            this.Model.MobileGameLaunchUrl : Domain.GetCfg(Williams.MobileGameBaseURL);

        StringBuilder url = new StringBuilder(launchUrlTemplate);
        url.AppendFormat("?partnercode={0}", HttpUtility.UrlEncode(Domain.GetCfg(Williams.PartnerCode)));
        url.AppendFormat("&game={0}", HttpUtility.UrlEncode(this.Model.GameID));
        url.AppendFormat("&locale={0}", HttpUtility.UrlEncode(this.Language));
        url.AppendFormat("&realmoney={0}", (!FunMode).ToString().ToLowerInvariant());
        
        if (!FunMode && UserSession != null)
        {
            string accountId = UserSession.UserID.ToString();
            int realityCheck = 0;
            string token = GetTicket(ref accountId, ref realityCheck);
            
            url.AppendFormat("&partneraccountid={0}", accountId);
            url.AppendFormat("&partnerticket={0}", HttpUtility.UrlEncode(token));
            AddRealityCheckParameters(realityCheck, url, Domain.MobileAccountHistoryUrl);
        }
        if (!string.IsNullOrWhiteSpace(Domain.MobileLobbyUrl))
            url.AppendFormat("&lobbyurl={0}", HttpUtility.UrlEncode(Domain.MobileLobbyUrl));
        
        if (!string.IsNullOrWhiteSpace(Domain.MobileCashierUrl))
            url.AppendFormat("&depositurl={0}", HttpUtility.UrlEncode(Domain.MobileCashierUrl));

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
    <%=InjectScriptCode(Williams.CELaunchInjectScriptUrl) %>
</body>
</html>