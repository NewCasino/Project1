<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="CE.db" %>
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
            case "en":
            case "es":
            case "ru":
            case "tr":
            case "kr":
            case "ko":
            case "th":
            case "vi":
                return lang;
            case "zh":
                return "zh";
            default:
                return "en";
        }
    }
    
    //VendorID = 132
    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        bool mobileDevice = CE.Utils.PlatformHandler.IsMobile;
        string showLiveLobby = Domain.GetCfg(Ezugi.ShowLiveLobby);
            
        Dictionary<string, ceLiveCasinoTableBaseEx> tables = global::CacheManager.GetLiveCasinoTableDictionary(Domain.DomainID);
        ceLiveCasinoTableBaseEx table;
        if (!tables.TryGetValue(TableID, out table))
            throw new CeException("Invalid table id [{0}]", TableID);

        if (UserSession == null || FunMode)
            throw new CeException("Ezugi Live Casino is only available in real money mode!");
        
        string tableUrl;
        // When games will be launched in html5 mode only one link will be used for mobile and desktop version
        if (!string.IsNullOrEmpty(this.Model.MobileGameLaunchUrl))
        {
            tableUrl = this.Model.MobileGameLaunchUrl;
        }
        else
        {            
            tableUrl = String.IsNullOrEmpty(table.TableStudioUrl) ? Domain.GetCfg(Ezugi.LiveCasinoBaseUrl) : table.TableStudioUrl;
        }
        
        StringBuilder url = new StringBuilder();
        url.Append(tableUrl);
        url.AppendFormat("?clientType={0}", "html5");

        string operatorID = string.Empty;
        string token = string.Empty;

        if (UseGmGaming)
        {
            List<NameValue> addParams = new List<NameValue>()
            {
                new NameValue { Name = "UserLanguage", Value = this.Language }
            };

            TokenResponse response = GetToken(addParams);

            if (response.AdditionalParameters.Exists(a => a.Name == "OperatorID"))
                operatorID = response.AdditionalParameters.First(a => a.Name == "OperatorID").Value;

            if (response.AdditionalParameters.Exists(a => a.Name == "UserLanguage"))
                this.Language = response.AdditionalParameters.First(a => a.Name == "UserLanguage").Value;

            token = response.TokenKey;
        }
        else
        {
            throw new CeException("GmGaming only valid to get token");            
        }

        if (showLiveLobby != "true")
        {
            url.AppendFormat("&operatorId={0}&language={1}&token={2}&openGame={3}&openTable={4}"
                , operatorID
                , HttpUtility.UrlEncode(this.Language)
                , HttpUtility.UrlEncode(token)
                , HttpUtility.UrlEncode(this.Model.GameID)
                , HttpUtility.UrlEncode(table.ExtraParameter1)
                );
        }
        else
        {
            url.AppendFormat("&operatorId={0}&language={1}&token={2}"
                , operatorID
                , HttpUtility.UrlEncode(this.Language)
                , HttpUtility.UrlEncode(token)
                );
        }
        
        this.LaunchUrl = url.ToString();

        if (mobileDevice)
        {
            Response.Redirect(LaunchUrl);
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
<% if (UseGmGaming){ %>
<body class="Rest">
<% } else{ %>
<body>
<% } %>
    <iframe id="ifmGame" allowTransparency="true" frameborder="0" scrolling="no" src="<%= this.LaunchUrl.SafeHtmlEncode() %>"></iframe>
    <% Html.RenderPartial("GoogleAnalytics", this.Domain, new ViewDataDictionary()
           {
               { "Language", this.Language},
               { "IsLoggedIn", this.ViewData["UserSession"] != null },
           }
           ); %>
    <%=InjectScriptCode(Ezugi.CELaunchInjectScriptUrl) %>
</body>
</html>