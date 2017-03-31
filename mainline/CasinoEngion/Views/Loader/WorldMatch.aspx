<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="GmGamingAPI" %>

<script language="C#" type="text/C#" runat="server">
    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        
        StringBuilder url = new StringBuilder();
        url.Append(Domain.GetCfg(WorldMatch.GameBaseURL));
        url.AppendFormat("{0}/{1}/{2}/{3}/", FunMode ? "free" : "real", this.Model.ExtraParameter2, this.Model.GameID, this.Model.ExtraParameter1);
        url.AppendFormat("?display=iframe&language={0}", this.Language);
        url.AppendFormat("&age={0}", WorldMatch.ShowAgeWarning.ToLowerInvariant() == "true" ? "true" : "false");
        
        if (!FunMode)
        {
            TokenResponse response = GetToken();

            string authskin = string.Empty;
            if (response.AdditionalParameters.Exists(a => a.Name == "authskin"))
                authskin = response.AdditionalParameters.First(a => a.Name == "authskin").Value;
                
            url.AppendFormat("&authuser={0}", UserSession.UserID);
            url.AppendFormat("&authkey={0}", response.TokenKey);
            url.AppendFormat("&authskin={0}", authskin);
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
    <%=InjectScriptCode(WorldMatch.CELaunchInjectScriptUrl) %>
</body>
</html>