<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="Newtonsoft.Json.Linq" %>
<%@ Import Namespace="System.Security.Cryptography" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>
<%@ Import Namespace="GmGamingAPI" %>
<%@ Import Namespace="Newtonsoft.Json" %>
<script language="C#" type="text/C#" runat="server">
    private bool IsMobile { get; set; }
    
    private static readonly HashSet<string> SupportedLanguages = new HashSet<string>()
    {
        "ar",
        "bg",
        "da",
        "de",
        "en",
        "es",
        "fi",
        "fil",
        "fr",
        "id",
        "it",
        "ja",
        "km",
        "ko",
        "lo",
        "lv",
        "ms",
        "nl",
        "no",
        "pt",
        "ru",
        "sk",
        "sv",
        "th",
        "tr",
        "vi",
        "zh"
    };
  
    public override string GetLanguage(string lang)
    {
        if (string.IsNullOrEmpty(lang))
            return "en";
        string lowerLang = lang.ToLowerInvariant();

        if (SupportedLanguages.Contains(lowerLang))
        {
            return lowerLang;
        }
        
        return "en";
    }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        string secret = Domain.GetCfg(BoomingGames.SecretKey);
        string key = Domain.GetCfg(BoomingGames.APIKey);
        string baseUrl = Domain.GetCfg(BoomingGames.VendorAPIBaseUrl);
        string sessionUrl = Domain.GetCfg(BoomingGames.VendorAPISessionUrlPath);
        string callback = Domain.GetCfg(BoomingGames.CallBackURL);
        string rollbackCallback = Domain.GetCfg(BoomingGames.CancelURL);
        string nonce = DateTime.UtcNow.Ticks.ToString();
        Uri apiUri = new Uri(baseUrl + sessionUrl);

        Dictionary<string, string> content = null;
        if (UserSession == null || FunMode)
        {
            content = new Dictionary<string, string>
            {
                {"game_id", Model.GameID},
                {"balance", "1000.0"},
                {"demo", "true"},
                {"locale", Language},
                {"variant", PlatformHandler.IsMobile ? "mobile" : "hds"},
                {"currency", "EUR"},
                {"player_id", UserSession != null ? UserSession.UserID.ToString(CultureInfo.InvariantCulture) : string.Empty},
                {"callback", callback},
                {"rollback_callback", rollbackCallback}
            };
        }
        else
        {
            List<NameValue> addParams = new List<NameValue>
            {
                new NameValue {Name = "UserLanguage", Value = Language}
            };

            TokenResponse tokenResponse = GetToken(addParams);

            string currency = string.Empty, balance = string.Empty;

            if (tokenResponse != null &&
                tokenResponse.AdditionalParameters != null)
            {
                if (tokenResponse.AdditionalParameters.Exists(a => a.Name == "UserCasinoCurrency"))
                {
                    currency = tokenResponse.AdditionalParameters.First(a => a.Name == "UserCasinoCurrency").Value;
                }

                if (tokenResponse.AdditionalParameters.Exists(a => a.Name == "UserCasinoBalance"))
                {
                    balance = tokenResponse.AdditionalParameters.First(a => a.Name == "UserCasinoBalance").Value;
                }
            }
            else
            {
                string responseJson = new JavaScriptSerializer().Serialize(tokenResponse);
                throw new ApplicationException(String.Format("AdditionalParameters was expected but not found in GIC response : {0}", responseJson));
            }

            content = new Dictionary<string, string>
            {
                {"game_id", Model.GameID},
                {"balance", balance},
                {"demo", "false"},
                {"locale", Language},
                {"variant", PlatformHandler.IsMobile ? "mobile" : "hds"},
                {"currency", currency},
                {"player_id", UserSession != null ? UserSession.UserID.ToString(CultureInfo.InvariantCulture) : string.Empty},
                {"callback", string.Format(@"{0}/?token={1}&gameId={2}", callback, tokenResponse.TokenKey, Model.GameID)},
                {"rollback_callback", string.Format(@"{0}/?token={1}&gameId={2}", rollbackCallback, tokenResponse.TokenKey, Model.GameID)}
            };
        }

        
        JObject jsonObject = JObject.Parse(FromDictionaryToJson(content));
        string bodyContent = jsonObject.ToString(Formatting.Indented);
        string hash256 = sha256_hash(bodyContent);

        string signature = Get_HMAC_SHA512(string.Format("{0}{1}{2}", sessionUrl, nonce, hash256), secret);

        NameValueCollection headers = new NameValueCollection
        {
            {"Content-Type", "application/vnd.api+json"},
            {"X-Bg-Api-Key", key},
            {"X-Bg-Nonce", nonce},
            {"X-Bg-Signature", signature}

        };

        string response = HttpHelper.PostData(apiUri, bodyContent, headers);
        IsMobile = CE.Utils.PlatformHandler.IsMobile;

        if (IsMobile)
        {
            Response.Redirect(GetDataFromResponse<string>(response, "play_url"));
        }
        LaunchUrl = GetDataFromResponse<string>(response, "play_url");
    }

    static string Get_HMAC_SHA512(string value, string key)
    {
        using (var hmac = new HMACSHA512(Encoding.ASCII.GetBytes(key)))
        {
            return ByteToString(hmac.ComputeHash(Encoding.ASCII.GetBytes(value)));
        }
    }

    static string ByteToString(IEnumerable<byte> data)
    {
        return string.Concat(data.Select(b => b.ToString("x2")));
    }

    private static string sha256_hash(String value)
    {
        using (SHA256 hash = SHA256.Create())
        {
            return string.Join("", hash
              .ComputeHash(Encoding.ASCII.GetBytes(value))
              .Select(item => item.ToString("x2")));
        }
    }

    public static string FromDictionaryToJson(Dictionary<string, string> dictionary)
    {
        var kvs = dictionary.Select(kvp => string.Format("\"{0}\": \"{1}\"", kvp.Key, kvp.Value));
        return string.Concat("{\n", string.Join(",\n", kvs), "\n}");
    }
    
    private T GetDataFromResponse<T>(string response, string path)
    {
        if (string.IsNullOrEmpty(response))
        {
            throw new CeException("Invalid response");
        }

        JObject jsonResp = JObject.Parse(response);
        JToken value;
        if (jsonResp.TryGetValue(path, out value))
        {
            return value.Value<T>();
        }

        throw new CeException("Invalid response: " + response);

    }

