<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="GmGamingAPI" %>


<script language="C#" type="text/C#" runat="server">


    public override string GetLanguage(string lang)
    {
        switch (lang.ToLowerInvariant())
        {
            case "en": return "en_US";
            case "es": return "es_ES";
            case "zh-cn": return "zh_CN";
            case "zh-tw": return "zh_TW";
            case "ms": return "ms-MY";
            default: return "en_US";
        }
    }
    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        
        var urlBuilder = new StringBuilder();
        urlBuilder.Append(Domain.GetCfg(PlayStar.GameBaseUrl));
        urlBuilder.AppendFormat("/launch/?host_id={0}&game_id={1}&lang={2}", Domain.GetCfg(PlayStar.HostId), this.Model.GameID, this.Language);

        if (!FunMode)
        {
            TokenResponse response = GetToken();
            urlBuilder.AppendFormat("&access_token={0}", response.TokenKey);
        }
        
        if (!string.IsNullOrEmpty(Domain.GetCfg(PlayStar.ReturnUrl)))
        {
            urlBuilder.AppendFormat("&return_url={0}", Domain.GetCfg(PlayStar.ReturnUrl));
        }
        
        LaunchUrl = urlBuilder.ToString();
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
    <%=InjectScriptCode(PlayStar.CELaunchInjectScriptUrl) %>
</body>
</html>