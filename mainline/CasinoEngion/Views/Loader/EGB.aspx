<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmGamingAPI" %>

<script language="C#" type="text/C#" runat="server">
    public override string GetLanguage(string lang)
    {
        if (string.IsNullOrEmpty(lang))
            return "EN";

        switch (lang.ToLowerInvariant())
        {
            case "de":
            case "cs":
            case "pl":
            case "es":
                return lang.ToUpperInvariant();
            default:
                return "EN";
        }
    }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        StringBuilder url = new StringBuilder();
        url.Append(Domain.GetCfg(EGB.GameBaseURL));
        url.AppendFormat("?gameKey={0}", this.Model.GameID);
        url.AppendFormat("&templateName={0}", HttpUtility.UrlEncode(Domain.GetCfg(EGB.TemplateName)));
        url.AppendFormat("&lang={0}", this.Language.ToUpperInvariant());

        string token = string.Empty;

        if (FunMode)
        {
            if (UseGmGaming)
            {
                string domainIdPart = "~" + Domain.DomainID;
                StringBuilder sb = new StringBuilder(Guid.NewGuid().ToString("N"));
                sb.Remove(sb.Length - 1 - domainIdPart.Length, domainIdPart.Length);
                sb.Append(domainIdPart);
                token = sb.ToString();
            }
            else
            {
                throw new CeException("GmGaming only valid to get token");
            }

            url.AppendFormat("&gameMode=fun&sessionToken={0}", token);
        }
        else
        {
            string playerName = string.Empty;

            if (UseGmGaming)
            {
                TokenResponse response = GetToken();

                if (response.AdditionalParameters.Exists(a => a.Name == "PlayerName"))
                    playerName = response.AdditionalParameters.First(a => a.Name == "PlayerName").Value;

                token = response.TokenKey;
            }
            else
            {
                throw new CeException("GmGaming only valid to get token");
            }

            url.AppendFormat("&gameMode=money&sessionToken={0}&playerName={1}", token, playerName);
        }

        this.LaunchUrl = url.ToString();
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
    <%=InjectScriptCode(EGB.CELaunchInjectScriptUrl) %>
</body>
</html>