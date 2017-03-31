<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>

<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GmGamingAPI" %>
<%@ Import Namespace="Newtonsoft.Json.Linq" %>

<script language="C#" type="text/C#" runat="server">

    protected string gameSessionUrl;
    protected string gameClientJsLibUrl;

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        bool mobileDevice = CE.Utils.PlatformHandler.IsMobile;
        
        List<NameValue> parameters = new List<NameValue>();

        parameters.Add(new NameValue {Name = "gameId", Value = this.Model.GameID});

        if (!FunMode)
        {
            TokenResponse tokenResponse = GetToken(parameters);
            if (tokenResponse != null && tokenResponse.AdditionalParameters != null)
            {
                if (tokenResponse.AdditionalParameters.Exists(a => a.Name == "gameSessionUrl"))
                {
                    gameSessionUrl = tokenResponse.AdditionalParameters.First(a => a.Name == "gameSessionUrl").Value;
                }
                if (tokenResponse.AdditionalParameters.Exists(a => a.Name == "gameClientJsLibUrl"))
                {
                    gameClientJsLibUrl = tokenResponse.AdditionalParameters.First(a => a.Name == "gameClientJsLibUrl").Value;
                }
            }
            else
            {
                string responseJson = new JavaScriptSerializer().Serialize(tokenResponse);
                throw new ApplicationException(string.Format("AdditionalParameters was expected but not found in GIC response : {0}", responseJson));
            }
        }
        else
        {
          string platform = mobileDevice ? "mobile" : "desktop";

          GetLaunchForDemo(Domain.GetCfg(StakeLogic.DemoBaseUrl), this.Model.GameID, platform, Domain.GetCfg(StakeLogic.UserName), Domain.GetCfg(StakeLogic.Password));
        }
    }

    private void GetLaunchForDemo(string baseUrl, string gameId, string platform, string userName, string password)
    {
        string uri = string.Format("{0}?gameId={1}&gamePlatform={2}", baseUrl, gameId, platform);
        
        Uri apiUri = new Uri(uri);

        string encodedCredentials = Convert.ToBase64String(ASCIIEncoding.ASCII.GetBytes(userName + ":" + password));

        NameValueCollection headers = new NameValueCollection {{"Authorization", string.Format("Basic {0}", encodedCredentials)}};

        string response = HttpHelper.GetData(apiUri, headers);   
        LoadDataForLaunch(response); 
    }

    private void LoadDataForLaunch(string response)
    {
        if (string.IsNullOrWhiteSpace(response))
        {
            throw new CeException("Invalid StakeLogic Url");
        }
        else
        {
            JToken jsonContent = JObject.Parse(response);
            gameSessionUrl = jsonContent.SelectToken("gameServerUrl").ToString();
            gameClientJsLibUrl = jsonContent.SelectToken("gameJsLibUrl").ToString();
        }   
    }

</script>
<!DOCTYPE html>
<html lang="<%= this.Language %>">
<head>
   <meta charset="utf-8">
   <title><%= this.Model.GameName %>></title>
</head>
<body>
<!-- 1. Game container element -->
<ngc-game ngc-server-url="<%=gameSessionUrl%>">"></ngc-game>
<!-- 2. Game client javascript responsible for game running -->
<script charset="utf-8" type="text/javascript" src="<%= gameClientJsLibUrl%>"></script>
<!-- 3. Casino platform specific javascript controlling game through Game API -->
<script charset="utf-8" type="text/javascript">
   // Define game event listenter
   function gameEventListener(type, data) {
      console.log("Game event: (" + type +"): " + JSON.stringify(data));
      if (type == ngc.api.GameEventType.HOME) {
         console.log("Event HOME: " + data);
         window.history.back();
      }
      if (type == ngc.api.GameEventType.REGISTER) {
         console.log("Event REGISTER: " + data);
      }
      if (type == ngc.api.GameEventType.CASHIER) {
         console.log("Event CASHIER: " + data);
      }
      if (type == ngc.api.GameEventType.ERROR) {
         console.log("Event ERROR: " + data);
      }
   }
   // Init all game containers, bind game event litener
   ngc.gameElementsInit(gameEventListener);
</script>
</body>
</html>
