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
    private string lobbyUrl;

    public override string GetLanguage(string lang)
    {
        if (string.IsNullOrEmpty(lang))
            return "en";

        switch (lang.ToLowerInvariant())
        {
            case "bg":
            case "nl":
            case "en":
            case "et":
            case "fi":
            case "fr":
            case "de":
            case "hu":
            case "it":
            case "no":
            case "pl":
            case "pt":
            case "ro":
            case "es":
            case "sv":
            case "pt-BR":
                lang = lang.ToLowerInvariant();
                break;
            case "zh-cn":
                lang = "zh-Hans";
                break;
            default:
                lang = "en";
                break;
        }
        return lang;
    }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        isMobile = PlatformHandler.IsMobile;

        lobbyUrl = isMobile ? Domain.MobileLobbyUrl : Domain.LobbyUrl;        
        
        if (UserSession == null || FunMode)
        {
            LaunchUrl = string.Format(Domain.GetCfg(Odobo.CasinoGameFunModeURL), this.Model.GameID.Trim(), this.Language, Domain.GetCfg(Odobo.CEStaticString));
        }
        else
        {
            TokenResponse response = GetToken();

            LaunchUrl = string.Format(Domain.GetCfg(Odobo.CasinoGameRealMoneyModeURL), Domain.GetCfg(Odobo.CEOperatorEnvirement), this.Model.GameID.Trim(), response.TokenKey, GetLanguage(this.Language));

            if (isMobile)
            {
                Response.Redirect(LaunchUrl);
            }
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
    <% if (this.UserSession != null)
       { %>
    <script src="https://code.jquery.com/jquery-latest.min.js" type="text/javascript"></script>
    <script type="text/javascript" src="<%= Url.Content("~/js/jquery.signalR-2.2.0.min.js") %>"></script>
    <script type="text/javascript" src="<%= Url.Content("~/signalr/hubs") %>" ></script>
    <script type="text/javascript">

        (function () {
            var userId = <%=this.UserSession.UserID%>;
            var domainId = <%=this.Model.DomainID%>;
            var lobbyUrl = '<%=lobbyUrl%>';

            var rcHub = $.connection.realityCheckHub;            
            
            rcHub.client.SendMessage = function (eventType) {
                if(eventType == "REALITY_CHECK_STOP"){  
                    rcHub.server.removeFromGroup(domainId, userId);   
                    window.top.location.href = lobbyUrl;
                }
            };

            $.connection.hub.start()
              .done(function() {
                rcHub.server.joinGroup(domainId, userId);        
            });
        })();        
    </script>
    <%} %>
    <iframe id="ifmGame" allowtransparency="true" frameborder="0" scrolling="no" src="<%= this.LaunchUrl.SafeHtmlEncode() %>"></iframe>
    <% Html.RenderPartial("GoogleAnalytics", this.Domain, new ViewDataDictionary()
           {
               { "Language", this.Language},
               { "IsLoggedIn", this.ViewData["UserSession"] != null },
           }
           ); %>
    <%=InjectScriptCode(Odobo.CELaunchInjectScriptUrl) %>    
</body>
</html>
