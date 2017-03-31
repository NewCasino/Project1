<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>

<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmGamingAPI" %>

<script language="C#" type="text/C#" runat="server">
    protected int RealityCheckTimeout { get; set; }
    protected bool IsMobile { get; set; }

    public override string GetLanguage(string lang)
    {
        if (lang != null)
        {
            switch (lang.ToUpperInvariant())
            {
                //case "ES": return  "ca_ES";
                //case "EE": return  "et_EE";
                //case "HR": return  "hr_HR";
                //case "LT": return  "lt_LT";
                //case "LV": return  "lv_LV";
                //case "SK": return  "sk_SK";
                //case "SI": return  "sl_SI";
                case "BG": return "bg_BG";
                case "CS": return "cs_CZ";
                case "DA": return "da_DK";
                case "DE": return "de_DE";
                case "EL": return "el_GR";
                case "ES": return "es_ES";
                case "FI": return "fi_FI";
                case "FR": return "fr_FR";
                case "HU": return "hu_HU";
                case "IT": return "it_IT";
                case "NL": return "nl_NL";
                case "PL": return "pl_PL";
                case "PT": return "pt_PT";
                case "RO": return "ro_RO";
                case "RU": return "ru_RU";
                case "SV": return "sv_SE";
                case "TR": return "tr_TR";
                case "NO": return "no_NO";
                default: return "en_GB";
            }
        }
        return "en_GB";
    }

    private string RedirectUrl
    {
        get;
        set;
    }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        IsMobile = CE.Utils.PlatformHandler.IsMobile;

        if (IsMobile)
        {
            StringBuilder url = new StringBuilder();
            url.Append(Domain.GetCfg(PlaynGO.MobileGameBaseURL));
            if (url[url.Length - 1] != '?')
            {
                if (Domain.GetCfg(PlaynGO.MobileGameBaseURL).IndexOf('?') > 0)
                    url.Append('&');
                else
                    url.Append('?');
            }
            
            url.AppendFormat(CultureInfo.InvariantCulture, "gid={0}", HttpUtility.UrlEncode(this.Model.GameID));
            url.AppendFormat(CultureInfo.InvariantCulture, "&lang={0}", HttpUtility.UrlEncode(Language));
            url.AppendFormat(CultureInfo.InvariantCulture, "&pid={0}", HttpUtility.UrlEncode(Domain.GetCfg(PlaynGO.PID)));
            url.AppendFormat(CultureInfo.InvariantCulture, "&lobby={0}", HttpUtility.UrlEncode(Domain.MobileLobbyUrl));

            if (UserSession == null || FunMode)
            {
                url.Append("&practice=1");
            }
            else
            {
                url.Append("&practice=0");
                url.AppendFormat(CultureInfo.InvariantCulture, "&ticket={0}", GetLaunchToken());
                url.Append(GetRelityCheckiFrameUrl());
            }

            this.RedirectUrl = url.ToString();
        }
        else
        {
            this.RedirectUrl = GetLaunchUrl();
        }
    }

    private string GetLaunchUrl()
    {
        StringBuilder url = new StringBuilder();
        url.Append(Domain.GetCfg(PlaynGO.CasinoGameBaseURL));
        url.Append("?div=game-place-holder");
        url.AppendFormat(CultureInfo.InvariantCulture, "&gid={0}", HttpUtility.UrlEncode(this.Model.GameID));
        url.AppendFormat(CultureInfo.InvariantCulture, "&lang={0}", HttpUtility.UrlEncode(Language));
        url.AppendFormat(CultureInfo.InvariantCulture, "&pid={0}", HttpUtility.UrlEncode(Domain.GetCfg(PlaynGO.PID)));
        url.AppendFormat("&width=100%");
        url.AppendFormat("&height=100%");

        if (UserSession == null || FunMode)
        {
            url.Append("&practice=1&username=practice&demo=2");
        }
        else
        {
            url.Append("&practice=0");
            url.AppendFormat(CultureInfo.InvariantCulture, "&username={0}", GetLaunchToken());
            url.Append(GetRelityCheckiFrameUrl());
        }
        return url.ToString();
    }

    private string GetLaunchToken()
    {
        if (UseGmGaming)
        {
            TokenResponse response = GetToken();
            if (response.AdditionalParameters != null && response.AdditionalParameters.Exists(a => a.Name == "RealityCheckSec"))
            {
                RealityCheckTimeout = int.Parse(response.AdditionalParameters.First(a => a.Name == "RealityCheckSec").Value);
            }
            return response.TokenKey;
        }
        else
            using (GamMatrixClient client = new GamMatrixClient())
            {
                PlaynGOGetSessionRequest request = new PlaynGOGetSessionRequest()
                {
                    UserID = UserSession.UserID,
                };
                request = client.SingleRequest<PlaynGOGetSessionRequest>(UserSession.DomainID, request);
                LogGmClientRequest(request.SESSION_ID, request.Token);
                return request.Token;
            }
    }

    private string GetRelityCheckiFrameUrl()
    {
        string rciframe = string.Empty;

        if (RealityCheckTimeout > 0)
        {
            var pluginConfigUrl = this.Url.RouteUrl("Loader", new
            {
                @action = "RealityCheckConfig",
                @domainID = this.Model.DomainID,
                @id = ((int)GamMatrixAPI.VendorID.PlaynGO).ToString(),
                @realityCheckTimeout = RealityCheckTimeout
            });

            pluginConfigUrl = String.Format("{0}://{1}{2}", "https", "casino.gm.stage.everymatrix.com", pluginConfigUrl);

            rciframe = string.Format("&iframeoverlay={0}", HttpUtility.UrlEncode(pluginConfigUrl));
        }
        
        return rciframe;
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
        html, body {
            width: 100%;
            height: 100%;
            padding: 0px;
            margin: 0px;
            background: black;
            overflow: hidden;
        }

        #game-wrapper {
            margin: 0 auto;
        }
    </style>

    <script src="https://code.jquery.com/jquery-latest.min.js" type="text/javascript"></script>
