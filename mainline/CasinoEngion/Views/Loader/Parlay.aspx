<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>

<%@ Import Namespace="System.Dynamic" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Net" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GmGamingAPI" %>
<%@ Import Namespace="Newtonsoft.Json" %>

<script language="C#" type="text/C#" runat="server">

    protected string LauncherForm = "";
    protected string RoomId = "";

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        bool mobileDevice = CE.Utils.PlatformHandler.IsMobile;
        
        bool forceChannel = !String.IsNullOrWhiteSpace(Domain.GetCfg(Parlay.ForceChannel));

        //bool forceMobile = forceChannel && String.Compare(Domain.GetCfg(Parlay.ForceChannel), "mobile", StringComparison.InvariantCultureIgnoreCase) == 0;
        bool forceFlash = forceChannel && String.Compare(Domain.GetCfg(Parlay.ForceChannel), "flash", StringComparison.InvariantCultureIgnoreCase) == 0;

        bool useMobile = !forceFlash;
        
        string startUrl;
        
        StringBuilder url = new StringBuilder();
        url.Append(Domain.GetCfg(Parlay.GameBaseURL));
        url.AppendFormat("?siteId={0}&key={1}&gameCode={2}&language={3}&operatorId={4}&freePlay={5}&mobile={6}&clientId={7}&mode={8}",
            Domain.GetCfg(Parlay.SiteId),
            Domain.GetCfg(Parlay.Key),
            PrepareGameCode(),
            this.Language,
            Domain.GetCfg(Parlay.PartnerID),
            FunMode ? "true" : "false", 
            useMobile ? "true": "false", // request from parlay
            Domain.GetCfg(Parlay.ClientID),
            Domain.GetCfg(Parlay.Mode)
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
            startUrl += String.Format("&token={0}&currencyCode={1}", response.TokenKey, currency);
        }

        if (EnableLogging)
        {
            GmLogger.Instance.Trace(String.Format("Start Url: {0}", startUrl));
        }
        
        //this.LaunchUrl = startUrl.SafeHtmlEncode();
        string launcherHtml = GetParlayGameLauncher(startUrl);

        if (EnableLogging)
        {
            GmLogger.Instance.Trace(String.Format("Response html: {0}", launcherHtml));
        }
        
        int startIndex = launcherHtml.IndexOf("<form", StringComparison.InvariantCultureIgnoreCase);
        
        if (startIndex < 0)
        {
            if (EnableLogging)
                GmLogger.Instance.Error(String.Format("Expected <form> tag in pre-game launch response from vendor, while response is: url:{0} Response:{1}", startUrl, launcherHtml));
            
            throw new ApplicationException();
        }
        int endIndex = launcherHtml.IndexOf("</form>", StringComparison.InvariantCultureIgnoreCase);

        int endTagLength = "</form>".Length;
        launcherHtml = launcherHtml.Substring(startIndex, endIndex - startIndex + endTagLength);
        //ActionUrl = this.Url.RouteUrl("Loader", new { Action = "StartParlay", domainID = Domain.DomainID, id = this.Model.Slug});
        LauncherForm = launcherHtml.HtmlEncodeSpecialCharactors();
        
    }

    private string PrepareGameCode()
    {
        string[] parts = Model.GameID.Split("-".ToCharArray());

        if (parts.Length != 3)
        {
            throw new ApplicationException("Incorrect game ID format. Expected TYPE-ID-ROOM");
        }

        dynamic gameInfo = new ExpandoObject();
        gameInfo.type = parts[0];
        gameInfo.id = parts[1];
        gameInfo.room = parts[2];

        RoomId = parts[2];
        
        var gameCode = JsonConvert.SerializeObject(gameInfo, Formatting.None);
        return gameCode;
    }
    
    private string GetParlayGameLauncher(string url)
    {
        WebRequest request = WebRequest.Create(url);
        WebResponse response = request.GetResponse();
        var dataStream = response.GetResponseStream();
        StreamReader reader = new StreamReader(dataStream);
        string responseFromServer = reader.ReadToEnd();
        reader.Close();
        dataStream.Close();
        response.Close();
        return responseFromServer;
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
        <script src="//ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js"></script>
</head>
<body>
    
    <%--<form method="post" action='<%=ActionUrl.SafeHtmlEncode() %>' target="ifmGame" id="launchForm" >
                <input type="hidden" name="url" value='<%=LaunchUrl %>' />
    </form>--%>
    
    <%--<form action="http://66.212.233.209/gameserver/GameLaunchServlet" name="BI94" >
        <input name="LANGUAGE" type="hidden" value="da">
        <input name="USERID" type="hidden" value="DSJ_overem">
        <input name="SESSIONID" type="hidden" value="5F2FFA11EA404F8604FE1AD32CA3E6DF">
        <input name="GAMEID" type="hidden" value="BI94">
        <input name="MOBILE" type="hidden" value="true">
    </form>--%>
    
    <%=LauncherForm %>

    
    <iframe id="ifmGame" name="ifmGame" allowtransparency="true" frameborder="0" scrolling="no" ></iframe>

    <% Html.RenderPartial("GoogleAnalytics", this.Domain, new ViewDataDictionary()
           {
               { "Language", this.Language},
               { "IsLoggedIn", this.ViewData["UserSession"] != null },
           }
           ); %>
    
    <script type="text/javascript">

        $(document).ready(function() {

            var host = $('form').first().attr('action');
            var lang = $('input[name=LANGUAGE]').val();
            var userId = $('input[name=USERID]').val();
            var sessionId = $('input[name=SESSIONID]').val();
            var gameid = $('input[name=GAMEID]').val();
            var mobile = $('input[name=MOBILE]').val();
            var roomId = <%=RoomId%> ;
            var launcherUrl = host + '?LANGUAGE=' + lang + '&USERID=' + userId + '&SESSIONID=' + sessionId +
                '&GAMEID=' + gameid + '&MOBILE=' + mobile + '&ROOMID=' + roomId;

            $('#ifmGame').attr('src', launcherUrl);


        });
        
        
    </script>

    <%=InjectScriptCode(Parlay.CELaunchInjectScriptUrl) %>

</body>
</html>
