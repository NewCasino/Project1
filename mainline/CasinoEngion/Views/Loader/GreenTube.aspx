<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GmGamingAPI" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="Newtonsoft.Json" %>
<%@ Import Namespace="Newtonsoft.Json.Linq" %>
<%@ Import Namespace="System.Dynamic" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.Security.Cryptography" %>
<%@ Import Namespace="System.Xml" %>
<script language="C#" type="text/C#" runat="server">
    private string SwfUrl
    {
        get;
        set;
    }
    private string FlashVars
    {
        get;
        set;
    }
           
    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        bool mobileDevice = CE.Utils.PlatformHandler.IsMobile;
        int gameID;
        
        if (!int.TryParse(this.Model.GameID, out gameID))
            throw new CeException("Invalid GreenTube Game ID: [{0}]", this.Model.GameID);

        if (!UseGmGaming)
        {
            if (UserSession == null)
                throw new CeException("_sid is mandatory for GreenTube game!");
            
            GetLaunchUrlFromGmCore(gameID);
        }
        else
        {
            //"https://gg-nrgs-b2b-staging.greentube.com/Nrgs/B2B/Service/Storm/V5/{0}/Games/{1}/Sessions/PresentationURL?Protocol={2}"
            string greentubeUrlTemp =  Domain.GetCfg(GreenTube.VendorAPIUrl);
            string getPresentationURL;
            string content = string.Empty;

            string secretKey =  Domain.GetCfg(GreenTube.APISecretKey);
            string publicKey =  Domain.GetCfg(GreenTube.APIPublicKey);
            string urlProtocol =  Domain.GetCfg(GreenTube.CELaunchUrlProtocol);
            string clientTechnology = mobileDevice || this.Model.LaunchGameInHtml5 ? "HTML5" : "Flash";
            
            if (UserSession == null)
            {
                getPresentationURL = string.Format(greentubeUrlTemp, "Demo", gameID, urlProtocol);
                dynamic data = new ExpandoObject();
                data.LanguageCode = Language;
                data.ClientTechnology = clientTechnology;
                content = JsonConvert.SerializeObject(data, Newtonsoft.Json.Formatting.None);
            }
            else
            {
                if (FunMode)
                {
                    greentubeUrlTemp += "&UserId={3}";
                    getPresentationURL = string.Format(greentubeUrlTemp, "Fun", gameID, urlProtocol, UserSession.UserID);

                    dynamic data = new ExpandoObject();
                    data.LanguageCode = Language;
                    data.ClientTechnology = clientTechnology;
                    content = JsonConvert.SerializeObject(data, Newtonsoft.Json.Formatting.None);
                }
                else
                {
                    TokenResponse response = GetToken();

                    greentubeUrlTemp += "&UserId={3}";
                    getPresentationURL = string.Format(greentubeUrlTemp, "Cash", gameID, urlProtocol, response.UserId);

                    dynamic data = new ExpandoObject();
                    data.LanguageCode = Language;
                    data.ClientTechnology = clientTechnology;
                    data.PartnerUserSessionKey = response.TokenKey;
                    content = JsonConvert.SerializeObject(data, Newtonsoft.Json.Formatting.None);
                }
            }

            this.LaunchUrl = GetLaunchUrlFromVendor(getPresentationURL, content, secretKey, publicKey);

            if (mobileDevice)
            {
                Response.Redirect(this.LaunchUrl);
            }
        }        
    }

    private string GetLaunchUrlFromVendor(string getPresentationURL, string content, string secretKey, string publicKey)
    {
        Uri apiUri = new Uri(getPresentationURL);
        string utcDateTime = DateTime.UtcNow.ToString("s") + "Z";

        string requestUri = apiUri.PathAndQuery;
        string signature = CreateSignature(secretKey, "POST", utcDateTime, requestUri, content);

        NameValueCollection headers = new NameValueCollection();
        headers.Add("Content-Type", "application/json");
        headers.Add("DateUtc", utcDateTime);
        headers.Add("Authorization", string.Format("V1 {0} {1}", publicKey, signature));

        string response = HttpHelper.PostData(apiUri, content, headers);
        string launchUrl = GetLaunchUrlFromResponse(response);
        return launchUrl;
    }

    private string CreateSignature(string secretKey, string method, string utcTime, string link, string content)
    {
        string signature = null;
        
        string contentHash = string.Empty;
        if(!string.IsNullOrEmpty(content))
        {
            using (var md5Hasher = new MD5CryptoServiceProvider())
            {
                byte[] contentHex = md5Hasher.ComputeHash(Encoding.UTF8.GetBytes(content));
                contentHash = ByteArrayToString(contentHex);
            }
        }       

        string stringToSign = string.Format("{0}\n{1}\n{2}\n{3}", method, utcTime, link, contentHash);

        HMACSHA1 hasher = new HMACSHA1(Encoding.UTF8.GetBytes(secretKey));
        hasher.Initialize();
        byte[] sign = hasher.ComputeHash(Encoding.UTF8.GetBytes(stringToSign));
        signature = ByteArrayToString(sign);

        return signature;
    }

    private string ByteArrayToString(byte[] data)
    {
        StringBuilder hex = new StringBuilder(data.Length * 2);
        foreach (byte b in data)
            hex.AppendFormat("{0:x2}", b);
        return hex.ToString().ToUpperInvariant();
    }

    private string GetLaunchUrlFromResponse(string response)
    {
        if(string.IsNullOrEmpty(response)){
            throw new CeException("Invalid GreenTube GamePresentationURL response");
        }
        else{
            JObject jsonResp = JObject.Parse(response);
            JToken launchUrl;
            if (jsonResp.TryGetValue("GamePresentationURL", out launchUrl))
            {
                return launchUrl.Value<string>();
            }
            else
            {
                throw new CeException("Invalid GreenTube GamePresentationURL response: " + response);                
            }
        }        
    }

    private void GetLaunchUrlFromGmCore(int gameID)
    {
        GreentubeGetPresentationParametersRequest getPresentationParametersRequest;
        if (FunMode)
        {
            getPresentationParametersRequest = new GreentubeGetPresentationParametersRequest()
            {
                TicketType = TicketTypeCode.FunGame,
                UserId = UserSession.UserID.ToString(),
            };
        }
        else
        {
            getPresentationParametersRequest = new GreentubeGetPresentationParametersRequest()
            {
                TicketType = TicketTypeCode.RealCash,
                UserId = UserSession.UserID.ToString(),
            };
        }
        getPresentationParametersRequest.LanguageCode = Language.ToUpperInvariant();
        getPresentationParametersRequest.GameId = gameID;
       
        
        using (GamMatrixClient client = new GamMatrixClient())
        {           
            GreenTubeAPIRequest request = new GreenTubeAPIRequest()
            {
                GetPresentationParametersRequest = getPresentationParametersRequest
            };
            request = client.SingleRequest<GreenTubeAPIRequest>(Domain.DomainID, request);
            LogGmClientRequest(request.SESSION_ID, request.GetPresentationParametersResponse.ErrorCode.ToString(), "ErrorCode");

            if (request.GetPresentationParametersResponse.ErrorCode < 0)
                throw new CeException(request.GetPresentationParametersResponse.Message.Description);

            string url = string.Format(CultureInfo.InvariantCulture
                , "{0}?clientAuthToken={1}"
                , request.GetPresentationParametersResponse.InterfaceUrl
                , HttpUtility.UrlEncode( request.GetPresentationParametersResponse.ClientAuthToken )
                );/*
<?xml version="1.0" encoding="UTF-8"?>
<GreentubeGameClient>
   <gameURL>https://mux-cdn.greentube.com/slot/2012-07-10_1117/slot_10.swf</gameURL>
   <parameterList>
      <parameter name="hostname">ip62-116-24-7.greentube.com</parameter>
      <parameter name="port">40831</parameter>
      <parameter name="roomid">4382</parameter>
      <parameter name="playerid">86229104</parameter>
      <parameter name="password">D868F3AD-A9D2-4126-A988-B28B455D9DC5</parameter>
      <parameter name="skin">english,fourkingcash,deepwalletuser</parameter>
      <parameter name="nolobby">1</parameter>
      <parameter name="crypto">1</parameter>
      <parameter name="hidestatuswindow">1</parameter>
      <parameter name="realitycheckintervalminutes">0</parameter>
      <parameter name="realitycheckintervalrounds">0</parameter>
   </parameterList>
</GreentubeGameClient>
             */
            XDocument xDoc = XDocument.Load(url);
            XElement gameUrlNode = xDoc.Root.Element("gameURL");
            XElement parameterListNode = xDoc.Root.Element("parameterList");
            if (gameUrlNode == null || parameterListNode == null)
            {
                using (XmlReader xr = xDoc.Root.CreateReader())
                {
                    xr.MoveToContent();
                    throw new CeException(xr.ReadInnerXml());
                }
            }
            this.SwfUrl = gameUrlNode.Value;

            StringBuilder flashVars = new StringBuilder();
            IEnumerable<XElement> parameterNodes = parameterListNode.Elements("parameter");
            foreach( XElement parameterNode in parameterNodes )
            {
                if( parameterNode.Attribute("name") == null )
                    continue;
                flashVars.AppendFormat(CultureInfo.InvariantCulture, "{0}={1}&"
                    , HttpUtility.UrlEncode(parameterNode.Attribute("name").Value)
                    , HttpUtility.UrlEncode(parameterNode.Value)
                    );
            }
            if (flashVars.Length > 0)
                flashVars.Remove(flashVars.Length - 1, 1);
            this.FlashVars = flashVars.ToString();
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
     <iframe id="ifmGame" allowtransparency="true" frameborder="0" scrolling="no" src="<%= this.LaunchUrl.SafeHtmlEncode() %>"></iframe>   

    <% Html.RenderPartial("GoogleAnalytics", this.Domain, new ViewDataDictionary()
           {
               { "Language", this.Language},
               { "IsLoggedIn", this.ViewData["UserSession"] != null },
           }
           ); %>
    <%=InjectScriptCode(GreenTube.CELaunchInjectScriptUrl) %>
</body>
</html>