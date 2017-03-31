<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="CE.DomainConfig" %>
<script language="C#" runat="server" type="text/C#">
    private string GetNanoXproUrl()
    {
        if (UserSession != null && !FunMode)
            return this.Url.RouteUrl("Loader", new { @action = "MicrogamingNanoXpro", domainID = Domain.DomainID, @id = this.Model.ID, _sid = UserSession.Guid, _t = Guid.NewGuid().ToString() });

        return this.Url.RouteUrl("Loader", new { @action = "MicrogamingNanoXpro", domainID = Domain.DomainID, @id = this.Model.ID, _t = Guid.NewGuid().ToString() });
    }

    private string GetNanoSysSwfUrl()
    {
        if (this.Model.GameID.StartsWith("Nano", StringComparison.InvariantCultureIgnoreCase))
            return Domain.GetCfg(Microgaming.NanoGameNanoSysSwfURL);

        //if (this.Model.GameID.StartsWith("Mini", StringComparison.InvariantCultureIgnoreCase))
        return Domain.GetCfg(Microgaming.MiniGameMiniSysSwfURL);
    }
</script>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" >
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
        html, body
        {
            width: 100%;
            height: 100%;
            padding: 0px;
            margin: 0px;
            background: transparent;
            overflow: hidden;
        }
        #game-wrapper
        {
            margin: 0 auto;
        }
    </style>
    <script language="javascript" type="text/javascript" src="/js/jquery-1.7.2.min.js"></script>
    <script language="javascript" type="text/javascript" src="/js/swfobject.js"></script>
</head>
<body>
    
    <div id="game-wrapper" style="width: 100%; height: 100%;" valign="middle">
    </div>
    <iframe id="ifmNanoXpro" width="1" height="1" frameborder="0" scrolling="no"></iframe>
    
<script type="text/javascript">
var g_GameParameters = {};

self.setGameParameters = function(oParams) { g_GameParameters = oParams; }
// <%-- load NanoSys --%>
self.loadGame = function(){
    var flashvars = {};
    var params = {};
    params.bgcolor = '#000000';
    params.scale = 'showall';
    params.wmode = 'window';
    params.align = 'middle';
    params.allowFullScreen = 'true';
    params.allowScriptAccess = 'always';
    params.swliveconnect = 'true';
    var attributes = { id: 'sysFlash', name: 'sysFlash' };

    var url = '<%= GetNanoSysSwfUrl().SafeJavascriptStringEncode() %>';
    $('#game-wrapper').html('<div id="flash-place-holder"></div>');
    swfobject.embedSWF(url, "flash-place-holder", "100%", "100%", "10.0.0.0", "/js/expressInstall.swf", flashvars, params, attributes);
};

function onSWFcallback(command, args) {
    var movref = document.getElementById("sysFlash");
    movref.focus();
    switch (command) {
        case "MINIRUBY_START_GETDETAILS":
            {
                movref.onJScallback("SETVARIABLE", "ALLVARIABLES", g_GameParameters);
                break;
            }
        case "SESSION_EXPIRED":
            {
                try { self.loadNewToken();  } catch (e) { }
                break;
            }
        case "HANDLE_ERROR":
			{
			    try { self.loadNewToken(); } catch (e) { }
				break;
			}
        default:
            {
                break;
            } 
    }
}

$(function(){
    $('#ifmNanoXpro').attr('src', '<%= GetNanoXproUrl().SafeJavascriptStringEncode() %>');
});
</script>
    <% Html.RenderPartial("GoogleAnalytics", this.Domain, new ViewDataDictionary()
           {
               { "Language", this.Language},
               { "IsLoggedIn", this.ViewData["UserSession"] != null },
           }
           ); %>
    <%=InjectScriptCode(Microgaming.CELaunchInjectScriptUrl) %>
</body>
</html>