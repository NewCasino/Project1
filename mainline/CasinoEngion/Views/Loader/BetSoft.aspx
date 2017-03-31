<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script language="C#" type="text/C#" runat="server">
    public override string GetLanguage(string lang)
    {
        if (string.IsNullOrWhiteSpace(lang))
            return "en";

        switch (lang.ToLowerInvariant())
        {
            case "no":
            case "nl":
            case "ru":
            case "fr":
            case "fi":
            case "tr":
            case "dk":
            case "pt":
            case "de":
            case "bg":
            case "pl":
            case "hu":
            case "ro":
            case "zh":
            case "zh-cn":
            case "zh-tw":
                break;
                
            case "cs":
                lang = "cz";
                break;

            case "sv":
                lang = "se";
                break;

            default:
                lang = "en";
                break;
        }

        return lang.ToLowerInvariant();
    }
    
    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        if (UserSession != null && !FunMode)
        {
            // http://lobby.everymatrix.betsoftgaming.com/cwguestlogin.do?bankId={0}&amp;gameId={1}&amp;lang={2}&amp;mode=real&amp;token={3}
            LaunchUrl = string.Format(Domain.GetCfg(BetSoft.CasinoGameRealMoneyModeURL)
                , Domain.GetCfg(BetSoft.BankID)
                , this.Model.GameID
                , Language
                , GetLaunchToken()
                );
        }
        else
        {
            // http://lobby.everymatrix.betsoftgaming.com/cwguestlogin.do?bankId={0}&amp;gameId={1}&amp;lang={2}
            LaunchUrl = string.Format(Domain.GetCfg(BetSoft.CasinoGameFunModeURL)
                , Domain.GetCfg(BetSoft.BankID)
                , this.Model.GameID
                , Language
                );
        }

        if (Request.GetTerminalType() != TerminalType.PC)
            Response.Redirect(this.LaunchUrl);
    }

    
    private string GetLaunchToken()
    {
        if (UseGmGaming)
        {
            return GetToken().TokenKey;
        }
        else
        {
            throw new CeException("GmGaming only valid to get token");
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
    <%=InjectScriptCode(BetSoft.CELaunchInjectScriptUrl) %>
</body>
</html>
