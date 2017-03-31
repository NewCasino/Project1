<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>

<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="GmGamingAPI" %>
<%@ Import Namespace="Newtonsoft.Json.Linq" %>

<script language="C#" type="text/C#" runat="server">

    private string GetGameHostName(bool isMobile)
    {
        string gameHost = string.Format(Domain.GetCfg(CandleBets.GameBaseURL), CandleBets.GameBaseURL);

        // For candlebets, each game has it's unique base url, 
        // (also, they are different for mobile and desktop version of the game)
        // Base url are saved in Description field in format: 
        //  {
        //     "DesktopLaunchUrl": "http://desktop.com", 
        //     "DesktopMobileLaunchUrlLaunchUrl": "http://mobile.com"
        //  }
        JObject jObj = JObject.Parse(this.Model.Description);
        if (isMobile)
        {
            JToken mobileItem;
            if (jObj.TryGetValue("MobileLaunchUrl", out mobileItem))
            {
                gameHost = string.Format(Domain.GetCfg(CandleBets.GameBaseURL), mobileItem.Value<string>());
            }
        }
        else
        {
            JToken desktopItem;
            if (jObj.TryGetValue("DesktopLaunchUrl", out desktopItem))
            {
                gameHost = string.Format(Domain.GetCfg(CandleBets.GameBaseURL), desktopItem.Value<string>());
            }
        }

        return gameHost;
    }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        bool mobileDevice = CE.Utils.PlatformHandler.IsMobile;
        bool funMode = FunMode;

        string gameHost = GetGameHostName(mobileDevice);
        
        StringBuilder url = new StringBuilder();
        url.Append(gameHost);
        url.AppendFormat("?gameCode={0}&language={1}&mobile={2}&freePlay={3}",
            this.Model.GameID,
            this.Language,
            mobileDevice ? "true" : "false",
            funMode
            );

        if (!FunMode)
        {
            TokenResponse response = GetToken();
            string currency = UserSession.Currency;
            if (response.AdditionalParameters.Exists(a => a.Name == "UserCasinoCurrency"))
            {
                currency = response.AdditionalParameters.First(a => a.Name == "UserCasinoCurrency").Value;
            }
            url.AppendFormat("&token={0}&currencyCode={1}", response.TokenKey, currency);
        }
        string startUrl = url.ToString();

        this.LaunchUrl = startUrl;

        if (mobileDevice)
        {
            Response.Redirect(startUrl);
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
</head>
<body>
    
    <iframe id="ifmGame" style="overflow-y:scroll;" allowtransparency="true" frameborder="0" scrolling="yes" src="<%= this.LaunchUrl %>"></iframe>
    <% Html.RenderPartial("GoogleAnalytics", this.Domain, new ViewDataDictionary()
           {
               { "Language", this.Language},
               { "IsLoggedIn", this.ViewData["UserSession"] != null },
           }
           ); %>
    <%=InjectScriptCode(CandleBets.CELaunchInjectScriptUrl) %>

</body>
</html>
