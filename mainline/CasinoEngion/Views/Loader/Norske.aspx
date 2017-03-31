<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script language="C#" type="text/C#" runat="server"> 
    public override string GetLanguage(string lang)
    {
        switch (lang.ToLowerInvariant())
        {
            case "en": return "eng";
            case "sv": return "swe";
            case "fi": return "fin";
            case "es": return "spa";
            case "fr": return "fra";
            case "de": return "due";
            case "it": return "ita";
            case "nl": return "nld";
            case "el": return "ell";
            case "ja": return "jpn";
            case "ko": return "kor";
            case "no": return "nor";
            case "pt": return "por";
            case "ru": return "rus";
            case "tr": return "tur";
            case "dk": return "dan";
            case "pl": return "pol";
            case "bg": return "bul";
            case "hr": return "hrv";
            case "cs": return "ces";
            case "hu": return "hun";
            case "uk": return "ukr";
            case "zh": return "zh_cn";
            case "zh-cn": return "zho";
            case "zh-tw": return "zho";
            default: return "eng";
        }
    }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        StringBuilder url = new StringBuilder();
        url.Append(Domain.GetCfg(Norske.CasinoGameBaseURL));
        url.AppendFormat("?bankId={0}", HttpUtility.UrlEncode("EC12"));
        url.AppendFormat("&gameId={0}", HttpUtility.UrlEncode(this.Model.GameID));
        url.AppendFormat("&lang={0}", HttpUtility.UrlEncode(this.Language));
        
        if (UserSession != null && !FunMode)
        {
            string token;
            if (UseGmGaming)
            {
                token = GetToken().TokenKey;
            }
            else
                using (GamMatrixClient client = new GamMatrixClient())
                {
                    var request = new NorskeGetSessionRequest()
                    {
                        UserID = UserSession.UserID,
                    };

                    request = client.SingleRequest<NorskeGetSessionRequest>(UserSession.DomainID, request);
                    LogGmClientRequest(request.SESSION_ID, request.Token);

                    token = request.Token;
                }

            url.AppendFormat("&mode=real&token={0}", HttpUtility.UrlEncode(token));
            string affiliateMarker = UserSession.AffiliateMarker;
            if (!string.IsNullOrWhiteSpace(affiliateMarker))
                url.AppendFormat("&affiliateid={0}", HttpUtility.UrlEncode(affiliateMarker));
        }        
        
        this.LaunchUrl = url.ToString();

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
        
        if (isMobileGame)
        {
            Response.Redirect(this.LaunchUrl);
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
    <%=InjectScriptCode(Norske.CELaunchInjectScriptUrl) %>
</body>
</html>