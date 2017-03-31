<%@ Page Language="C#" Debug="true" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script language="C#" type="text/C#" runat="server">
private string GameSrc { get; set; }
private string FlashVars { get; set; }
private string BaseUrl { get; set; }
private string HelpUrl { get; set; }
private int InitialWidth { get; set; }
private int InitialHeight { get; set; }

/// <summary>
/// http://www.w3.org/WAI/ER/IG/ert/iso639.htm
/// 
/// </summary>
/// <param name="lang"></param>
/// <returns></returns>
public override string GetLanguage(string lang)
{
    //ConvertToISO639
    if (string.IsNullOrWhiteSpace(lang))
        return "en";

    switch (lang.Truncate(2).ToLowerInvariant())
    {
        case "he": return "iw";
        case "ka": return "en";
        case "ko": return "en";
        case "ja": return "en";
        case "bg": return "en";
        case "zh": return "en";
        default: return lang.Truncate(2).ToLowerInvariant();
    }
}
public Dictionary<string, string> GetNetEntGameParameters(long domainID, string gameID, string language = null)
{
    using (GamMatrixClient client = new GamMatrixClient())
    {
        NetEntAPIRequest request = new NetEntAPIRequest()
        {
            GetGameInfo = true,
            GetGameInfoGameID = gameID,
            GetGameInfoLanguage = this.Language,
        };
        request = client.SingleRequest<NetEntAPIRequest>(domainID, request);
        LogGmClientRequest(request.SESSION_ID, request.GetGameInfoResponse.Count.ToString(), "GameInfo records");

        Dictionary<string, string> ret = new Dictionary<string, string>();

        for (int i = 0; i < request.GetGameInfoResponse.Count - 1; i += 2)
        {
            ret[request.GetGameInfoResponse[i]] = request.GetGameInfoResponse[i + 1];
        }
        return ret;
    }
}

public string CreateNetEntSessionID()
{
    if (UseGmGaming)
    {
        
        return GetToken().TokenKey;
    }
    else
        
        using (GamMatrixClient client = new GamMatrixClient())
        {
            NetEntAPIRequest request = new NetEntAPIRequest()
            {
                LoginUserDetailedCache = true,
                UserID = UserSession.UserID
            };
            request = client.SingleRequest<NetEntAPIRequest>(UserSession.DomainID, request);
            LogGmClientRequest(request.SESSION_ID, request.LoginUserDetailedCacheResponse, "sID");
            return request.LoginUserDetailedCacheResponse;
        }
}

protected override void OnInit(EventArgs e)
{
    base.OnInit(e);

    bool disableAudio = string.Equals(Request.QueryString["disableAudio"], "true", StringComparison.OrdinalIgnoreCase);
    
    HelpUrl = Url.RouteUrl("Loader", new { Action = "Help", domainID = Domain.DomainID, id = this.Model.Slug, language = Language });
    
    StringBuilder html = new StringBuilder();
    Dictionary<string, string> parameters
        = GetNetEntGameParameters(Domain.DomainID, this.Model.GameID, Language);

    string src = parameters["src"];
    if (!string.IsNullOrWhiteSpace(Domain.GetCfg(NetEnt.CasinoBrand)))
    {
        Match m = Regex.Match(src, @"^(\/flash\/)(?<sub>.+)$", RegexOptions.IgnoreCase| RegexOptions.CultureInvariant);
        if (m.Success)
        {
            src = string.Format("/flash/{0}/{1}", Domain.GetCfg(NetEnt.CasinoBrand), m.Groups["sub"].Value);
        }
    }
    src = string.Format("{0}{1}", Domain.GetCfg(NetEnt.CasinoGameHostBaseURL), src);

    string flashVars = string.Format("{0}&server={1}&disableAudio={2}&allowFullScreen=true"
        , parameters["vars"]
        , HttpUtility.UrlEncode(Domain.GetCfg(NetEnt.CasinoGameApiBaseURL))
        , disableAudio.ToString().ToLowerInvariant()
        );
    if (UserSession != null && !FunMode)
    {
        string sessid = CreateNetEntSessionID();
        flashVars = string.Format("{0}&sessid={1}", flashVars, HttpUtility.UrlEncode(sessid));
    }
    
    if (parameters.Keys.Contains("client") && parameters["client"].Equals("flash", StringComparison.InvariantCultureIgnoreCase))
    {
        int width, height;
        if (int.TryParse(parameters["width"], out width))
            InitialWidth = width;
        if (int.TryParse(parameters["height"], out height))
            InitialHeight = height;
    }
    else
    { 
        if(this.Model.Width > 0)
            InitialWidth = this.Model.Width;
         if(this.Model.Height > 0)
             InitialHeight = this.Model.Height;
    }
    BaseUrl = parameters["base"];
    FlashVars = flashVars;
    GameSrc = src;
}
</script>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
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
    html, body { width:100%; height:100%; padding:0px; margin:0px; background:black; overflow:hidden; }
    #game-wrapper { margin:0 auto; }
    </style>
    <script language="javascript" type="text/javascript" src="/js/jquery-1.7.2.min.js" ></script>
    <script language="javascript" type="text/javascript" src="/js/swfobject.js"></script>
    <%= InjectScriptCode(NetEnt.CELaunchInjectScriptUrl) %>
