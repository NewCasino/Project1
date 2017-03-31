<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Models" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script language="C#" type="text/C#" runat="server">
    private string GetNanoXProSwfUrl()
    {
        if (this.Model.GameID.StartsWith("Nano", StringComparison.InvariantCultureIgnoreCase))
            return Domain.GetCfg(Microgaming.MiniGameXProSwfURL);

        return Domain.GetCfg(Microgaming.NanoGameXProSwfURL);
    }
    private MicrogamingNanoGameSessionInfo MicrogamingNanoGameSessionInfo
    {
        get { return this.ViewData["MicrogamingNanoGameSessionInfo"] as MicrogamingNanoGameSessionInfo; }
    }
    private string GetLaunchToken()
    {
        if (UseGmGaming)
        {
            return GetToken().TokenKey;
        }
        else
            using (GamMatrixClient client = new GamMatrixClient())
            {
                VanguardGetSessionRequest request = new VanguardGetSessionRequest()
                {
                    UserID = UserSession.UserID,
                    //VendorID = VendorID.CasinoWallet,
                    GameCode = this.Model.GameCode,
                };
                request = client.SingleRequest<VanguardGetSessionRequest>(UserSession.DomainID, request);
                LogGmClientRequest(request.SESSION_ID, request.Token);
                return request.Token;
            }
    }
    
    private string GetGameParametersScript()
    {
        StringBuilder script = new StringBuilder();
        
        // for real play mode, create a new token
        string newToken = null;
        if (UserSession != null)
        {
            newToken = GetLaunchToken();
            script.AppendFormat("var g_newToken = '{0}';\n", newToken.SafeJavascriptStringEncode());
        }

        script.Append("var g_GameParameters = {");

        if (UserSession == null)
        {
            script.Append("sEXT1:'demo',");
            script.Append("sEXT2:'demo',");
            script.AppendFormat("CasinoID:'{0}',", Domain.GetCfg(Microgaming.MiniGameFunModeCasinoID).SafeJavascriptStringEncode());
        }
        else
        {
            script.AppendFormat("CasinoID:'{0}',", Domain.GetCountrySpecificCfg(Microgaming.MiniGameRealMoneyModeCasinoID, UserSession.UserCountryCode, UserSession.IpCountryCode).SafeJavascriptStringEncode());
        }
        script.AppendFormat("xmanURL:'{0}',", Domain.GetCfg(Microgaming.MiniGameXManURL).SafeJavascriptStringEncode());
        script.AppendFormat("gameID:'{0}',", this.Model.GameID.SafeJavascriptStringEncode());

        script.Append("platformID:'5',");

        // for real play, 
        if (UserSession != null)
        {
            // there is another cached session
            if (this.MicrogamingNanoGameSessionInfo != null)
            {
                script.AppendFormat("lcid:'{0}',", this.MicrogamingNanoGameSessionInfo.LocalConnectionID.SafeJavascriptStringEncode());
                script.AppendFormat("userType:'',", this.MicrogamingNanoGameSessionInfo.UserType.SafeJavascriptStringEncode());
                script.AppendFormat("sessionId:'',", this.MicrogamingNanoGameSessionInfo.SessionId.SafeJavascriptStringEncode());
                script.AppendFormat("token:'{0}',", this.MicrogamingNanoGameSessionInfo.Token.SafeJavascriptStringEncode());
            }
            else
            {
                script.AppendFormat("token:'{0}',", newToken.SafeJavascriptStringEncode());
            }
        }

        script.Append("clientLanguage:'en',");
        script.Append("casinoUL:'en'"); // Only supports English for now
        script.Append("};");

        return script.ToString();
    }
</script>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title></title>
    <meta http-equiv="pragma" content="no-cache" />
    <meta http-equiv="cache-control" content="no-store, must-revalidate" />
    <meta http-equiv="expires" content="Wed, 26 Feb 1997 08:21:57 GMT" />
    <meta http-equiv="X-UA-Compatible" content="requiresActiveX=true" /> 
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" />
    <script language="javascript" type="text/javascript" src="/js/jquery-1.7.2.min.js"></script>
    <script language="javascript" type="text/javascript" src="/js/swfobject.js"></script>
