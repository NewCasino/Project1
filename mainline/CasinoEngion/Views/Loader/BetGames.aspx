<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="CE.db" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script language="C#" type="text/C#" runat="server">
    private string ServerHost { get; set; }
    private string PartnerCode { get; set; }
    private string JavascriptSrc { get; set; }
    private string Token { get; set; }
    private string LobbyGameId { get; set; }
    private string ShowLiveLobby { get; set; }

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
            case "he": return "il";
            default: return lang.Truncate(2).ToLowerInvariant();
        }
    }
    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        ShowLiveLobby = Domain.GetCfg(BetGames.ShowLiveLobby);
        LobbyGameId = ShowLiveLobby == "true" ? Domain.GetCfg(BetGames.DefaultLobbyGameId) : this.Model.GameID;
        
        if (UserSession == null || FunMode)
            throw new CeException("BetGames is only available in real money mode!");
        


        Dictionary<string, ceLiveCasinoTableBaseEx> tables = global::CacheManager.GetLiveCasinoTableDictionary(Domain.DomainID);
        ceLiveCasinoTableBaseEx table;
        if (!tables.TryGetValue(TableID, out table))
            throw new CeException("Invalid table id [{0}]", TableID);

        ServerHost = Domain.GetCfg(BetGames.Server);

        if (string.Equals(UserSession.Currency, "TRY", StringComparison.InvariantCultureIgnoreCase) || 
            string.Equals(UserSession.IpCountryCode, "TR", StringComparison.InvariantCultureIgnoreCase) ||
            string.Equals(UserSession.UserCountryCode, "TR", StringComparison.InvariantCultureIgnoreCase))
            PartnerCode = Domain.GetCfg(BetGames.SubPartnerCode);
        else
            PartnerCode = Domain.GetCfg(BetGames.PartnerCode);
        
        JavascriptSrc = string.Format(Domain.GetCfg(BetGames.LaunchJavaScriptSrc), ServerHost);

        if (UseGmGaming)
        {
            Token = GetToken().TokenKey;
        }
        else
        {
            throw new CeException("GmGaming only valid to get token");
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
    html, body { width:100%; height:100%; padding:0px; margin:0px; background:#E9E9E9; }
    #ifmGame { width:100%; height:100%; border:0px; }
    </style>
    <script type="text/javascript" src="/js/jquery-1.7.2.min.js" ></script>
    <script type="text/javascript" src="/js/swfobject.js"></script>
</head>
<body>
    <script type="text/javascript">
        var d = new Date();
        var gmtHours = d.getTimezoneOffset() / 60;

        var _bt = _bt || [];
        _bt.push(['server', '<%=this.ServerHost.SafeJavascriptStringEncode()%>']);
        _bt.push(['partner', '<%=this.PartnerCode.SafeJavascriptStringEncode()%>']);
        _bt.push(['token', '<%=this.Token.SafeJavascriptStringEncode()%>']);
        _bt.push(['language', '<%=this.Language.SafeJavascriptStringEncode()%>']);
        _bt.push(['timezone', gmtHours]);
        _bt.push(['current_game', '<%=LobbyGameId%>']);
        <% if (PlatformHandler.IsMobile) {%>
            _bt.push(['is_mobile', '1']);
        <%} %>

        (function () {
            document.write('<' + 'script type="text/javascript" src="<%=this.JavascriptSrc.SafeJavascriptStringEncode()%>"><' + '/script>');
        })();
 </script>
 <script type="text/javascript">BetGames.frame(_bt);</script>
</body>
</html>