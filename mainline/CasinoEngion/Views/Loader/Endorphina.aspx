<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>

<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.Net" %>
<%@ Import Namespace="System.Net.Cache" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmGamingAPI" %>


<script language="C#" type="text/C#" runat="server">
    private bool isMobile = false;

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        isMobile = PlatformHandler.IsMobile;
        string startUrl = string.Empty;
        var exitUrl = isMobile ? Domain.MobileLobbyUrl : Domain.LobbyUrl;
        if (UserSession == null || FunMode)
        {
            startUrl = Domain.GetCfg(Endorphina.FunModeGameBaseURL);
            string accountId = Domain.GetCfg(Endorphina.AccountIdFromVendor);
            string gameId = StringExtension.MD5Hash(Model.GameID);
            string returnUrl = HttpUtility.UrlEncode(HttpUtility.UrlEncode(exitUrl));
            startUrl = string.Format(startUrl, accountId, gameId, returnUrl);
            if (!string.IsNullOrEmpty(startUrl))
            {
                string funModeUrl = HttpHelper.GetData(new Uri(startUrl));
                GmLogger.Instance.Trace("Endorphina - funModeData: " + funModeUrl);
                this.LaunchUrl = funModeUrl;
            }
            else
            {
                GmLogger.Instance.Error("Endorphina - exitUrl: " + exitUrl);
                this.LaunchUrl = exitUrl;
            }
        }
        else
        {
            string sign = string.Empty, nodeId = string.Empty;
            TokenResponse response;
            startUrl = Domain.GetCfg(Endorphina.GameBaseURL);
            startUrl = string.Format(CultureInfo.InvariantCulture, "{0}exit={1}&", startUrl, HttpUtility.UrlEncode(exitUrl));
            List<NameValue> addParams = new List<NameValue>
            {
                new NameValue
                {
                    Name = "exit",
                    Value = exitUrl
                }
            };
            response = GetToken(addParams);

            if (response.AdditionalParameters.Exists(a => a.Name == "NodeId"))
                nodeId = response.AdditionalParameters.First(a => a.Name == "NodeId").Value;

            if (response.AdditionalParameters.Exists(a => a.Name == "Salt"))
                sign = response.AdditionalParameters.First(a => a.Name == "Salt").Value;

            //if (response.AdditionalParameters.Exists(a => a.Name == "RealityCheckSec"))
            //    realityCheck = int.Parse(response.AdditionalParameters.First(a => a.Name == "RealityCheckSec").Value);

            startUrl += String.Format("nodeId={0}&token={1}&sign={2}", nodeId, response.TokenKey, sign);
            this.LaunchUrl = startUrl;
        }

        if (isMobile)
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
    <meta http-equiv="X-UA-Compatible" content="requiresActiveX=true" />
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
    <iframe id="ifmGame" allowtransparency="true" frameborder="0" scrolling="no" src="<%= this.LaunchUrl.SafeHtmlEncode() %>"></iframe>

    <% Html.RenderPartial("GoogleAnalytics", this.Domain, new ViewDataDictionary()
           {
               { "Language", this.Language},
               { "IsLoggedIn", this.ViewData["UserSession"] != null },
           }
           ); %>
    <%=InjectScriptCode(Endorphina.CELaunchInjectScriptUrl) %>
</body>
</html>
