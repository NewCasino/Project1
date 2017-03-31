<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Integration.VendorApi" %>
<%@ Import Namespace="CE.Integration.VendorApi.Models" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GmGamingAPI" %>

<script language="C#" type="text/C#" runat="server">

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        bool mobileDevice = PlatformHandler.IsMobile;        
        
        string baseGameUrl = mobileDevice ? Domain.GetCfg(Oriental.MobileGameURL) : Domain.GetCfg(Oriental.CasinoGameURL);  
        string agent = Domain.GetCfg(Oriental.Agent);        
        string agentKey = Domain.GetCfg(Oriental.AgentKey);         
        string password = GetPassword();
        string gametype = mobileDevice ? "21" : "1";
        string iFrame = mobileDevice ? "0" : "1";

        string queryString = string.Format("agent={0}$username={1}$password={2}$domain={3}$gametype={4}$gamekind=0$iframe={5}$platformname=Oriental$lang={6}$method=tg",
            agent, UserSession.Username, password, Domain.Name, gametype, iFrame, Language); 
        
        string encodedQueryStringWithoutSecretKey = EncodeBase64OrientalStyle(queryString);
        string encodedQueryStringWithSecretKey = string.Format("{0}{1}", encodedQueryStringWithoutSecretKey, agentKey);
        string md5EncodedRequestPatameters = encodedQueryStringWithSecretKey.MD5Hash();
                

        string launchUrl = string.Format("{0}?params={1}&key={2}", baseGameUrl, encodedQueryStringWithoutSecretKey, md5EncodedRequestPatameters);
        this.LaunchUrl = launchUrl;
        
        if (mobileDevice)
        {
            Response.Redirect(launchUrl);
        }
    }   

    public override string GetLanguage(string lang)
    {
        if (string.IsNullOrEmpty(lang))
            return "en";
        string lowerLang = lang.ToLowerInvariant();

        if (SupportedLanguages.Contains(lowerLang))
        {
            return lowerLang;
        }

        return "en";
    }

    private static readonly HashSet<string> SupportedLanguages = new HashSet<string>()
    {
        "zh",
        "jp",
        "kr"
    };

    private string EncodeBase64OrientalStyle(string code)
    {
        string encode = "";
        byte[] bytes = Encoding.GetEncoding("utf-8").GetBytes(code); 
        try
        {
            encode = Convert.ToBase64String(bytes);
        }
        catch
        {
            encode = code;
        }
        
        return encode;
    }

    private string GetPassword()
    {
        string password = string.Format("{0}~{1}", UserSession.DomainID, UserSession.UserID);
        return password.ToBase36String();
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
    <%=InjectScriptCode(Oriental.CELaunchInjectScriptUrl) %>
</body>
</html>
