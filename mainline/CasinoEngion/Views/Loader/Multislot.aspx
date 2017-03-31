<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GmGamingAPI" %>

<script language="C#" type="text/C#" runat="server">

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        bool mobileDevice = PlatformHandler.IsMobile;
        StringBuilder startUrl = new StringBuilder(Domain.GetCfg(Multislot.GameLaunchBaseURL));

        if (!FunMode && UserSession != null)
        {
            StringBuilder url = new StringBuilder(Domain.GetCfg(Multislot.GameTokenBaseURL));

            TokenResponse response = GetToken();
            if (response != null &&
                response.AdditionalParameters != null)
            {
                string userId = UserSession.UserID.ToString(CultureInfo.InvariantCulture);
                if (response.AdditionalParameters.Exists(a => a.Name == "UserId"))
                {
                    userId = response.AdditionalParameters.First(a => a.Name == "UserId").Value;
                }

                url.AppendFormat("?UserId={0}&UserKey={1}&Provider={2}&Target={3}", userId, response.TokenKey, Domain.GetCfg(Multislot.Provider), "none");

                string multislotResponse = HttpHelper.GetData(new Uri(url.ToString()));

                string token = string.Empty;
                if (multislotResponse != null)
                {
                    if (multislotResponse.StartsWith("ErrorCode"))
                    {
                        throw new ApplicationException(String.Format("Vendor Token creation error with response : {0}", multislotResponse));
                    }

                    foreach (string item in multislotResponse.Split('&'))
                    {
                        string[] parts = item.Replace('?', '\0').Split('=');
                        if (parts.Length > 0 && !string.IsNullOrEmpty(parts[0]) && parts[0].ToLowerInvariant() == "token")
                        {
                            token = parts[1];
                            break;
                        }
                    }
                }

                startUrl.AppendFormat("?Token={0}&CasinoGameId={1}&AccountId={2}&Lang={3}", token, Model.GameID, FunMode ? -1 : 1, Language);
            }
            else
            {
                string responseJson = new JavaScriptSerializer().Serialize(response);
                throw new ApplicationException(String.Format("Token creation error in GIC response : {0}", responseJson));
            }

        }
        else
        {
            startUrl.AppendFormat("?Token=&CasinoGameId={0}&AccountId={1}&Lang={2}", Model.GameID, FunMode ? -1 : 1, Language);  
        }
        this.LaunchUrl = startUrl.ToString();

        if (mobileDevice)
        {
            Response.Redirect(startUrl.ToString());
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
    <%=InjectScriptCode(Multislot.CELaunchInjectScriptUrl) %>

</body>
</html>