</head>
<body>
    
    <div id="xpro-wrapper">
    </div>

    <script language="javascript" type="text/javascript">

        function isFunMode() { return <%= (this.ViewData["UserSession"] == null).ToString().ToLowerInvariant() %>; }

        <%= GetGameParametersScript() %>

         // <%-- if failed in real mode, and token is not the new one, then try the new one --%>
        parent.loadNewToken = function(){
            if( !isFunMode() ){
                if( g_GameParameters.token != g_newToken )
                {
                    g_GameParameters.token = g_newToken;
                    g_GameParameters.sessionId = null;
                    g_GameParameters.lcid = null;
                    g_GameParameters.userType = null;
                    g_GameParameters.balance = null;
                    parent.setGameParameters(g_GameParameters);
                    loadXProSwf();
                }
            }
        }

        function onSWFcallback(command, args) {
            var movref = document.getElementById("xproFlash");
            movref.focus();
            switch (command) {
                case "MINIRUBY_START_GETDETAILS":
                    {
                        movref.onJScallback("SETVARIABLE", "ALLVARIABLES", g_GameParameters);
                        break;
                    }

                case "XPROX_LCID":
                    {
                        g_GameParameters.lcid = args[0][1];
                        parent.setGameParameters(g_GameParameters);
                        break;
                    }
                case "SESSION_EXPIRED":
                    {
                        // <%-- reload the game if this is fun mode and session expired --%>
                        if( isFunMode() ){
                            g_GameParameters.sessionId = null;
                            g_GameParameters.lcid = null;
                            g_GameParameters.userType = null;
                            g_GameParameters.balance = null;
                            parent.setGameParameters(g_GameParameters);
                            loadXProSwf();
                        }else{
                            parent.loadNewToken();
                        }
                        break;
                    }
                case "HANDLE_ERROR":
			        { 
                        alert("Unknown error from Microgaming NanoXpro.swf.");
				        break;
			        }
                case "LOGIN_COMPLETE":
                    {
                        <%-- 
                     /* args[0][1] holds the success value 
                        args[1][1] holds the balance value 
                        args[2][1] holds the sessionid value 
                        args[3][1] holds the usertype value */
                        --%>
                        if (args[0][1] == true) {
                            g_GameParameters.balance = args[1][1];
                            g_GameParameters.sessionId = args[2][1];
                            g_GameParameters.userType = args[3][1];
                            parent.setGameParameters(g_GameParameters);
                            parent.loadGame();  

                            // <%-- Cache the session if real mode --%>
                            if( !isFunMode() ){
                                jQuery.getJSON( '<%= (this.ViewData["HandlerUrl"] as string).SafeJavascriptStringEncode() %>'
                                , {
                                    balance : g_GameParameters.balance,
                                    userType : g_GameParameters.userType,
                                    lcid : g_GameParameters.lcid,
                                    sessionId : g_GameParameters.sessionId,
                                    token: g_GameParameters.token
                                });
                            }
                        }
                        else {
                            // <%-- if failed in fun mode, try to reload --%>
                            if( isFunMode() ){
                                g_GameParameters.sessionId = null;
                                g_GameParameters.lcid = null;
                                g_GameParameters.userType = null;
                                g_GameParameters.balance = null;
                                parent.setGameParameters(g_GameParameters);
                                loadXProSwf();
                            }
                            else{
                                // <%-- if failed in real mode, and token is not the new one, then try the new one --%>
                                parent.loadNewToken();
                            }
                        }
                        break;
                    }
                default:
                    {
                        break;
                    } 
            }
        }

        function loadXProSwf(){
            var flashvars = {};
            var params = {};
            params.bgcolor = '#000000';
            params.scale = 'showall';
            params.wmode = 'window';
            params.align = 'middle';
            params.allowFullScreen = 'true';
            params.allowScriptAccess = 'always';
            params.swliveconnect = 'true';
            var attributes = { id: 'xproFlash', name: 'xproFlash' };

            $('#xpro-wrapper').html( '<div id="flash-place-holder"></div>' );
            var url = '<%= GetNanoXProSwfUrl().SafeJavascriptStringEncode() %>';
            swfobject.embedSWF(url, "flash-place-holder", "0", "0", "10.0.0.0", null, flashvars, params, attributes);
        }
        $(function () {
            if( !isFunMode() && g_GameParameters.token !=  g_newToken ) {
                parent.setGameParameters(g_GameParameters);
                parent.loadGame();
            }
            else{
                loadXProSwf();
            }
        });
    </script>
    <% Html.RenderPartial("GoogleAnalytics", this.Domain); %>
    <%=InjectScriptCode(Microgaming.CELaunchInjectScriptUrl) %>
</body>
</html>