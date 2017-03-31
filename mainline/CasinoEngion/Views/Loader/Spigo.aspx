<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="CE.db.Accessor" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="GmGamingAPI" %>

<script language="C#" type="text/C#" runat="server">

    protected string IsStage{ get; private set; }
    protected string UserName{ get; private set; }
    protected string PlayerId{ get; private set; }
    protected string Token{ get; private set; }
    protected string Currency{ get; private set; }
    protected int SiteId { get; private set; }
    protected string Alias { get; private set; }
    protected string Locale { get; private set; }
    
    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        int siteId;
        if (Int32.TryParse(Domain.GetCfg(Spigo.SiteID), out siteId))
        {
            SiteId = siteId;
        }
        string isLive = Domain.GetCfg(Spigo.IsLive);
        IsStage = (isLive == "1") ? "False" : "True";
        Locale = Language;

        if (!FunMode)
        {
            TokenResponse response = GetToken();

            Currency = this.UserSession.Currency;
            if (response.AdditionalParameters.Exists(a => a.Name == "UserCasinoCurrency"))
            {
                Currency = response.AdditionalParameters.First(a => a.Name == "UserCasinoCurrency").Value;
            }

            if (response.AdditionalParameters.Exists(a => a.Name == "siteId"))
            {
                SiteId = int.Parse(response.AdditionalParameters.First(a => a.Name == "siteId").Value);
            }

            UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
            string alias = ua.GetUserAlias(UserSession.UserID);
            
            Token = response.TokenKey;
            PlayerId = UserSession.UserID.ToString() + '~' + this.Domain.DomainID;
            Alias = String.IsNullOrWhiteSpace(alias) ? UserSession.UserID.ToString() : alias;
            Locale += "-" + this.UserSession.UserCountryCode;
            
        }
        
        //url = url + "opengame?" + "siteId=" + siteId + "&playerPartnerIdentifier=" + playerPartnerIdentifier + "&gameId=" + gameId
        //    + "&sessionId=" + sessionId + "&alias=" + alias + "&currencyISO4217=" + currencyISO4217 + "&localeISO639_ISO3166=" + localeISO639_ISO3166;
        
        StringBuilder url = new StringBuilder();
        url.Append(Domain.GetCfg(Spigo.GameBaseURL));
        url.AppendFormat("opengame?siteId={0}&playerPartnerIdentifier={1}&gameId={2}&sessionId={3}&alias={4}&currencyISO4217={5}&localeISO639_ISO3166={6}",
         SiteId, PlayerId, GameID, Token, Alias, Currency, Locale);

        this.LaunchUrl = url.ToString();

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
    <meta http-equiv="Access-Control-Allow-Origin" content="*"/>
    <style type="text/css">
    html, body { width:100%;height: 100%; padding:0px; margin:0px; background:#E9E9E9; overflow:hidden; }
    #ifmGame {  width:100%;height: 100%; border:0px; }
    </style>
</head>
<body>
    <script src="//ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js"></script>
    <script src="https://api.spigoworld.com/javascript/spigo_frontend.js" type="text/javascript">
    </script>
    
    <% Html.RenderPartial("GoogleAnalytics", this.Domain, new ViewDataDictionary()
           {
               { "Language", this.Language},
               { "IsLoggedIn", this.ViewData["UserSession"] != null },
           }
    ); %>
    
    <iframe id="ifmGame" allowtransparency="true" frameborder="0" scrolling="no" src=""></iframe>
    
    <script type="text/javascript"> 
        
        var mobileDevice = <%=CE.Utils.PlatformHandler.IsMobile.ToString().ToLowerInvariant()%>;
        var url = '<%= this.LaunchUrl %>';
        var funMode = <%=FunMode.ToString().ToLowerInvariant()%>;

        if (mobileDevice && window.parent != null) {
            window.parent.location = url;
        } else if(mobileDevice) {
            window.location = url;
        }
        else {
            $('#ifmGame').attr('src', url);
        }

    </script>
   
</body>
</html>