<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>

<%@ Import Namespace="System.Security.Cryptography" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Integration.VendorApi" %>
<%@ Import Namespace="CE.Integration.VendorApi.Models" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GmGamingAPI" %>

<script language="C#" type="text/C#" runat="server">
    
    private const string VendorName = "GoldenRace";

    public override string GetLanguage(string lang)
    {
        switch (lang.ToLowerInvariant())
        {
            case "de": return "de_DE";
            case "en": return "en_GB";
            case "es": return "es_ES";
            case "ge": return "ge_GE";
            case "it": return "it_IT";
            case "pt": return "pt_PT";
            case "th": return "th_TH";
            case "tr": return "tr_TR";
            case "ru": return "ru_RU";

            default: return "en_GB";
        }
    }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        var isVirtualGame = GameID == Domain.GetCfg(GoldenRace.VirtualGameId);
        var baseUrl = isVirtualGame ? Domain.GetCfg(GoldenRace.VirtualGameBaseUrl) : Domain.GetCfg(GoldenRace.CasinoGameBaseUrl);

        var queryParams = new NameValueCollection();

        if (FunMode)
        {
            queryParams.Add("t", Domain.GetCfg(GoldenRace.DemoGameModeValue));
        }
        else
        {
            // Generate Token
            var vendorLoginHash = CreateOrLoginVendorUser();
            var loginHashParam = new NameValue("vendorLoginHash", vendorLoginHash);

            TokenResponse token = GetToken(new List<NameValue> { loginHashParam });
            queryParams.Add("loginHash", token.TokenKey);
        }

        if (isVirtualGame)
        {
            var launchParams = Domain.GetCfg(GoldenRace.VirtualsAdditionalLaunchParameters);
            if (!string.IsNullOrWhiteSpace(launchParams))
            {
                var additionalParameters = HttpUtility.ParseQueryString(launchParams);
                queryParams.Add(additionalParameters);
            }
        }
        else
        {
            var gameCountdown = Domain.GetCfg(GoldenRace.CasinoGameCountdown);
            
            queryParams.Add("product", "online");
            queryParams.Add("profile", "tablet");
            queryParams.Add("gameId", GameID);
            queryParams.Add("gameCountdown", gameCountdown);
        }

        queryParams.Add("lang", Language);

        var urlBuilder = new UriBuilder(baseUrl)
        {
            Query = string.Join("&", queryParams.AllKeys.Select(a => a + "=" + HttpUtility.UrlEncode(queryParams[a])))
        };
        LaunchUrl = urlBuilder.ToString();
    }

    private string CreateOrLoginVendorUser()
    {
        var password = string.Format("{0}~{1}", Domain.DomainID, UserSession.UserID);
        using (var client = new VendorApiClient(VendorName))
        {
            var hashedPassword = GetPasswordHash(password);
            var createUserRequest = new CreateUserRequest
            {
                DomainId = Domain.DomainID,
                UserDetails =
                {
                    UserId = UserSession.UserID,
                    UserPassword = hashedPassword,
                    UserCasinoCurrency = UserSession.Currency,
                    UserName = UserSession.Username
                }
            };

            var userResponse = client.CreateUser(createUserRequest);
            if (!userResponse.Success)
            {
                throw new CeException(string.Format("Error on calling VendorApi.CreateUser: {0}", userResponse.Message));
            }

            var sessionRequest = new CreateGameSessionRequest
            {
                DomainId = Domain.DomainID,
                UserDetails =
                {
                    UserId = UserSession.UserID,
                    UserPassword = hashedPassword
                }
            };

            var sessionResponse = client.CreateGameSession(sessionRequest);
            if (!sessionResponse.Success)
            {
                throw new CeException(string.Format("Error on calling VendorApi.CreateGameSession: {0}", sessionResponse.Message));
            }

            return sessionResponse.GameSession;
        }
    }

    private static string GetPasswordHash(string passwod)
    {
        using (var md5 = MD5.Create())
        {
            var bytes = Encoding.UTF8.GetBytes(passwod);
            var hashedBytes = md5.ComputeHash(bytes);
            return BitConverter.ToString(hashedBytes).Replace("-", string.Empty).ToLower();
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
        #playarea {
            position: absolute;
            /*top: 60px;*/
            width: 100%;
            height: 100%;
            min-height: 100%;
            overflow: hidden;
        }

        #gameframe {
            position: fixed;
        }

        iframe.noScrolling {
            width: 100%;
            height: 100%;
            overflow: hidden;
        }
    </style>
    <script language="javascript" type="text/javascript" src="/js/jquery-1.7.2.min.js"></script>
    <script>
        $(window).scroll(function () {
            var iframe = $('#gameframe');
            var playarea = $('#playarea');
            iframe.css({ top: playarea.offset().top - $(window).scrollTop() + "px" });
            iframe.css({ left: playarea.offset().left - $(window).scrollLeft() + "px" });

            // This is only needed to support iframe in different domain
            iframe[0].contentWindow.postMessage('onScroll:' + $(window).scrollTop() + ':' + iframe.offset().top + ':' + $(window).height() + ':' + playarea.height(), '*');
        });

        window.addEventListener('message', function (e) {
            if (e.data.split) {
                var args = e.data.split(":");
                if (args[0] == "resizeBody") {
                    $('#gameframe')[0].style.height = args[1];
                    $('#playarea')[0].style.height = args[1];
                }
                else if (args[0] == "moveTop")
                    $(window.parent.document).find('body,html').animate({ scrollTop: args[1] }, 400);
            }
        });
    </script>
</head>
<body>
    <div id='playarea'>
        <iframe
            id='gameframe'
            class='noScrolling'
            frameborder="0"
            seamless="seamless"
            scrolling="no"
            marginheight="0"
            marginwidth="0"
            src="<%= LaunchUrl.SafeHtmlEncode() %>"
            style="min-width: 1000px;"></iframe>
    </div>
    <% Html.RenderPartial("GoogleAnalytics", Domain, new ViewDataDictionary
       {
           {"Language", Language},
           {"IsLoggedIn", ViewData["UserSession"] != null}
       }); %>
    <%=InjectScriptCode(GoldenRace.CELaunchInjectScriptUrl) %>
</body>
</html>