</head>
<body>

    <div id="game-wrapper" style="width:100%; height:100%;" valign="middle">
        <object classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" width="100%" height="100%" id="ctlFlash">
            <param name="movie" value="<%= this.GameSrc.SafeHtmlEncode() %>" />
            <param name="quality" value="high" />
            <param name="bgcolor" value="#000000" />
            <param name="scale" value="exactfit" />
            <param name="flashVars" value="<%= this.FlashVars.SafeHtmlEncode() %>" />
            <param name="base" value="<%= this.BaseUrl.SafeHtmlEncode() %>" />
            <param name="allowScriptAccess" value="always" />
            <param name="allowNetworking" value="all" />
            <param name="allowFullScreen" value="true" />
            <param name="wmode" value="direct" />
                    
            <embed src="<%= this.GameSrc.SafeHtmlEncode() %>" 
                    quality="high" 
                    bgcolor="#000000" 
                    scale = "exactfit"
                    width="100%" 
                    height="100%" 
                    flashVars="<%= this.FlashVars.SafeHtmlEncode() %>"
                    id="ctlFlash"
                    base="<%= this.BaseUrl.SafeHtmlEncode() %>"
                    type="application/x-shockwave-flash" 
                    allowScriptAccess="always"
                    allowNetworking="all"
                    allowFullScreen="true"
                    wmode = "direct"
                    pluginspage="https://get.adobe.com/cn/flashplayer/">
            </embed>
        </object>
    </div>



    <script type="text/javascript">
        function rules(){
            var url = "<%=HelpUrl.SafeJavascriptStringEncode() %>";
            if(url != "")
            {
                var features="directories=no,location=no,menubar=no,resizable=no,scrollbars=yes,status=no,toolbar=no,width=440,height=420";
                window.open(url, "netent_casino_rules", features);
            }
        }

        function resizeGame() {
            var initialWidth = <%= InitialWidth %> * 1.00;
            var initialHeight = <%= InitialHeight %> * 1.00;

            var height = $(document.body).height() * 1.00;
            var width = $(document.body).width() * 1.00;

            var newWidth = width;
            var newHeight = newWidth * initialHeight / initialWidth;
            if( newHeight > height ){
                newHeight = height;
                newWidth = newHeight * initialWidth / initialHeight;
            } 
            $('#game-wrapper').width(newWidth).height(newHeight);
        }

        function loadGame(){
            $('#game-wrapper').empty();
            $('<div id="flash_place_holder"></div>').appendTo($('#game-wrapper'));

            var fn = null;
            if (swfobject.hasFlashPlayerVersion("11")) {
                fn = function() {
                    var now = new Date().getTime();
                    var flashvars = {};
                    var params = {
                        menu: "false",
                        flashvars: "<%= this.FlashVars.SafeJavascriptStringEncode() %>",
                        base: "<%= this.BaseUrl.SafeJavascriptStringEncode() %>",
	                    allowScriptAccess: 'always',
	                    allowNetworking: 'all',
	                    wmode: 'direct',
	                    scale: 'exactfit',
	                    bgcolor: '#000000',
	                    quality: 'high'
	                };
                    var attributes = {
                        id: "ctlFlash",
                        name: "ctlFlash"
                    };

                    swfobject.embedSWF("<%= this.GameSrc.SafeJavascriptStringEncode() %>", "flash_place_holder", "100%", "100%", "11", null, false, params, attributes);
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
           
            resizeGame();
            $(window).bind( 'resize', resizeGame);
        }

        function gameEventHandler() {       
            <% if (!FunMode) 
               {%>
            try{
                if(arguments[0][0]=='balanceChanged' && arguments[0][1]=='success')
                {
                    queryBalanceChange();
                    console.log('balanceChanged, called queryBalanceChange');
                }
            }catch(ex){}
            <% }%>
        }

            <% if (!FunMode) 
               {%>
        function queryBalanceChange() {
            return;
            var url = '/HttpHandlers/query_balance_change.ashx?domainID=<%=this.Domain.DomainID%>&_sid64=<%=HttpUtility.UrlEncode(this.ViewData["_sid64"].ToString())%>&_t=' + (new Date()).getTime();
            $.ajax({
                type: "POST",
                async: false,
                url: url,
                cache: false,
                success: function (data) {
                    if (!data.success)
                        console.log(data.error);

                    if (data.reloadBalance)
                        reloadBalance();
                }
            });
        };

        function reloadBalance() {
            try {
                document.getElementById('ctlFlash').reloadbalance();
            }
            catch (err) {}
        };

        if (window.addEventListener) {
            // For standards-compliant web browsers
            window.addEventListener("message", reloadBalance, false);
        }
        else {
            window.attachEvent("onmessage", reloadBalance);
        }
        <% }%>

        $(function () {
            if( typeof(__customizedLoadGame) === 'function' )
                __customizedLoadGame();
            else
                loadGame();
        });
    </script>
    
    <% Html.RenderPartial("GoogleAnalytics", this.Domain, new ViewDataDictionary()
           {
               { "Language", this.Language},
               { "IsLoggedIn", this.ViewData["UserSession"] != null },
           }
           ); %>
</body>
</html>