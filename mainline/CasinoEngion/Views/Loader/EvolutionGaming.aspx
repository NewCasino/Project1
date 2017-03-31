<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>

<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>
<%@ Import Namespace="CE.db" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Integration.VendorApi" %>
<%@ Import Namespace="CE.Integration.VendorApi.Models" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmGamingAPI" %>

<script language="C#" type="text/C#" runat="server">
    protected bool IsMobile = false;
    protected int RealityCheckTimeout = 60;
    protected string FrameScriptUrl;
    protected string TokenKey;

    public override string GetLanguage(string lang)
    {
        if (string.IsNullOrEmpty(lang))
            return "en";

        switch (lang.ToLowerInvariant())
        {
            case "al":
            case "bp":
            case "bg":
            case "ca":
            case "hr":
            case "cs":
            case "dk":
            case "nl":
            case "ee":
            case "fi":
            case "fr":
            case "de":
            case "el":
            case "he":
            case "hu":
            case "it":
            case "ja":
            case "no":
            case "pl":
            case "pt":
            case "ro":
            case "ru":
            case "sr":
            case "sk":
            case "sl":
            case "es":
            case "sv":
            case "th":
            case "tr":
            case "ko":
                lang = lang.ToLowerInvariant();
                break;

            case "zh-cn":
                lang = "cn";
                break;

            case "zh-tw":
                lang = "b5";
                break;

            default:
                lang = "en";
                break;
        }
        return lang;
    }

    protected override void OnInit(EventArgs e)
    {
        const string vendorName = "EvolutionGaming";
        string country = string.Empty;
        
        base.OnInit(e);

        if (string.IsNullOrWhiteSpace(TableID))
            throw new CeException("Table ID is missing.");

        Dictionary<string, ceLiveCasinoTableBaseEx> tables = global::CacheManager.GetLiveCasinoTableDictionary(Domain.DomainID);
        ceLiveCasinoTableBaseEx table;
        if (!tables.TryGetValue(TableID, out table))
            throw new CeException("Invalid table id [{0}].", TableID);

        IsMobile = CE.Utils.PlatformHandler.IsMobile;

        if (UserSession == null || FunMode)
            throw new CeException("Evolution game is only available in real money mode.");

        int page;
        if (!int.TryParse(this.Model.GameID.Trim(), NumberStyles.Integer, CultureInfo.InvariantCulture, out page))
            throw new CeException("Incorrect game id [{0}].", this.Model.GameID);

        string pageValue = "106";
        string tableIdValue = table.ExtraParameter3;
        var pageTableItems = table.ExtraParameter3.Split('-');
        if (pageTableItems.Length == 2)
        {
            tableIdValue = pageTableItems[0];
            pageValue = pageTableItems[1];
        }

        TokenResponse response = GetToken();

        if (response.AdditionalParameters.Exists(a => a.Name == "LaunchUrl"))
        {
            LaunchUrl = response.AdditionalParameters.First(a => a.Name == "LaunchUrl").Value;
        }
        else
        {

            if (response.AdditionalParameters.Exists(a => a.Name == "RealityCheckSec"))
            {
                RealityCheckTimeout = Int32.Parse(response.AdditionalParameters.First(a => a.Name == "RealityCheckSec").Value);
            }

            if (response.AdditionalParameters.Exists(a => a.Name == "Country"))
            {
                country = response.AdditionalParameters.First(a => a.Name == "Country").Value;
            }

            using (VendorApiClient vendorApi = new VendorApiClient(vendorName))
            {
                CreateGameSessionResponse gameSessionResponse = vendorApi.CreateGameSession(new CreateGameSessionRequest
                {
                    DomainId = Domain.DomainID,
                    VendorName = vendorName,
                    IsMobile = IsMobile,
                    UserDetails = {UserId = UserSession.UserID},
                    AdditionParameters =
                    {
                        {"Page", pageValue},
                        {"GameType", table.ExtraParameter1},
                        {"GameInterface", table.ExtraParameter2},
                        {"TableID", tableIdValue},
                        {"VirtualTableID", table.ExtraParameter4},
                        {"UserLanguage", Language},
                        {"Token", response.TokenKey},
                        {"Cashier", GetLobbyUrl()},
                        {"ResponsibleGaming", response.TokenKey},
                        {"Lobby", response.TokenKey},
                        {"SessionTimeout", response.TokenKey},
                        {"Country", country}
                    }
                });

                LaunchUrl = gameSessionResponse.GameSession;
            }
        }
        
        Uri uri = new Uri(LaunchUrl);
        FrameScriptUrl = uri.Scheme + Uri.SchemeDelimiter + uri.Host + "/mobile/js/iframe.js";
    }

    private string GetLobbyUrl()
    {
        string casinoLobbyUrl = Domain.GetCfg(EvolutionGaming.CELiveCasinoMobileLobbyUrl);
        return casinoLobbyUrl;
    }
    private string GetLobbyButton()
    {
        string casinoLobbyUrl = GetLobbyUrl();
        if (!string.IsNullOrWhiteSpace(casinoLobbyUrl))
        {
            return string.Format("<a href=\"javascript:void(0);\" class=\"Button GBLButton hiddened\" onclick=\"GoToLobby('{0}');\"><span class=\"ButtonText\">Return to lobby</span><span class=\"RTButtonText\">Lobby</span></a>",
                casinoLobbyUrl);
        }
        return "";
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

        .GBLButton {
            border-radius: 0;
            display: block;
            height: 34px;
            right: 5px;
            position: fixed;
            top: 5px;
            width: 36px;
            z-index: 999999;
        }

        .ButtonText {
            background: none repeat scroll 0 0 #FFFFFF;
            border-radius: 1px;
            box-shadow: 0 0 2px 1px #FFFFFF;
            color: #FFFFFF;
            display: block;
            font-size: 0;
            margin-left: 4px;
            margin-top: 1px;
            overflow: hidden;
            padding-left: 29px;
            padding-top: 28px;
            width: 1px;
        }

        .RTButtonText {
            background: url("//cdn.everymatrix.com/Generic/img/ce-button.png") no-repeat;
            color: #FFFFFF;
            display: block;
            height: 1px;
            left: 1px;
            overflow: hidden;
            padding-left: 34px;
            padding-top: 34px;
            position: absolute;
            top: 0;
            width: 0;
        }
    </style>
    <script src="https://code.jquery.com/jquery-latest.min.js" type="text/javascript"></script>

    <% if (RealityCheckTimeout > 0)
       { %>
    <script type="text/javascript" src="<%= Url.Content("~/js/realityCheck.js") %>"></script>
    <% } %>

    <script type="text/javascript" src="<%=FrameScriptUrl%>"></script>

</head>
<body>
    <% Html.RenderPartial("GoogleAnalytics", this.Domain, new ViewDataDictionary()
           {
               { "Language", this.Language},
               { "IsLoggedIn", this.ViewData["UserSession"] != null },
           }
           ); %>
    <%=InjectScriptCode(EvolutionGaming.CELaunchInjectScriptUrl) %>

    <% if (RealityCheckTimeout > 0)
       { %>

    <script type="text/javascript">
        
        var config = {
            beforeShowMessageFunction: beforeMessageShow,
            messageAcknowlegeFunction: afterMessageShow,
            realitychecktimeout: <%=RealityCheckTimeout%>,
            historyLink: '<%=IsMobile ? Domain.MobileAccountHistoryUrl : Domain.AccountHistoryUrl%>',
            lobbyLink: '<%=IsMobile ? Domain.MobileLobbyUrl : Domain.LobbyUrl%>'
        }

        window.onload = function () {
            emrc.init(config);

            EvolutionGaming.loadGame({
                authToken: '<%=TokenKey%>',
                url: '<%=LaunchUrl%>'
            });

            EvolutionGaming.on("betsOpen", function () {
                emrc.changeGameStatus(false);
            });

            EvolutionGaming.on("betsClosed", function () {
                emrc.changeGameStatus(true);
            });
        }

        function beforeMessageShow() {
            
            emrc.show();
        }

        function afterMessageShow() {
            // notify game that need to resume
        }

    </script>


    <% }
       else
       { %>

    <iframe id="ifmGame" allowtransparency="true" frameborder="0" scrolling="no" src="<%= this.LaunchUrl.SafeHtmlEncode() %>"></iframe>

    <% } %>
</body>
</html>
