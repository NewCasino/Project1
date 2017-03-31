<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>

<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="GmGamingAPI" %>

<script language="C#" type="text/C#" runat="server">
  
    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        bool mobileDevice = CE.Utils.PlatformHandler.IsMobile;
        string customertId = Domain.GetCfg(GaminGenius.CustomerId);
        string gamingServerURL = Domain.GetCfg(GaminGenius.GamingServerURL);
        Uri apiUri = new Uri(Domain.GetCfg(GaminGenius.VendorAPIUrl));
        
        StringBuilder url = new StringBuilder();
        url.Append(apiUri);
        
        if (FunMode)
        {
            url.AppendFormat("{0}/?customerid={1}", Model.GameName, "demo");                            
        }
        else
        {
            TokenResponse tokenResponse = GetToken();
            string currency;
            if (tokenResponse != null &&
                tokenResponse.AdditionalParameters != null &&
                tokenResponse.AdditionalParameters.Exists(a => a.Name == "UserCasinoCurrency"))
            {
                currency = tokenResponse.AdditionalParameters.First(a => a.Name == "UserCasinoCurrency").Value;
            }
            else
            {
                string responseJson = new System.Web.Script.Serialization.JavaScriptSerializer().Serialize(tokenResponse);
                throw new ApplicationException(String.Format("UserCasinoCurrency was expected but not found in GIC response : {0}", responseJson));
            }

            url.AppendFormat("{0}/?customerid={1}&gameid={2}&currency={3}&original={4}&remotesessionid={5}&url={6}", Model.GameName, customertId, Model.GameID, currency, UserSession.IpCountryCode, tokenResponse.TokenKey, gamingServerURL);
        }
        
        this.LaunchUrl = url.ToString();
        
        if (mobileDevice)
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
    <script type="text/javascript" src="/js/jquery-1.7.2.min.js" ></script>
    <script type="text/javascript" src="/js/swfobject.js"></script>
</head>
<body>
    <iframe id="ifmGame" allowTransparency="true" frameborder="0" scrolling="no" src="<%= this.LaunchUrl.SafeHtmlEncode() %>"></iframe>   

    <% Html.RenderPartial("GoogleAnalytics", this.Domain, new ViewDataDictionary()
           {
               { "Language", this.Language},
               { "IsLoggedIn", this.ViewData["UserSession"] != null },
           }
           ); %>
    <%=InjectScriptCode(GaminGenius.CELaunchInjectScriptUrl) %>
</body>
</html>