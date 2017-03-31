<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="Newtonsoft.Json.Linq" %>
<%@ Import Namespace="System.Security.Cryptography" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>
<%@ Import Namespace="GmGamingAPI" %>
<script language="C#" type="text/C#" runat="server">
         
    public override string GetLanguage(string lang)
    {
        if (string.IsNullOrEmpty(lang))
            return "en";

        switch (lang.ToLowerInvariant())
        {
            case "ru":
                lang = lang.ToLowerInvariant();
                break;
            default:
                lang = "en";
                break;
        }
        return lang;
    }
  
    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        
        string salt = Domain.GetCfg(Igrosoft.Salt);
        string merchantId = Domain.GetCfg(Igrosoft.MerchantId);
        Uri apiUri = new Uri(Domain.GetCfg(Igrosoft.VendorAPIUrl));
        
        string utcDateTime = DateTime.UtcNow.ToString("yyyyMMddTHHmmss");
        string transactionId = Guid.NewGuid().ToString();

        string signature = GetHash(string.Format("{0}{1}{2}{3}", merchantId, transactionId, utcDateTime, salt));
        
        Dictionary<string, string> headers = new Dictionary<string, string>
        {
            {"X-Casino-Merchant-Id", merchantId},
            {"X-Casino-Transaction-Id", transactionId},
            {"X-Casino-Timestamp", utcDateTime},
            {"X-Casino-Signature", signature},
            {"Accept", "application/json"}
        };

        Dictionary<string, string> content = new Dictionary<string, string>
        {
            {"game", Model.GameID}
        };

        if (FunMode)
        {
            content.Add("demo", "1000");
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
                string responseJson = new JavaScriptSerializer().Serialize(tokenResponse);
                throw new ApplicationException(String.Format("UserCasinoCurrency was expected but not found in GIC response : {0}", responseJson));
            }
            string makeTransaction = string.Format(@"{0}/?token={1}&gameId={2}", Domain.GetCfg(Igrosoft.MakeTransaction), tokenResponse.TokenKey, Model.GameID);
            content.Add("makeTransaction", makeTransaction);
            content.Add("currency", currency);
        }

        string response = HttpHelper.PostFormUrlEncodedContent(apiUri, "session_create", content, headers);

        LaunchUrl = string.Format("{0}?sign={1}&language={2}", 
            GetDataFromResponse<string>(response, "launch"), 
            GetHash(string.Format("{0}{1}", GetDataFromResponse<string>(response, "token"), salt)), 
            Language);
    }

    private static string GetHash(string stringToSign)
    {
        MD5CryptoServiceProvider x = new MD5CryptoServiceProvider();
        byte[] bs = Encoding.UTF8.GetBytes(stringToSign);
        bs = x.ComputeHash(bs);
        StringBuilder s = new StringBuilder();
        foreach (byte b in bs)
        {
            s.Append(b.ToString("x2").ToLower());
        }

        return s.ToString();
    }

    private T GetDataFromResponse<T>(string response, string path)
    {
        if (string.IsNullOrEmpty(response))
        {
            throw new CeException("Invalid Igrosoft GamePresentationURL response");
        }

        JObject jsonResp = JObject.Parse(response);
        JToken value;
        if (jsonResp.TryGetValue(path, out value))
        {
            return value.Value<T>();
        }

        throw new CeException("Invalid Igrosoft GamePresentationURL response: " + response);

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
    <%=InjectScriptCode(Igrosoft.CELaunchInjectScriptUrl) %>
</body>
</html>