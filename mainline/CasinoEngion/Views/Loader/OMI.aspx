<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script language="C#" type="text/C#" runat="server">
    public override string GetLanguage(string lang)
    {
        switch (lang.ToLowerInvariant())
        {
            case "sv":
            case "tr":
            case "zh-cn":
            case "no":
                lang = lang.ToLowerInvariant();
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

        bool isMobileGame = false;
        switch (Request.GetTerminalType())
        {
            case TerminalType.iPad:
            case TerminalType.iPhone:
            case TerminalType.Android:
                isMobileGame = true;
                break;

            default:
                break;
        }

        string sessionID = string.Empty;
        if (UserSession != null && !FunMode)
        {
            if (UseGmGaming)
            {
                sessionID = GetToken().TokenKey;
            }
            else
            {
                throw new CeException("GmGaming only valid to get token");
            }
        }

        string urlFormat = isMobileGame ? Domain.GetCfg(OMI.MobileGameURL) : Domain.GetCfg(OMI.CasinoGameURL);

        this.LaunchUrl = string.Format(CultureInfo.InvariantCulture, urlFormat
            , this.Model.GameID // {0}
            , this.Model.GameCode // {1}
            , this.Language // {2}
            , sessionID // {3}
            , HttpUtility.UrlEncode(Domain.MobileLobbyUrl) // {4}
            );

        if (isMobileGame)
            Response.Redirect(this.LaunchUrl);
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
    html, body { width:100%; height:100%; padding:0px; margin:0px; background:#E9E9E9; overflow:hidden; }
    #ifmGame { width:100%; height:100%; border:0px; }
    </style>
</head>
<body>
    <iframe id="ifmGame" allowTransparency="true" frameborder="0" scrolling="no" src="<%= this.LaunchUrl.SafeHtmlEncode() %>"></iframe>
    <% Html.RenderPartial("GoogleAnalytics", this.Domain, new ViewDataDictionary()
           {
               { "Language", this.Language},
               { "IsLoggedIn", this.ViewData["UserSession"] != null },
           }
           ); %>
    <%=InjectScriptCode(OMI.CELaunchInjectScriptUrl) %>
</body>
</html>