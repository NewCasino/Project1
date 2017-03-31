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

    public string JwtToken = string.Empty;
    public string Currency = string.Empty;
    public string JsBaseUrl = string.Empty;

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        JsBaseUrl = Domain.GetCfg(LiveGames.ScriptBaseUrl);  
        
        if (!FunMode)
        {
            TokenResponse response = GetToken();
            Currency = UserSession.Currency;
            if (response.AdditionalParameters.Exists(a => a.Name == "UserCasinoCurrency"))
            {
                Currency = response.AdditionalParameters.First(a => a.Name == "UserCasinoCurrency").Value;
            }

            if (!response.AdditionalParameters.Exists(a => a.Name == "JwtToken"))
            {
                throw new CeException("Failed to generate jwt token from Gic");    
            }
            
            JwtToken = response.AdditionalParameters.First(a => a.Name == "JwtToken").Value;
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
        html, body {
            width: 100%;
            height: 100%;
            padding: 0px;
            margin: 0px;
            background: #E9E9E9;
        }

        #ifmGame {
            width: 100%;
            height: 100%;
            border: 0px;
        }
    </style>
  <script type="text/javascript">
  (function(l,i,v,e,t,c,h){
  l['LiveGamesObject']=t;l[t]=l[t]||function(){(l[t].q=l[t].q||[]).push(arguments)},
  l[t].l=1*new Date();c=i.createElement(v),h=i.getElementsByTagName(v)[0];
  c.async=1;c.src=e;h.parentNode.insertBefore(c,h)
  })(window, document, 'script', '<%= JsBaseUrl%>', 'lg');
  if(lg){
      lg('sign', '<%= JwtToken%>');
      lg('currency', '<%= Currency%>');
      lg('bgColor', '000');
      
      lg('frames', [ 
          {
              container:'lgGameContainer', 
              windowName :'liveGamesFrame', 
              service : 'game'
          }
      ]);
  }
</script>
</head>
<body>
</body>
</html>
