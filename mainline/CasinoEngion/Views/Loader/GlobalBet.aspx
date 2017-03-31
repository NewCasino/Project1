<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>

<%@ Import Namespace="System.Dynamic" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Net" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GmGamingAPI" %>
<%@ Import Namespace="Newtonsoft.Json" %>
<%@ Import Namespace="Newtonsoft.Json.Linq" %>

<script language="C#" type="text/C#" runat="server">
    private bool isMobile = false;
    
    public override string GetLanguage(string lang)
    {
        //English - en_US
        //Spanish - es_ES
        //Italian - it_IT
        //French - fr_FR
        //Flamish - nl_BE
        //Romanian - ro_RO
        //Russian - ru_RU
        //Slovakian - sk_SK
        //Turkish - tr_TR
        //Chinese Simplified - zh_CN
        //Chinese Traditional - zh_HK
        //Tagalog - tl_PH 	tl
        //Thai - th_TH
        
        var dic = new Dictionary<string, string>();
        dic.Add("en", "en-US");
        dic.Add("es", "es-ES");
        dic.Add("it", "it-IT");
        dic.Add("fr", "fr-FR");
        dic.Add("nl", "nl_BE");
        dic.Add("ro", "ro_RO");
        dic.Add("ru", "ru_RU");
        dic.Add("sk", "sk_SK");
        dic.Add("tr", "tr_TR");
        dic.Add("zh-cn", "zh_CN");
        dic.Add("zh-tw", "zh_HK");
        dic.Add("tl", "tl_PH");
        dic.Add("th", "th_TH");
        if (string.IsNullOrWhiteSpace(lang))
            lang = "en";
        else
            lang = lang.Truncate(2).ToLowerInvariant();

        if (dic.Keys.Contains(lang))
            return dic[lang];

        return "en-US";
    }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        bool isLobby = Model.GameName.ToLower().Contains("lobby");
        
        isMobile = PlatformHandler.IsMobile;

        if (UserSession == null || FunMode)
            throw new CeException("GlobalBet game is only available in real money mode.");

        TokenResponse response = GetToken();

        StringBuilder url = new StringBuilder();
        url.AppendFormat(Domain.GetCfg(Globalbet.GameBaseURL), response.TokenKey);
        url.AppendFormat("locale={0}", Language);
        
        if (!isLobby)
        {
            url.AppendFormat("#odds:{0}", Model.GameID);
        }

        LaunchUrl = url.ToString();
        if (isMobile)
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
    <meta http-equiv="X-UA-Compatible" content="requiresActiveX=true" />
    <style type="text/css">
        html, body {
            width: 100%;
            height: 100%;
            padding: 0px;
            margin: 0px;
            background: #E9E9E9;
        }

        #ifmGame {
            width: 100%;
            height: 100%;
            border: 0px;
        }
    </style>
    <script language="javascript" type="text/javascript" src="/js/jquery-1.7.2.min.js"></script>
    <%=InjectScriptCode(Globalbet.EasyXDMScriptUrl) %>
    <%=InjectScriptCode(Globalbet.WidgetIntegrationScriptUrl) %>
</head>
<body>
    <div id="globalbet"/>
    
    <script>
        $(document).ready(function(){
        var container = document.getElementById("globalbet");
        widgetAdapter.registerVirtualSports(container, "<%=LaunchUrl%>");
        });
    </script>
        
    <script type="text/javascript">
        var prevBodyHeight = document.body.offsetHeight;

        function sendBodyHeight() {

            var bodyHeight = document.body.offsetHeight;

            if (prevBodyHeight != bodyHeight) {
                console.log("Height changed: prev = " + prevBodyHeight + ", before = " + bodyHeight);
                prevBodyHeight = bodyHeight;

                window.parent.postMessage({
                    "bodyHeight": bodyHeight,
                    "source": "casinoIframe"
                }
                , "*");
            }
        }

        setInterval(sendBodyHeight, 500);
    </script>

    <% Html.RenderPartial("GoogleAnalytics", this.Domain, new ViewDataDictionary()
           {
               { "Language", this.Language},
               { "IsLoggedIn", this.ViewData["UserSession"] != null },
           }
           ); %>
    <%=InjectScriptCode(Globalbet.CELaunchInjectScriptUrl) %>
</body>
</html>
