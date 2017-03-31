<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>

<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="GmGamingAPI" %>

<script language="C#" type="text/C#" runat="server">

    protected int InitialWidth;
    protected int InitialHeight;

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        bool showLiveLobby = Domain.GetCfg(Authentic.ShowLiveLobby) == "true";
        string gameId = string.Format("gameCode={0}&", Model.GameID);
        bool mobileDevice = CE.Utils.PlatformHandler.IsMobile;

        string startUrl = string.Empty;

        InitialWidth = Model.Width;
        InitialHeight = Model.Height;


        if (!FunMode)
        {
            StringBuilder url = new StringBuilder();
            url.Append(Domain.GetCfg(Authentic.GameBaseURL));
            url.AppendFormat("?{0}language={1}&operatorId={2}&freePlay={3}&mobile={4}&clientId={5}&mode={6}",
                showLiveLobby ? string.Empty : gameId,
                this.Language,
                Domain.GetCfg(Authentic.PartnerID),
                "false",
                mobileDevice ? "true" : "false",
                UserSession.Username,
                Domain.GetCfg(Authentic.Mode)
                );
            startUrl = url.ToString();


            TokenResponse response = GetToken();
            string currency = UserSession.Currency;
            if (response.AdditionalParameters.Exists(a => a.Name == "UserCasinoCurrency"))
            {
                currency = response.AdditionalParameters.First(a => a.Name == "UserCasinoCurrency").Value;
            }
            startUrl += String.Format("&token={0}&currencyCode={1}", response.TokenKey, currency);
        }

        this.LaunchUrl = startUrl;
        if (mobileDevice)
        {
            string mobileUrl = this.LaunchUrl;
            if (!string.IsNullOrWhiteSpace(Domain.MobileLobbyUrl))
                mobileUrl = mobileUrl + "&lobbyUrl=" + Domain.MobileLobbyUrl;
            Response.Redirect(mobileUrl);
        }         
    }

</script>

<html xmlns="http://www.w3.org/1999/xhtml" lang="<%= this.Language %>">
<head>
    <script language="javascript" type="text/javascript" src="/js/jquery-1.7.2.min.js"></script>
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
            background-color: #000;
            text-align: center;
            background: #000;
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
    
    <iframe id="ifmGame" allowtransparency="true" frameborder="0" scrolling="no" allowfullscreen="allowfullscreen" src="<%= this.LaunchUrl %>"></iframe>
    <% Html.RenderPartial("GoogleAnalytics", this.Domain, new ViewDataDictionary()
           {
               { "Language", this.Language},
               { "IsLoggedIn", this.ViewData["UserSession"] != null },
           }
           ); %>
    <%=InjectScriptCode(Authentic.CELaunchInjectScriptUrl) %>
    
    <script type="text/javascript">

          $(document).ready(function() {
              $(window).bind( 'resize', resizeGame);     
              resizeGame();
          });

          function resizeGame() {
              var initialWidth = <%= InitialWidth %> * 1.00;
              var initialHeight = <%= InitialHeight %> * 1.00;

              var height = $(document.body).height() * 1.00;
              var width = $(document.body).width() * 1.00;

              var newWidth = width;
              var newHeight = newWidth * initialHeight / initialWidth;
              if (newHeight > height) {
                  newHeight = height;
                  newWidth = newHeight * initialWidth / initialHeight;
              }
              $('#ifmGame').width(newWidth).height(newHeight);
          }
    </script>

</body>
</html>
