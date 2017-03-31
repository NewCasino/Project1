<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>

<%@ Import Namespace="CE.db" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Integration.VendorApi" %>
<%@ Import Namespace="CE.Integration.VendorApi.Models" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GmGamingAPI" %>

<script language="C#" type="text/C#" runat="server">

    public override string GetLanguage(string lang)
    {
        //Korean,
        //Japenese,
        //Chinese,
        //Traditional Chinese,
        //English

        SupportedLanguages = new List<string> { "en", "zh-tw", "zh-cn", "ja", "ko" };
        return base.GetLanguage(lang);
    }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        
        const string vendorName = "TTG";

        bool showLiveLobby = Domain.GetCfg(TTG.ShowLiveLobby) == "true" || Model.GameName.ToLower().Contains("lobby");
        bool mobileDevice = PlatformHandler.IsMobile;
        string isdId = Domain.GetCfg(TTG.IsdId);
        StringBuilder url = new StringBuilder(mobileDevice ? Domain.GetCfg(TTG.GameBaseMobileURL) : Domain.GetCfg(TTG.GameBaseURL));
        StringBuilder lobbyUrl = mobileDevice|| showLiveLobby ? new StringBuilder(Domain.GetCfg(TTG.GameBaseLobbyURL)) : null;
        
        var typeAndName = Model.GameID.Split('_');
        string startgameName = typeAndName.First();
        string gameType = typeAndName.Last();
        
        if (!FunMode)
        {
            string currency = UserSession.Currency;
            
            using (VendorApiClient vendorApi = new VendorApiClient(vendorName))
            {
                CreateGameSessionResponse gameSessionResponse = vendorApi.CreateGameSession(new CreateGameSessionRequest
                {
                    DomainId = Domain.DomainID,
                    VendorName = vendorName,
                    UserDetails =
                    { 
                        UserId = UserSession.UserID,
                        UserName = UserSession.Username,
                        FirstName = UserSession.Firstname,
                        LastName = UserSession.Surname,
                        UserCasinoCurrency = currency
                    },
                    AdditionParameters = { {"UserCountryCode", UserSession.UserCountryCode} }
                });

                if (!gameSessionResponse.Success)
                {
                    throw new CeException(string.Format("Invalid response from vendor side, {0}", gameSessionResponse.Message));
                }

                if (!gameSessionResponse.AdditionalParameters.ContainsKey("UserCasinoCurrency"))
                {
                    throw new CeException("UserCasinoCurrency parameter is required");
                }
                currency = gameSessionResponse.AdditionalParameters["UserCasinoCurrency"];

                url.AppendFormat("?playerHandle={0}&account={1}",
                    gameSessionResponse.GameSession,
                    currency);

                if (mobileDevice || showLiveLobby)
                {
                    lobbyUrl.AppendFormat("?playerHandle={0}&account={1}",
                        gameSessionResponse.GameSession,
                        currency);
                }

                List<NameValue> addParams = new List<NameValue> { new NameValue { Name = "GameSessionId", Value = gameSessionResponse.GameSession } };
                GetToken(addParams);
            }
        }
        else
        {
            url.AppendFormat("?playerHandle=999999&account=FunAcct");

            if (mobileDevice || showLiveLobby)
            {
                lobbyUrl.AppendFormat("?playerHandle=999999&account=FunAcct");
            }
        }
        
        url.AppendFormat("&gameName={0}&gameType={1}&gameId={2}&lang={3}&lsdId={4}&deviceType={5}",
                startgameName,
                gameType,
                Model.GameCode,
                Language,
                isdId,
                mobileDevice ? "mobile" : "web");
        
        if (mobileDevice || showLiveLobby)
        {
            lobbyUrl.AppendFormat("&lang={0}&deviceType={1}", Language, mobileDevice? "mobile": "web");
            if (mobileDevice)
            {
                url.AppendFormat("&lobbyUrl={0}", lobbyUrl);    
            }
        }

        var startUrl = showLiveLobby ? lobbyUrl.ToString() : url.ToString();
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
    <%=InjectScriptCode(TTG.CELaunchInjectScriptUrl) %>

</body>
</html>
