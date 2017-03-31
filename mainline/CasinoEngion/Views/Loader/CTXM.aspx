<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script language="C#" type="text/C#" runat="server">
    private string CreateCTXMTicket()
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
    
    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        StringBuilder url = new StringBuilder();
        url.Append(Domain.GetCfg(CTXM.CasinoGameBaseURL));

        // game_code
        url.AppendFormat("&game_code={0}", HttpUtility.UrlEncode(this.Model.GameID));

        if (UserSession != null && !FunMode)
        {
            string ticket = CreateCTXMTicket();
            url.Append("&playmode=real");
            url.AppendFormat("&ticket={0}", HttpUtility.UrlEncode(ticket));
        }
        else
        {
            url.Append("&playmode=fun");
        }

        // singlegame
        url.Append("&singlegame=true");

        // disableLogout
        url.Append("&disableLogout=true");

        // lockPlaymode
        url.Append("&lockPlaymode=true");

        // uniformScaling
        url.Append("&uniformScaling=true");

        url.AppendFormat("&language={0}", HttpUtility.UrlEncode(Language.ToUpper()));

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
    <%=InjectScriptCode(CTXM.CELaunchInjectScriptUrl) %>
</body>
</html>