</script>

<html xmlns="http://www.w3.org/1999/xhtml" lang="<%= Language %>">
<head>
     <title><%= Model.GameName.SafeHtmlEncode()%></title>
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" />
    <meta name="keywords" content="<%= Model.Tags.SafeHtmlEncode() %>" />
    <meta name="description" content="<%= Model.Description.SafeHtmlEncode() %>" />
    <meta http-equiv="pragma" content="no-cache" />
    <meta http-equiv="content-language" content="<%= Language %>" />
    <meta http-equiv="cache-control" content="no-store, must-revalidate" />
    <meta http-equiv="expires" content="Wed, 26 Feb 1997 08:21:57 GMT" />
    <style type="text/css">
        html, body {
            width: 100%;
            height: 100%;
            padding: 0;
            margin: 0;
            background: #E9E9E9;
            overflow: hidden;
        }

        #ifmGame {
            width: 100%;
            height: 100%;
            border: 0;
        }
    </style>
    <script type="text/javascript" src="/js/jquery-1.7.2.min.js" ></script>
    <script type="text/javascript" src="/js/swfobject.js"></script>
</head>
<body>
     <iframe id="ifmGame" allowtransparency="true" scrolling="no" src="<%= LaunchUrl.SafeHtmlEncode() %>"></iframe>   

    <% Html.RenderPartial("GoogleAnalytics", Domain, new ViewDataDictionary()
           {
               { "Language", Language},
               { "IsLoggedIn", ViewData["UserSession"] != null },
           }
           ); %>
    <%=InjectScriptCode(BoomingGames.CELaunchInjectScriptUrl) %>
</body>
</html>