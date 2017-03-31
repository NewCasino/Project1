<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.Xml" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GamMatrixAPI" %>
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

        this.SwfUrl = "//static.energycasino.com/GameLoader/loader.swf";

        int gameID;
        if( !int.TryParse( this.Model.GameID, out gameID) )
            throw new CeException( "Invalid GreenTube Game ID: [{0}]", this.Model.GameID);

        if (UserSession == null)
            throw new CeException("_sid is mandatory for GreenTube game!");

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
                );

            /*
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
            flashVars.AppendFormat("gameurl={0}", HttpUtility.UrlEncode(gameUrlNode.Value));
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
    <meta http-equiv="X-UA-Compatible" content="requiresActiveX=true" />
    <style type="text/css">
    html, body { width:100%; height:100%; padding:0px; margin:0px; background:black; overflow:hidden; }
    #game-wrapper { margin:0 auto; }
    </style>
    <script type="text/javascript" src="/js/jquery-1.7.2.min.js" ></script>
    <script type="text/javascript" src="/js/swfobject.js"></script>
</head>
<body>
    <div id="game-wrapper" style="width:100%; height:100%;" valign="middle">
        <object classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" width="100%" height="100%" id="ctlFlash">
            <param name="movie" value="<%= this.SwfUrl.SafeHtmlEncode() %>" />
            <param name="quality" value="high" />
            <param name="bgcolor" value="#000000" />
            <param name="scale" value="showall" />
            <param name="flashVars" value="<%= this.FlashVars.SafeHtmlEncode() %>" />
            <param name="salign" value="tl" />
            <param name="allowScriptAccess" value="always" />
            <param name="allowNetworking" value="all" />
            <param name="allowFullScreen" value="true" />
            <embed src="<%= this.SwfUrl.SafeHtmlEncode() %>" quality="high" bgcolor="#000000" scale="showall" width="100%" height="100%" flashvars="<%= this.FlashVars.SafeHtmlEncode() %>" id="ctlFlash" type="application/x-shockwave-flash" allowscriptaccess="always" allownetworking="all" allowfullscreen="true" salign="tl" pluginspage="https://get.adobe.com/cn/flashplayer/" />
        </object>
    </div>



    <script type="text/javascript">
        $(document).ready(function () {
            resizeGame();
            
            $(window).bind( 'resize', resizeGame);
        });
        

        function resizeGame() {
            var initialWidth = <%= this.Model.Width == 0 ? 1024 : this.Model.Width %> * 1.00;
            var initialHeight = <%= this.Model.Height == 0 ? 768 : this.Model.Height %> * 1.00;

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
    </script>
    

    <% Html.RenderPartial("GoogleAnalytics", this.Domain, new ViewDataDictionary()
           {
               { "Language", this.Language},
               { "IsLoggedIn", this.ViewData["UserSession"] != null },
           }
           ); %>

    <script src="//static.energycasino.com/GameLoader/game_loader.js" type="text/javascript"></script>
    <%=InjectScriptCode(GreenTube.CELaunchInjectScriptUrl) %>
</body>
</html>