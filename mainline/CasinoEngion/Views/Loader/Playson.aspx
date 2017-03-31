<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>

<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="GmGamingAPI" %>

<script language="C#" type="text/C#" runat="server">

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        bool mobileDevice = CE.Utils.PlatformHandler.IsMobile;
        string lobbyUrl = mobileDevice ? HttpUtility.UrlEncode(Domain.MobileLobbyUrl) : HttpUtility.UrlEncode(Domain.LobbyUrl);
        string historyUrl = mobileDevice ? HttpUtility.UrlEncode(Domain.MobileAccountHistoryUrl) : HttpUtility.UrlEncode(Domain.AccountHistoryUrl);
        string baseGameUrl = mobileDevice ? Domain.GetCfg(Playson.MobileGameBaseURL) : Domain.GetCfg(Playson.GameBaseURL);

        StringBuilder url = new StringBuilder(baseGameUrl);
        
        url.AppendFormat("?gameName={0}&lang={1}", Model.GameID, Language);

        bool isRealityCheck = false;
        if (!FunMode)
        {
            TokenResponse responseToken = GetToken();

            url.AppendFormat("&partner={0}", Domain.GetCountrySpecificCfg(Playson.Partner, UserSession.UserCountryCode, UserSession.IpCountryCode));    
            string currency = UserSession.Currency;
            if (responseToken.AdditionalParameters.Exists(a => a.Name == "UserCasinoCurrency"))
            {
                currency = responseToken.AdditionalParameters.First(a => a.Name == "UserCasinoCurrency").Value;
            }
            url.AppendFormat("&key={0}&currency={1}", responseToken.TokenKey, currency);

            isRealityCheck = responseToken.AdditionalParameters != null
                && responseToken.AdditionalParameters.Exists(a => a.Name == "RealityCheckSec");

            if (isRealityCheck)
            {
                int realityCheckTimeoutMin = int.Parse(responseToken.AdditionalParameters.First(a => a.Name == "RealityCheckSec").Value) / 60;
                url.AppendFormat("&rci={0}&historyURL={1}&rcExitURL={2}", realityCheckTimeoutMin, historyUrl, lobbyUrl);
            }
        }
        else
        {
            url.AppendFormat("&partner={0}", Domain.GetCfg(Playson.Partner)); 
        }
        //https://cdn.ps-gamespace.com/gm/index.html?&gameName=bumper_crop&key=TEST5000&partner=everymatrix-preprod

        if (mobileDevice)
        {
            url.AppendFormat("&cashier_url={0}", HttpUtility.UrlEncode(Domain.MobileCashierUrl));
            if (!isRealityCheck)
            {
                url.AppendFormat("&exit_url={0}", lobbyUrl);
            }
        }

        var startUrl = url.ToString();
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
    <%=InjectScriptCode(Playson.CELaunchInjectScriptUrl) %>

</body>
</html>
