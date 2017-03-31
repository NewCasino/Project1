<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>

<%@ Import Namespace="System.Dynamic" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Net" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>
<%@ Import Namespace="CE.db" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GmGamingAPI" %>
<%@ Import Namespace="Newtonsoft.Json" %>
<%@ Import Namespace="Newtonsoft.Json.Linq" %>

<script language="C#" type="text/C#" runat="server">
    private bool isMobile = false;

    public override string GetLanguage(string lang)
    {
        if (string.IsNullOrEmpty(lang))
            return "en";

        switch (lang.ToLowerInvariant())
        {
            case "al":
            case "bp":
            case "bg":
            case "ca":
            case "hr":
            case "cs":
            case "dk":
            case "nl":
            case "ee":
            case "fi":
            case "fr":
            case "de":
            case "el":
            case "he":
            case "hu":
            case "it":
            case "ja":
            case "no":
            case "pl":
            case "pt":
            case "ro":
            case "ru":
            case "sr":
            case "sk":
            case "sl":
            case "es":
            case "sv":
            case "th":
            case "tr":
            case "ko":
                lang = lang.ToLowerInvariant();
                break;

            case "zh-cn":
                lang = "cn";
                break;

            case "zh-tw":
                lang = "b5";
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

        Encoding encoding = Encoding.UTF8;
        string credential = String.Format("{0}:{1}", Domain.GetCfg(LuckyStreak.CEOperatorClientId), Domain.GetCfg(LuckyStreak.CEOperatorClientSecret));
        string credentialHeaderValue = Convert.ToBase64String(encoding.GetBytes(credential));
        string tokenKey = string.Empty;

        HttpWebRequest request = WebRequest.Create(Domain.GetCfg(LuckyStreak.CELuckyStreakTokenURL)) as HttpWebRequest;

        JObject jsonObj;
        if (request != null)
        {
            request.Headers.Add(HttpRequestHeader.Authorization, "Basic " + credentialHeaderValue);
            //request.Host = "integ.api-ids.livepbt.com";
            request.KeepAlive = true;
            request.ContentType = "application/x-www-form-urlencoded";
            request.Method = "POST";
            
            using (var streamWriter = new StreamWriter(request.GetRequestStream()))
            {
                streamWriter.Write("grant_type=operator_authorization&scope=operator offline_access&operator_name=" + Domain.GetCfg(LuckyStreak.CEOperatorName));
                streamWriter.Flush();
            }

            HttpWebResponse responseToken = request.GetResponse() as HttpWebResponse;
            if (responseToken != null)
                using (Stream s = responseToken.GetResponseStream())
                {
                    using (StreamReader sr = new StreamReader(s))
                    {
                        var token = sr.ReadToEnd();
                        jsonObj = JObject.Parse(token);
                        tokenKey = jsonObj["access_token"].Value<string>();
                    }
                }
        }
                
        NameValueCollection headers1 = new NameValueCollection();
        headers1.Add("Authorization", "Bearer " + tokenKey);
        headers1.Add("KeepAlive", true.ToString());
        headers1.Add("Content-Type", "application/json");
        
        dynamic data = new ExpandoObject();
        data.Open = false;
        data.GameTypes = new ArrayList();
        data.Currencies = new ArrayList();
        dynamic body = new ExpandoObject();
        body.Data = data;
        string bodyContent = JsonConvert.SerializeObject(body, Formatting.None);

        string gameListDetail = HttpHelper.PostData(new Uri(Domain.GetCfg(LuckyStreak.CasinoGameListURL)), bodyContent, headers1);
        if (EnableLogging)
        {
            GmLogger.Instance.Trace(String.Format("gameListDetailі: {0}", gameListDetail));
        }
        jsonObj = JObject.Parse(gameListDetail);

        JObject gameInfo = jsonObj["data"]["games"].Values<JObject>().FirstOrDefault(m => m["id"].Value<string>() == this.Model.GameID.Trim());
        if (gameInfo == null)
        {
            if (EnableLogging)
                GmLogger.Instance.Error(String.Format("No specific games was returned by vendor : GameId {0}", this.Model.GameID.Trim()));

            throw new ApplicationException();
        }

        if (string.IsNullOrWhiteSpace(TableID))
            throw new CeException("Table ID is missing.");

        Dictionary<string, ceLiveCasinoTableBaseEx> tables = global::CacheManager.GetLiveCasinoTableDictionary(Domain.DomainID);
        ceLiveCasinoTableBaseEx table;
        if (!tables.TryGetValue(TableID, out table))
            throw new CeException("Invalid table id [{0}].", TableID);
        
        LaunchUrl = gameInfo["launchUrl"].Value<string>();
        isMobile = PlatformHandler.IsMobile;
        
        string limitGroupId = table.ExtraParameter2;
        if ((Domain.GetCfg(LuckyStreak.CEShowLiveLobby).ToLower() == "true" || limitGroupId.ToLower() == "lobby") && !isMobile)
        {
            LaunchUrl = ReplaceGameId(LaunchUrl);
            LaunchUrl = ReplaceGameType(LaunchUrl);
        }
        
        // From now to configure limit use limitId, instead if limit name
        // Apropriate settings should be configured in BackOffice/CE
        // GAI-1769        

        JObject limitGroupInfo = gameInfo["limitGroups"].Values<JObject>().FirstOrDefault(m => m["id"].Value<string>() == limitGroupId);
        if (limitGroupInfo == null || limitGroupInfo["id"].Value<string>() == null)
        {
            limitGroupInfo = gameInfo["limitGroups"].Values<JObject>().FirstOrDefault(m => m["id"].Value<string>() != null);
            if (limitGroupInfo != null) limitGroupId = limitGroupInfo["id"].Value<string>();
        }

        if (UserSession == null || FunMode)
            throw new CeException("LuckyStreak game is only available in real money mode.");

        List<NameValue> addParams = new List<NameValue>()
            {
                new NameValue { Name = "UserLanguage", Value = this.Language }
            };

        TokenResponse response = GetToken(addParams);

        LaunchUrl = LaunchUrl.Replace("{operatorName}", Domain.GetCfg(LuckyStreak.CEOperatorName));
        LaunchUrl = LaunchUrl.Replace("{authCode}", response.TokenKey);
        if (response.AdditionalParameters.Exists(a => a.Name == "PlayerId"))
            LaunchUrl = LaunchUrl.Replace("{playerName}", response.AdditionalParameters.First(a => a.Name == "PlayerId").Value);
        LaunchUrl += "&LimitsGroupId=" + limitGroupId;
               
        if (isMobile)
        {
            Response.Redirect(LaunchUrl);
        }

    }

    private string ReplaceGameType(string launchUrl)
    {
        List<string> launchParts = launchUrl.Split('&').ToList();
        int index = launchParts.FindIndex(x => x.Contains("GameType="));
        if (index != -1)
        launchParts[index] = "GameType=All";
        string value = string.Join("&", launchParts);

        return value;
    }

    private string ReplaceGameId(string launchUrl)
    {
        List<string> launchParts = launchUrl.Split('&').ToList();
        int index = launchParts.FindIndex(x => x.Contains("GameId="));
        if (index != -1)
        launchParts.RemoveAt(index);
        string value = string.Join("&", launchParts);

        return value;        
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
    <meta http-equiv="X-UA-Compatible" content="requiresActiveX=true" />
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
    <iframe id="ifmGame" allowtransparency="true" frameborder="0" scrolling="no" src="<%= this.LaunchUrl.SafeHtmlEncode() %>"></iframe>

    <% Html.RenderPartial("GoogleAnalytics", this.Domain, new ViewDataDictionary()
           {
               { "Language", this.Language},
               { "IsLoggedIn", this.ViewData["UserSession"] != null },
           }
           ); %>
    <%=InjectScriptCode(LuckyStreak.CELaunchInjectScriptUrl) %>
</body>
</html>
