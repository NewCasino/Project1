<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="GmGamingAPI" %>

<script language="C#" type="text/C#" runat="server">

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        int realityCheck = 0;
        
        bool mobileDevice = CE.Utils.PlatformHandler.IsMobile;              
        string lobbyUrl = mobileDevice ? HttpUtility.UrlEncode(Domain.MobileLobbyUrl) : HttpUtility.UrlEncode(Domain.LobbyUrl);           

        StringBuilder url = new StringBuilder();      

        if (!FunMode)
        {
            string countrySpecificBaseUrl = mobileDevice ?
                Domain.GetCountrySpecificCfg(Genii.MobileGameBaseURL, UserSession.UserCountryCode, UserSession.IpCountryCode) :
                Domain.GetCountrySpecificCfg(Genii.GameBaseURL, UserSession.UserCountryCode, UserSession.IpCountryCode);
            
            url.Append(countrySpecificBaseUrl);
            
            TokenResponse responseToken = GetToken();
            if (responseToken.AdditionalParameters.Exists(a => a.Name == "RealityCheckSec"))
                realityCheck = int.Parse(responseToken.AdditionalParameters.First(a => a.Name == "RealityCheckSec").Value);
            url.AppendFormat("?GameId={0}&ReturnUrl={1}&SessionId={2}&Locale={3}",
                this.Model.GameID, lobbyUrl, responseToken.TokenKey, this.Language);

            if (responseToken.AdditionalParameters != null && responseToken.AdditionalParameters.Exists(a => a.Name == "RealityCheckSec"))
            {
                int realityCheckTimeoutMin = int.Parse(responseToken.AdditionalParameters.First(a => a.Name == "RealityCheckSec").Value) / 60;
                url.AppendFormat("&RealityCheckPeriodMinutes={0}", realityCheckTimeoutMin);
            }            
        }
        else
        {
            string funModeUrl = mobileDevice ? Domain.GetCfg(Genii.MobileGameBaseURL) : Domain.GetCfg(Genii.GameBaseURL);
            url.Append(funModeUrl);
            url.AppendFormat("/Demo?GameId={0}&ReturnUrl={1}&Locale={2}",
                this.Model.GameID, lobbyUrl, this.Language);
        }       
        
        this.LaunchUrl = url.ToString();
        if (mobileDevice)
        {
            Response.Redirect(url.ToString());
        }       
    }

    public override string GetLanguage(string lang)
    {
        var dic = new Dictionary<string, string>();
        dic.Add("en", "en-US");
        dic.Add("da", "da-DK");        
        dic.Add("de", "de-DE");        
        dic.Add("el", "el-GR");        
        dic.Add("es", "es-ES");           
        dic.Add("fr", "fr-FR");        
        dic.Add("it", "it-IT");        
        dic.Add("sv", "sv-SE");       
        dic.Add("nb", "nb-NO");                  
        if (string.IsNullOrWhiteSpace(lang))
            lang = "en";
        else
            lang = lang.Truncate(2).ToLowerInvariant();

        if (dic.Keys.Contains(lang))
            return dic[lang];

        return "en-US";
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
           {"Language", this.Language},
           {"IsLoggedIn", this.ViewData["UserSession"] != null},
       }
           ); %>
    <%=InjectScriptCode(Genii.CELaunchInjectScriptUrl) %>
</body>
</html>
