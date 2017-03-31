<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="CE.db" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmGamingAPI" %>

<script language="C#" type="text/C#" runat="server">
    public override string GetLanguage(string lang)
    {
        if (string.IsNullOrWhiteSpace(lang))
            return "en";

        switch (lang.Truncate(2).ToLowerInvariant())
        {
            case "en":
            case "ko":
            case "ja":
            case "el":
            case "it":
            case "th":
            case "es":
            case "ru":
            case "vi":
            case "id":
            case "zh-cn":
                return "zh-CN";
            case "zh-tw":
                return "zh-TW";
            default:
                return "en";
        }
    }

    //VendorID = 188
    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        bool isMobileDevice = CE.Utils.PlatformHandler.IsMobile;
        string merchantCode = Domain.GetCfg(Entwine.MerchantCode);

        if (UserSession == null || FunMode)
            throw new CeException("Entwine Live Casino is only available in real money mode!");

        StringBuilder url = new StringBuilder();

        TokenResponse response = GetToken();

        if (isMobileDevice)
        {
            url.AppendFormat(Domain.GetCfg(Entwine.MobileGameBaseUrl));
        }
        else
        {
            Uri apiUri = new Uri(Domain.GetCfg(Entwine.DesktopGameBaseUrl));
        }

        url.AppendFormat("SingleLogin?merchantcode={0}&lang={1}&userId={2}&uuId={3}"
            , merchantCode
            , this.Language
            , UserSession.UserID
            , response.TokenKey
            );

        this.LaunchUrl = url.ToString();

        if (isMobileDevice)
        {
            Response.Redirect(LaunchUrl);
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
<% if (UseGmGaming){ %>
<body class="Rest">
<% } else{ %>
<body>
<% } %>
    <iframe id="ifmGame" allowTransparency="true" frameborder="0" scrolling="no" src="<%= this.LaunchUrl.SafeHtmlEncode() %>"></iframe>
    <% Html.RenderPartial("GoogleAnalytics", this.Domain, new ViewDataDictionary()
           {
               { "Language", this.Language},
               { "IsLoggedIn", this.ViewData["UserSession"] != null },
           }
           ); %>
    <%=InjectScriptCode(Entwine.CELaunchInjectScriptUrl) %>
</body>
</html>