</head>
<body>
       
    <% if (IsMobile)
       { %>

    <script type="text/javascript">
        
        <%if (RealityCheckTimeout > 0)
          { %>

        if (typeof (Storage) !== "undefined") 
        {
            // Store 
            localStorage.setItem("RealityCheckTimeout", '<%=RealityCheckTimeout%>' );
            localStorage.setItem("LobbyUrl", '<%=Domain.MobileLobbyUrl%>' );
            localStorage.setItem("HistoryUrl", '<%=Domain.MobileAccountHistoryUrl%>' );
        }
        else
        {
            console.log('error - localstorage is not supported...');
        }
        
        <% } %>

        function __redirect() {
            try {
                self.location.replace('<%= this.RedirectUrl.SafeJavascriptStringEncode() %>');
            }
            catch (e) {
                self.location = '<%= this.RedirectUrl.SafeJavascriptStringEncode() %>';

            }
        }
        setTimeout(2000, __redirect());
    </script>
    <% }
       else
       { %>
    <%---------------------If it is PC ----------------%>
    <div id="game-wrapper" style="width: 100%; height: 100%;" valign="middle">
        <div id="game-place-holder"></div>
    </div>
    <script type="text/javascript" src="<%= this.RedirectUrl.SafeHtmlEncode() %>"></script>

     <% if (RealityCheckTimeout > 0)
       { %>
    <script type="text/javascript" src="<%= Url.Content("~/js/realityCheck.js") %>"></script>
    <script type="text/javascript">

        var config = {
            beforeShowMessageFunction: invokeRealityCheck,
            messageAcknowlegeFunction: continuePlaying,
            realitychecktimeout: '<%=RealityCheckTimeout%>',
            historyLink: '<%=Domain.AccountHistoryUrl%>',
            lobbyLink: '<%=Domain.LobbyUrl%>'
        };        

        var RCComponent =
         {
             init: function () {  
                 Engage.addEventListener( "running", RCComponent.onEngageEvent.bind(RCComponent));     
                 Engage.addEventListener( "roundEnded", RCComponent.onEngageEvent.bind(RCComponent));      
                 emrc.init(config); 
             },
             //Post message to parent host (PNGHostInterface component)
             request: function (req) {
                 Engage.request(req);
             },
             onEngageEvent: function(e) 
             {
                 console.log("onPNGHostInterfaceEvent",e); 
                 switch(e.type) 
                 { 
                     //Spin is running, RC message can't be shown
                     case "running": 
                         emrc.changeGameStatus(true);
                         break; 
                         //Spin finished, RC message can be shown
                     case "roundEnded": 
                         emrc.changeGameStatus(false);
                         break; 
                 }
             }            
         };
                
        RCComponent.init();

        function continuePlaying() {
            RCComponent.request({ req: "gameEnable" });

        }

        function stopPlaying() {
            RCComponent.request({ req: "gameEnd", data: { redirectUrl: lobbyUrl } }
            );
        }
        
        function invokeRealityCheck()
        {
            RCComponent.request({ req: "gameDisable" });
            emrc.show();
        } 
    </script>
    <% } %>
    
    <%
    
           int initialWidth = this.Model.Width == 0 ? 1024 : this.Model.Width;
           int initialHeight = this.Model.Height == 0 ? 768 : this.Model.Height;
    %>
    <script type="text/javascript">
        function ShowCashier() {
            window.open('<%= this.Domain.CashierUrl.SafeJavascriptStringEncode() %>', '_blank');
        }

        function Logout(reason) {
            try
            {
                top.location.replace('<%= this.Domain.LobbyUrl.SafeJavascriptStringEncode() %>');
            }
            catch(e)
            {
                top.location = '<%= this.Domain.LobbyUrl.SafeJavascriptStringEncode() %>';
            }
        }

        $(function () {
    
            function resizeGame() {
                var initialWidth = <%= initialWidth %> * 1.00;
            var initialHeight = <%= initialHeight %> * 1.00;

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

        resizeGame();
        $(window).bind( 'resize', resizeGame);
    });
    </script>
    <% Html.RenderPartial("GoogleAnalytics", this.Domain, new ViewDataDictionary()
           {
               { "Language", this.Language},
               { "IsLoggedIn", this.ViewData["UserSession"] != null },
           }
           ); %>
    <%=InjectScriptCode(PlaynGO.CELaunchInjectScriptUrl) %>
    <% } %>

</body>
</html>
