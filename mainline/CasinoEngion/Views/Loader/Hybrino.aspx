<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>

<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="GmGamingAPI" %>

<script language="C#" type="text/C#" runat="server">

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        bool mobileDevice = CE.Utils.PlatformHandler.IsMobile;
        
        string startUrl;

        StringBuilder url = new StringBuilder();
        url.Append(Domain.GetCfg(Hybrino.GameBaseURL));
        url.AppendFormat("?gameCode={0}&language={1}&operatorId={2}&freePlay={3}&mobile={4}&clientId={5}&mode={6}",
            this.Model.GameID,
            this.Language,
            Domain.GetCfg(Hybrino.PartnerID),
            FunMode ? "true" : "false",
            mobileDevice ? "true" : "false",
            Domain.GetCfg(Hybrino.ClientID),
            Domain.GetCfg(Hybrino.Mode)
            );
        startUrl = url.ToString();

        if (!FunMode)
        {
            TokenResponse response = GetToken();
            string currency = UserSession.Currency;
            if (response.AdditionalParameters.Exists(a => a.Name == "UserCasinoCurrency"))
            {
                currency = response.AdditionalParameters.First(a => a.Name == "UserCasinoCurrency").Value;
            }
            startUrl += String.Format("&launchToken={0}&currencyCode={1}", response.TokenKey, currency);
        }
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
    <%=InjectScriptCode(Hybrino.CELaunchInjectScriptUrl) %>

</body>
</html>
