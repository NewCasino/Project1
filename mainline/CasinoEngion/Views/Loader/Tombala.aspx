<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GmGamingAPI" %>

<script language="C#" type="text/C#" runat="server">

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        bool mobileDevice = CE.Utils.PlatformHandler.IsMobile;
        if (UserSession == null || FunMode)
            throw new CeException("Tombala Live Casino is only available in real money mode!");
        
        string baseGameUrl = mobileDevice ? Domain.GetCfg(Tombala.MobileGameBaseURL) : Domain.GetCfg(Tombala.GameBaseURL);
        StringBuilder url = new StringBuilder(baseGameUrl);

        TokenResponse token = GetToken();
        if (token.AdditionalParameters != null && token.AdditionalParameters.Exists(a => a.Name == "token"))
        {
            string tombalaToken = token.AdditionalParameters.First(a => a.Name == "token").Value;
            url.AppendFormat("/{0}", tombalaToken);
        }
        else
        {
            throw new CeException("Faild to load vendor addition parameter - token from Gic");
        }

        this.LaunchUrl = url.ToString();
        if (mobileDevice)
        {
            Response.Redirect(url.ToString());
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
           {"Language", this.Language},
           {"IsLoggedIn", this.ViewData["UserSession"] != null},
       }
           ); %>
    <%=InjectScriptCode(Tombala.CELaunchInjectScriptUrl) %>
</body>
</html>
