<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>

<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script language="C#" type="text/C#" runat="server">
    private bool IsMobile { get; set; }
    
    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        string currency = "EUR";
        string organizationName = "Jetbull";
        int realityCheck = 0;

        string baseUrl = string.Empty;
        
        if (FunMode)
        {
            baseUrl = (UserSession != null) ? Domain.GetCountrySpecificCfg(Yggdrasil.FunModeGameBaseURL, UserSession.UserCountryCode, UserSession.IpCountryCode) :
                Domain.GetCfg(Yggdrasil.FunModeGameBaseURL);
        }
        else
        {
            baseUrl = (UserSession != null) ? Domain.GetCountrySpecificCfg(Yggdrasil.GameBaseURL, UserSession.UserCountryCode, UserSession.IpCountryCode) :
                Domain.GetCfg(Yggdrasil.GameBaseURL);                
        }

        StringBuilder url = new StringBuilder(baseUrl);

        url.AppendFormat("?gameid={0}", this.Model.GameID);
        url.AppendFormat("&lang={0}", string.IsNullOrEmpty(this.Language) ? "EN" : this.Language.ToUpperInvariant());
        url.AppendFormat("&channel={0}", PlatformHandler.IsMobile ? "mobile" : "pc");

        if (FunMode)
        {
            url.Append("&org=Demo&key=");
        }
        else
        {
            string token = string.Empty;
            if (UseGmGaming)
            {
                var tokenResponse = GetToken();
                token = tokenResponse.TokenKey;

                if (tokenResponse.AdditionalParameters.Exists(a => a.Name == "Currency"))
                    currency = tokenResponse.AdditionalParameters.First(a => a.Name == "Currency").Value;

                if (tokenResponse.AdditionalParameters.Exists(a => a.Name == "OrganizationName"))
                    organizationName = tokenResponse.AdditionalParameters.First(a => a.Name == "OrganizationName").Value;

                if (tokenResponse.AdditionalParameters.Exists(a => a.Name == "RealityCheckSec"))
                    realityCheck = Int32.Parse(tokenResponse.AdditionalParameters.First(a => a.Name == "RealityCheckSec").Value)/60;
            }
            else
            {
                throw new CeException("GmGaming only valid to get token");
            }

            url.AppendFormat("&currency={0}", currency);
            url.AppendFormat("&org={0}&key={1}", organizationName, token);
            if (realityCheck > 0)
            {
                url.AppendFormat("&reminderElapsed=0&reminderInterval={0}", realityCheck);
            }            
        }

        this.LaunchUrl = url.ToString();

        IsMobile = CE.Utils.PlatformHandler.IsMobile;
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
    <%if (!IsMobile) { %>
    <iframe id="ifmGame" allowtransparency="true" frameborder="0" scrolling="no" src="<%= this.LaunchUrl.SafeHtmlEncode() %>"></iframe>
    <%} else {%>
    <script type="text/javascript">
        function __redirect() {
            try {
                self.location.replace('<%= this.LaunchUrl.SafeJavascriptStringEncode() %>');
            }
            catch (e) {
                self.location = '<%= this.LaunchUrl.SafeJavascriptStringEncode() %>';
            }
        }
        setTimeout(3000, __redirect());
    </script>
    <%}%>
    <% Html.RenderPartial("GoogleAnalytics", this.Domain, new ViewDataDictionary()
           {
               { "Language", this.Language},
               { "IsLoggedIn", this.ViewData["UserSession"] != null },
           }
           ); %>
    <%=InjectScriptCode(Yggdrasil.CELaunchInjectScriptUrl) %>
</body>
</html>
