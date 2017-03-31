<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>

<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Integration.VendorApi" %>
<%@ Import Namespace="CE.Integration.VendorApi.Models" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GmGamingAPI" %>

<script language="C#" type="text/C#" runat="server">

    private const string VendorName = "Opus";
    private string TokenKey = string.Empty;
    private string GameDomain = string.Empty;

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        
        List<NameValue> addParams = new List<NameValue>()
            {
                new NameValue { Name = "currency", Value = UserSession.Currency },
                new NameValue { Name = "language", Value = this.Language },
                new NameValue { Name = "balance", Value = "0" },
                new NameValue { Name = "userName", Value = UserSession.Username }
            };

        TokenKey = GetToken(addParams).TokenKey;
        GameDomain = Domain.GetCfg(Opus.GameDomain);

        var gameDetails = this.GameID.Split('~');
        if (gameDetails.Length == 2)
        {
            LaunchUrl = Domain.GetCfg(Opus.GameBaseURL);

            string subvendorName = gameDetails[0];
            string gameId = gameDetails[1];
            string launchContent = SetLaunchContent(subvendorName, gameId);

            LaunchUrl = string.Concat(LaunchUrl, launchContent);
        }
        else
        {
            throw new CeException("Wrong GameId for Opus subvendor games. GameId : " + this.GameID);
        }
        if (PlatformHandler.IsMobile)
        {
            Response.Redirect(LaunchUrl);
        }

    }

    private string SetLaunchContent(string subVendor, string gameId)
    {
        string funMode = FunMode ? "0" : "1";
        string launchContent = string.Empty;

        switch (subVendor.ToLower())
        {
            case "gameos":
                launchContent = GetGameOSLaunchContent(gameId, funMode);
                break;
            case "pragmatic":
                launchContent = GetPragmaticLaunchContent(gameId, funMode);
                break;
            case "mg":
                launchContent = GetMGLaunchContent(gameId, funMode);
                break;
            case "opus":
                launchContent = GetOpusLaunchContent(gameId);
                break;
            default:
                break;
        }

        return launchContent;
    }

    private string GetOpusLaunchContent(string gameId)
    {
        return gameId.Equals("lobby2", StringComparison.OrdinalIgnoreCase) ? "/Intro2.aspx" : "/Intro.aspx";
    }

    private string GetGameOSLaunchContent(string gameId, string funMode)
    {
        string pcLaunchContent = Domain.GetCfg(Opus.SubVendorGameOSLaunchPart);
        string mobileLaunchContent = Domain.GetCfg(Opus.SubVendorGameOSMobileLaunchPart);
        return PlatformHandler.IsMobile ?
            string.Format(mobileLaunchContent, gameId, funMode) :
            string.Format(pcLaunchContent, gameId, funMode);
    }

    private string GetPragmaticLaunchContent(string gameId, string funMode)
    {
        string pcLaunchContent = Domain.GetCfg(Opus.SubVendorPragmaticLaunchPart);
        string pcContent = string.Format(pcLaunchContent, gameId, funMode);

        if (PlatformHandler.IsMobile)
        {
            return string.Concat(pcContent, "&ismobile=", funMode);
        }

        return pcContent;
    }

    private string GetMGLaunchContent(string gameId, string funMode)
    {
        string pcLaunchContent = Domain.GetCfg(Opus.SubVendorMGLaunchPart);
        string pcContent = string.Format(pcLaunchContent, gameId, funMode);

        if (PlatformHandler.IsMobile)
        {
            return string.Concat(pcContent, "&ismobile=", funMode);
        }

        return pcContent;
    }


    public override string GetLanguage(string lang)
    {
        var dic = new Dictionary<string, string>();
        dic.Add("en", "en-US");
        dic.Add("zh", "zh-CN");
        dic.Add("th", "th-TH");
        dic.Add("vi", "vi-VN");
        dic.Add("ja", "ja-JP");
        dic.Add("id", "id-ID");
        dic.Add("it", "km-KH");
        if (string.IsNullOrWhiteSpace(lang))
            lang = "en";
        else
            lang = lang.Truncate(2).ToLowerInvariant();

        if (dic.Keys.Contains(lang))
            return dic[lang];

        return "en-US";
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
    <iframe id="ifmGame" allowtransparency="true" frameborder="0" scrolling="no" src="<%= LaunchUrl %>"></iframe>
    <script type="text/javascript">
        function SetCookies() {
            var myDate = new Date();
            myDate.setMonth(myDate.getMonth() + 12);
            var languageCookie = "SelectedLanguage=" + "<%= this.Language %>";
        var sessionToken = "S=" + "<%= TokenKey %>";

        document.cookie = languageCookie +
            ";expires=" + myDate +
            ";domain=" + "<%= GameDomain %>" +
            ";path=/";

        document.cookie = sessionToken +
            ";expires=" + myDate +
            ";domain=" + "<%= GameDomain %>" + //".casinodeveverymatrix.com" 
            ";path=/";
    }

    SetCookies();

    </script>
</body>
</html>
