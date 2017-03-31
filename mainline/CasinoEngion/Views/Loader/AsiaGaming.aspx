<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Integration.VendorApi" %>
<%@ Import Namespace="CE.Integration.VendorApi.Models" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GmGamingAPI" %>

<script language="C#" type="text/C#" runat="server">

    private const string VendorName = "AsiaGaming";   

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        bool mobileDevice = PlatformHandler.IsMobile;

        string balance = string.Empty;
        string currencyList = string.Empty;
        string launchBaseUrl = mobileDevice ? Domain.GetCfg(AsiaGaming.MobileGameBaseURL) : Domain.GetCfg(AsiaGaming.GameBaseURL);

        TokenResponse tokenResponse = GetToken();
        if (tokenResponse.AdditionalParameters.Exists(a => a.Name == "UserCasinoBalance"))
        {
            balance = tokenResponse.AdditionalParameters.First(a => a.Name == "UserCasinoBalance").Value;
        }
        if (tokenResponse.AdditionalParameters.Exists(a => a.Name == "SupportedCurrencies"))
        {
            currencyList = tokenResponse.AdditionalParameters.First(a => a.Name == "SupportedCurrencies").Value;          
        }

        if (string.IsNullOrEmpty(balance))
        {
            throw new CeException(string.Format("Cant get balance from current user, {0}", UserSession.Username));
        }
        if (string.IsNullOrEmpty(currencyList))
        {
            throw new CeException("User supproted currencies list is empty");
        }
      
       string token = tokenResponse.TokenKey;
       string userCurrency = GetSupportedCurrency(currencyList);

       using (VendorApiClient vendorApi = new VendorApiClient(VendorName))
        {
            CreateUserResponse userResponse = vendorApi.CreateUser(new CreateUserRequest
            {
                DomainId = Domain.DomainID,
                UserDetails =
                {
                    UserId = UserSession.UserID,
                    UserName = UserSession.Username,
                    UserCasinoCurrency = userCurrency
                },
                AdditionParameters =
                {
                  { "balance", balance },
                  { "token", token }  
                }
            });

            if (!userResponse.Success)
            {
                throw new CeException(string.Format("Invalid response when creating user on vendor side, {0}", userResponse.Message));
            }
        }

        string md5Key = Domain.GetCfg(AsiaGaming.Md5Key);
        string desKey = Domain.GetCfg(AsiaGaming.DesKey);
        string paramsFormat = CreateRequestParams(userCurrency, token, mobileDevice);
        string desParamsFormat = paramsFormat.DesEncryptWithKey(desKey);
        string keyFormat = string.Format("{0}{1}", desParamsFormat, md5Key);
        string md5ParamsFormat = keyFormat.MD5Hash();

        string launchUrl = string.Format("{0}?params={1}&key={2}", launchBaseUrl, desParamsFormat, md5ParamsFormat);

        this.LaunchUrl = launchUrl;

        if (mobileDevice)
        {
            Response.Redirect(LaunchUrl);
        }
    }

    private string CreateRequestParams(string currency, string token, bool isMobile)
    {        
        string cagent = Domain.GetCfg(AsiaGaming.Cagent);
        string password = GetPassword();
        string sid = string.Format("{0}{1}", cagent, token);
        string mh5 = isMobile ? "y" : "n";
        string requestParams = string.Format(
             "cagent={0}/\\\\/loginname={1}/\\\\/password={2}/\\\\/dm={3}/\\\\/sid={4}/\\\\/mh5={5}\\\\/actype=1/\\\\/gameType={6}/\\\\/oddtype=A/\\\\/cur={7}/\\\\/lang=1",
             cagent, UserSession.Username, password, Domain.Name, sid, mh5, GameID, currency);

        return requestParams;
    }

    private string GetSupportedCurrency(string supportedCurrencies)
    {
        string currency = string.Empty;
        if (supportedCurrencies.Contains(UserSession.Currency))
        {
            currency = UserSession.Currency;
        }
        else
        {
            currency = GetDefaultCurrency(supportedCurrencies);
        }

        return currency;
    }

    private string GetDefaultCurrency(string supportedCurrencies)
    {
        string[] currencies = supportedCurrencies.Split(',').ToArray();

        return currencies.FirstOrDefault();
    }

    private string GetPassword()
    {
        string password = string.Format("{0}~{1}", UserSession.DomainID, UserSession.UserID);
        return password.ToBase36String();
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
    <%=InjectScriptCode(AsiaGaming.CELaunchInjectScriptUrl) %>

</body>
</html>
