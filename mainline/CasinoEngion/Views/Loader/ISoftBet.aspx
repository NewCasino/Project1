<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Extensions" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmGamingAPI" %>

<script language="C#" type="text/C#" runat="server">
    private string RuleUrl { get; set; }
    private string FlashSrc { get; set; }
    private string FlashVars { get; set; }
    private string FlashParams { get; set; }

    private bool AlwaysLoadSettingsFormTargetServer { get; set; }
    
    private string TargetServer { get; set; }
    
    public override string GetLanguage(string lang)
    {
        if (string.IsNullOrWhiteSpace(lang))
            return "en";
        
        lang = lang.ToLowerInvariant();
        switch (lang)
        { 
            case "zh-cn":
                lang = "zh";
                break;
            case "vs":
                lang = "en";
                break;
        }
        
        if (ISoftBetIntegration.GameMgt.SupportedLanguages.Contains(lang))
            return lang;
        
        return "en";
    }

    private int GetLanguageCode(string lang)
    {
        switch (lang)
        { 
            case "en":
                return 0;
            case "fr":
                return 1;
            case "es":
                return 2;
            case "it":
                return 3;
            case "de":
                return 5;
            case "nl":
                return 8;
            default:
                return 0;
        }
    }

    private string GetRuleLanguage(string lang)
    {
        switch (lang)
        { 
            case "en":
            case "fr":
            case "es":
            case "de":
            case "nl":
            case "ru":
            case "ro":
            case "jp":
            case "it":
                return lang;
            default:
                return "en";
        }
    }
    
    private string GetFlashParams(ISoftBetIntegration.GameModel iGame)
    {
        StringBuilder sb = new StringBuilder();
        sb.Append("{");
        sb.Append("align: 'middle',");
        sb.Append("allowScriptAccess: 'always',");
        sb.Append("allowFullScreen: 'true',");
        sb.Append("quality: 'high',");
        sb.Append("bgcolor: '#000000',");
        sb.AppendFormat("wmode: '{0}'", iGame.WMode);
        sb.Append("}");
        return sb.ToString();
    }

    private string GetFlashVars(ISoftBetIntegration.GameModel iGame, string iSessionID, string currency)
    {
        StringBuilder sb = new StringBuilder();

        sb.Append("{");
        sb.AppendFormat("loginc: '{0},{1}',", HttpUtility.UrlEncode(Domain.GetCfg(ISoftBet.LicenseID)), FunMode ? "fun" : HttpUtility.UrlEncode(UserSession.UserID.ToString()));
        sb.AppendFormat("passc: '{0}',", FunMode ? "fun" : HttpUtility.UrlEncode(string.Format("{0},{1},{2},{3},real", iSessionID, UserSession.Username, currency, UserSession.UserCountryCode)));
        sb.AppendFormat("cur: '{0}',", HttpUtility.UrlEncode(currency));
        sb.AppendFormat("forfun: 1,");
        sb.AppendFormat("language: {0},", GetLanguageCode(this.Language));
        sb.AppendFormat("casino: '{0}',", HttpUtility.UrlEncode(iGame.SkinID));
        

        sb.AppendFormat("tokenuse: {0},", 0);
        sb.AppendFormat("table: {0},", 0);
        sb.Append("realc: 0");
        
        sb.Append("}");
        
        return sb.ToString();
    }

    private string GetGameUrl(ISoftBetIntegration.GameModel iGame)
    {
        return string.Format("{0}dev/custom_assets/{1}Game.swf"
            , TargetServer
            , iGame.Identifier
            );
    }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        string ipCountryCode = null;
        ISoftBetIntegration.GameModel iGame = null;
        
        if (UserSession == null)
        {
            FunMode = true;

            ipCountryCode = IPLocation.GetByIP(Request.GetRealUserAddress()).CountryCode;

            AlwaysLoadSettingsFormTargetServer = Domain.GetCountrySpecificCfg(ISoftBet.AlwaysLoadSettingsFormTargetServer, ipCountryCode).SafeParseToBool(false);
            
            TargetServer = Domain.GetCountrySpecificCfg(ISoftBet.TargetServer, ipCountryCode);
            iGame = ISoftBetIntegration.GameManager.Get(Domain, this.Model.GameID, false, this.Language, ipCountryCode);
        }
        else
        {
            AlwaysLoadSettingsFormTargetServer = Domain.GetCountrySpecificCfg(ISoftBet.AlwaysLoadSettingsFormTargetServer, UserSession.UserCountryCode, UserSession.IpCountryCode).SafeParseToBool(false);
            
            TargetServer = Domain.GetCountrySpecificCfg(ISoftBet.TargetServer, UserSession.UserCountryCode, UserSession.IpCountryCode);
            iGame = ISoftBetIntegration.GameManager.Get(Domain, this.Model.GameID, false, this.Language, UserSession.UserCountryCode, UserSession.IpCountryCode);
        }

        if(iGame == null)
            throw new CeException("Error, failed to find the Casino Game [{0}].", this.Model.GameID);

        if (!TargetServer.EndsWith("/", StringComparison.InvariantCultureIgnoreCase))
            TargetServer += "/";

        if (FunMode)
        {
            if (!iGame.FunModel)
                throw new CeException("Error, The Game [{0}] can't be played in fun mode.", this.Model.GameID);
        }
        else
        {
            if (!iGame.RealModel)
                throw new CeException("Error, The Game [{0}] can't be played in real mode.", this.Model.GameID);
        }

        if (!FunMode && iGame.UserIDs != null && iGame.UserIDs.Length > 0)
        { 
            if(!iGame.UserIDs.Contains(UserSession.UserID.ToString()))
                throw new CeException("Error, You are not allowed to play the Game [{0}].", this.Model.GameID);
        }

        string iSessionID = null;
        string currency = string.Empty;
        if (!FunMode && UserSession != null)
        {
            if (UseGmGaming)
            {
                TokenResponse response = GetToken();

                if (response.AdditionalParameters.Exists(a => a.Name == "UserCasinoCurrency"))
                    currency = response.AdditionalParameters.First(a => a.Name == "UserCasinoCurrency").Value;

                iSessionID = response.TokenKey;
            }
            else
            {
                throw new CeException("GmGaming only valid to get token");
            }
        }
        
        this.FlashParams = GetFlashParams(iGame);

        this.FlashSrc = GetGameUrl(iGame);

        this.FlashVars = GetFlashVars(iGame, iSessionID, currency);

        this.RuleUrl = string.Format("{0}/rules/rules_{1}.html",
            TargetServer,
            GetRuleLanguage(this.Language.ToLowerInvariant())
            );
    }
