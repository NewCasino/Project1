<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="System.Security.Cryptography" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="Newtonsoft.Json.Linq" %>

<script language="C#" type="text/C#" runat="server">

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        if (UserSession == null)
            throw new CeException("_sid is mandatory for PokerKlas game!");

        string pokerKlasUrlTemp = Domain.GetCfg(PokerKlas.VendorAPIUrl);
        string getPresentationURL;
        string methodName = "createLobbyURL";
        string responseType = "json";
        string pokerKlasUserName = CreatePokerKlasUserName(UserSession.Username, UserSession.DomainID);
        string merchantLogin = Domain.GetCfg(PokerKlas.APIMerchantLogin);
        string privateKey = Domain.GetCfg(PokerKlas.APIPrivateKey);

        string stringToSign = string.Format("{0}{1}{2}{3}{4}", methodName, pokerKlasUserName, merchantLogin, responseType, privateKey);
        string signature = stringToSign.MD5Hash(Encoding.UTF8);
        pokerKlasUrlTemp += "?method={0}&username={1}&merchantId={2}&responseType={3}&hash={4}";
        getPresentationURL = string.Format(pokerKlasUrlTemp, methodName, pokerKlasUserName, merchantLogin, responseType, signature);


        this.LaunchUrl = GetLaunchUrlFromVendor(getPresentationURL);
    }

    private string GetLaunchUrlFromVendor(string getPresentationURL)
    {
        Uri apiUri = new Uri(getPresentationURL);

        string response = HttpHelper.PostData(apiUri, null);
        string launchUrl = GetLaunchUrlFromResponse(response);
        return launchUrl;
    }

    string GetLaunchUrlFromResponse(string response)
    {
        if (string.IsNullOrEmpty(response))
        {
            throw new CeException("Invalid PokerKlas GamePresentationURL response");
        }
        else
        {
            JObject jsonResp = JObject.Parse(response);
            JToken launchUrl;
            if (jsonResp.TryGetValue("response", out launchUrl))
            {
                if (launchUrl != null && (string)launchUrl["status"] != "failed")
                {
                    return (string) launchUrl["url"];
                }
                else
                {
                    GmLogger.Instance.Error(String.Format("Error while launching the game is: Response:{0}", response));
                    throw new CeException("Error occured during launching the game. Please, try again later.");
                }
            }
            else
            {
                throw new CeException("Error occured during launching the game. Please, try again later.");
            }
        }
    }

    private string CreatePokerKlasUserName
        (string userName, long domainId)
    {
        return string.Format("{0}_{1}", userName, domainId.ToString());
    }

</script>

<html xmlns="http://www.w3.org/1999/xhtml" lang="<%= this.Language %>">
<head>
    <title><%= this.Model.GameName.SafeHtmlEncode() %></title>
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1"/>
    <meta name="keywords" content="<%= this.Model.Tags.SafeHtmlEncode() %>"/>
    <meta name="description" content="<%= this.Model.Description.SafeHtmlEncode() %>"/>
    <meta http-equiv="pragma" content="no-cache"/>
    <meta http-equiv="content-language" content="<%= this.Language %>"/>
    <meta http-equiv="cache-control" content="no-store, must-revalidate"/>
    <meta http-equiv="expires" content="Wed, 26 Feb 1997 08:21:57 GMT"/>
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
<iframe id="ifmGame" allowTransparency="true" frameborder="0" scrolling="no" src="<%= this.LaunchUrl.SafeHtmlEncode() %>"></iframe>
<% Html.RenderPartial("GoogleAnalytics", this.Domain, new ViewDataDictionary()
   {
       {"Language", this.Language},
       {"IsLoggedIn", this.ViewData["UserSession"] != null},
   }
       ); %>
</body>
</html>