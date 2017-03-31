<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.ServiceModel.Configuration" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Integration.VendorApi" %>
<%@ Import Namespace="CE.Integration.VendorApi.Models" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GmGamingAPI" %>
<%@ Import Namespace="Newtonsoft.Json.Linq" %>

<script language="C#" type="text/C#" runat="server">

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        const string vendorName = "Magnet";

        string gameFrameUrl = string.Empty;

        if (!FunMode && UserSession != null)
        {
            using (VendorApiClient vendorApi = new VendorApiClient(vendorName))
            {
                GameListResponse gameListResponse = vendorApi.GetGameList(new GameListRequest
                {
                    DomainId = Domain.DomainID,
                    VendorName = vendorName
                });

                if (!gameListResponse.Success)
                {
                    throw new CeException(string.Format("Invalid response when getting games configurations from vendor side, {0}", gameListResponse.Message));
                }
                
                var gameInfo = gameListResponse.VendorData.FirstOrDefault(game => game.GameId == GameID);
                if (gameInfo == null)
                {
                    throw new CeException(string.Format("Can't found configuration for gameId {0}", GameID));
                }

                CreateUserResponse createUserResponse = vendorApi.CreateUser(new CreateUserRequest
                {
                    DomainId = Domain.DomainID,
                    UserDetails =
                    {
                        UserId = UserSession.UserID,
                        UserName = UserSession.Username,
                    }
                });

                if (!createUserResponse.Success)
                {
                    throw new CeException(string.Format("Invalid response when getting games configurations from vendor side, {0}", createUserResponse.Message));
                }

                CreateGameSessionResponse gameSessionResponse = vendorApi.CreateGameSession(new CreateGameSessionRequest
                {
                    DomainId = Domain.DomainID,
                    VendorName = vendorName,
                    UserDetails = { UserId = UserSession.UserID },
                    AdditionParameters =
                    {
                        {"GameConfiguration", gameInfo.ConfigId },
                        { "SessionIdFromCe", Session.SessionID },
                        { "ExternalUserId", createUserResponse.UserId }
                    }
                });

                if (!gameSessionResponse.Success)
                {
                    throw new CeException(string.Format("Invalid response when getting games configurations from vendor side, {0}", createUserResponse.Message));
                }
                if (!gameSessionResponse.AdditionalParameters.ContainsKey("GameFrameUrl"))
                {
                    throw new CeException("GameFrameUrl parameter is required"); 
                }

                gameFrameUrl = gameSessionResponse.AdditionalParameters["GameFrameUrl"];
            }
        }
        
        this.LaunchUrl = gameFrameUrl;
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
    <%=InjectScriptCode(Multislot.CELaunchInjectScriptUrl) %>

</body>
</html>