</script>
<!DOCTYPE html>

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
    html, body { width:100%; height:100%; padding:0px; margin:0px; background:#E9E9E9; overflow:hidden; }
    #ifmGame { width:100%; height:100%; border:0px; }
    </style>
    <script type="text/javascript" src="/js/jquery-1.7.2.min.js" ></script>
    <script type="text/javascript" src="/js/swfobject.js"></script>
</head>
<body>
    <div id="game-wrapper" style="width:100%; height:100%;" valign="middle">
    </div>

    <script type="text/javascript">
        $(document).ready(function () {
            //netent
            var fn = null;
            $('#game-wrapper').empty();
            $('<div id="flash_place_holder"></div>').appendTo($('#game-wrapper'));

            if (swfobject.hasFlashPlayerVersion("11")) {
                fn = function() {
                    var now = new Date().getTime();
                    var flashvars = <%= this.FlashVars %>;
                    var params = <%= this.FlashParams %>;
                    var attributes = {
                        id: "ctlFlash",
                        name: "ctlFlash"
                    };

                    swfobject.embedSWF("<%= this.FlashSrc.SafeJavascriptStringEncode() %>", "flash_place_holder", "100%", "100%", "11", null, flashvars, params, attributes);
                };
            }
            else {
                fn = function() {
                    var att = { data:"/js/expressInstall.swf", width:"600", height:"240" };
                    var par = { menu:false };
                    var id = "flash_place_holder";
                    swfobject.showExpressInstall(att, par, id, null);
                }
            }

            fn();
        });

        function game_action(_command)
        {
            switch(_command)
            {
                case 'rules':
                    window.open('<%=this.RuleUrl.SafeJavascriptStringEncode()%>');
                    break;
                default:
                    //alert('Command ' + _command + ' is unrecognised.');
                    break;
            }
        }
        
    </script>

    <% Html.RenderPartial("GoogleAnalytics", this.Domain, new ViewDataDictionary()
           {
               { "Language", this.Language},
               { "IsLoggedIn", this.ViewData["UserSession"] != null },
           }
           ); %>
    <%=InjectScriptCode(ISoftBet.CELaunchInjectScriptUrl) %>
</body>
</html>