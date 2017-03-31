<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>
<%@ Import Namespace="CE.db" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GmGamingAPI" %>

<script language="C#" type="text/C#" runat="server">

    public override string GetLanguage(string lang)
    {
        //Korean,
        //Japenese,
        //Chinese,
        //Traditional Chinese,
        //English
        //Taiwanese

        SupportedLanguages = new List<string> { "en", "ja", "tr", "ch", "ko", "sp", "th" };
        return base.GetLanguage(lang);
    }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        bool showLiveLobby = Domain.GetCfg(HoGaming.ShowLiveLobby) == "true";
        string tableId = string.Empty;
        
        bool mobileDevice = CE.Utils.PlatformHandler.IsMobile;
        
        StringBuilder startUrl  = new StringBuilder(Domain.GetCfg(HoGaming.GameBaseLobbyURL));
        string sessionId = string.Empty;
        
        if (!FunMode && UserSession != null)
        {
            string userId = string.Format("{0}~{1}", UserSession.UserID, UserSession.DomainID);
            StringBuilder url = new StringBuilder(Domain.GetCfg(HoGaming.GameBaseLoginURL));

            TokenResponse tokenResponse = GetToken();
            string currency = UserSession.Currency;
            if (tokenResponse.AdditionalParameters.Exists(a => a.Name == "UserCasinoCurrency"))
            {
                currency = tokenResponse.AdditionalParameters.First(a => a.Name == "UserCasinoCurrency").Value;
            }
            
            url.AppendFormat("?uname={0}&currency={1}&country={2}&fn={3}&mode={4}&commonwallet={5}",
                userId, currency, UserSession.UserCountryCode, UserSession.Firstname, "1", "true");

            string loginResponse = HttpHelper.GetData(new Uri(url.ToString()));

            if (!string.IsNullOrWhiteSpace(loginResponse))
            {
                sessionId = GetSessionIdFromResponse(loginResponse, url.ToString());
            }
            startUrl.AppendFormat("?sessionid={0}&lang={1}", sessionId, Language);

            if (!showLiveLobby)
            {
                Dictionary<string, ceLiveCasinoTableBaseEx> tables = global::CacheManager.GetLiveCasinoTableDictionary(Domain.DomainID);
                ceLiveCasinoTableBaseEx table;
                if (!tables.TryGetValue(TableID, out table))
                    throw new CeException("Invalid table id [{0}]", TableID);

                tableId = table.LaunchParams.Split('=').Last();

                startUrl.AppendFormat("&gameType={0}&tableId={1}", Model.GameID, tableId);
            }
        }

        if (mobileDevice)
        {
            startUrl.AppendFormat("&mobile=true");
        }

        this.LaunchUrl = startUrl.ToString();
    }

    private static string GetSessionIdFromResponse(string response, string url)
    {
        if (string.IsNullOrEmpty(response))
        {
            throw new CeException("Invalid response");
        }

        var xdoc = XDocument.Parse(response);
        var sessionId = (xdoc.Descendants("attribute").Where(xml =>
        {
            var xElement = xml.Element("name");
            if (xElement != null && xElement.Value == "errorcode")
            {
                throw new ApplicationException(string.Format("User login error. Url : {0} Response : {1}", url, response));
            }
            
            return xElement != null && xElement.Value == "sessionid";
        }).Select(xml => xml.Element("value"))).FirstOrDefault();
        
        if (sessionId == null)
        {
            throw new CeException("Parameter sessionId is empty");
        }

        return sessionId.Value;
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
        html, body {
            width: 100%;
            height: 100%;
            padding: 0px;
            margin: 0px;
            background: #E9E9E9;
            overflow: hidden;
        }

        #ifmGame {
            width: 100%;
            height: 100%;
            border: 0px;
        }
    </style>
</head>
<body>
    
    <iframe id="ifmGame" allowtransparency="true" frameborder="0" scrolling="no" src="<%= this.LaunchUrl %>"></iframe>
    <% Html.RenderPartial("GoogleAnalytics", this.Domain, new ViewDataDictionary()
           {
               { "Language", this.Language},
               { "IsLoggedIn", this.ViewData["UserSession"] != null },
           }
           ); %>
    <%=InjectScriptCode(HoGaming.CELaunchInjectScriptUrl) %>

</body>
</html>
