<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script language="C#" type="text/C#" runat="server">
    public override string GetLanguage(string lang)
    {
        lang = lang.ToLowerInvariant();
        
        switch (lang)
        { 
            case "fi":
            case "de":
            case "no":
            case "sv":
                break;
            default :
                lang = "en";
                break;
        }
        
        return lang;
    }

    private string GetCurrency(string currency)
    {
        currency = currency.ToUpperInvariant();

        switch (currency)
        {
            case "NOK":
            case "SEK":
            case "GBP":
            case "USD":
            case "AUD":
                break;
            default:
                currency = "EUR";
                break;
        }

        return currency;
    }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        //if (session == null)
        //    throw new CeException("Please log in first before you can play GTS game.");

        if (!FunMode && UserSession == null)
            FunMode = true;

        string language = GetLanguage(this.ViewData["Language"] as string ?? "en");
        this.Language = language;

        string currency = "EUR";

        //?gameType=***GAME_TYPE***&region=***REGION***&token=***TOKEN***
        //?gameType=***GAME_TYPE***&token=***TOKEN***&language=***language***&currency=***currency***
        StringBuilder url = new StringBuilder();
        url.Append(Domain.GetCfg(GTS.GameBaseURL));
        url.AppendFormat("?gameType={0}", HttpUtility.UrlEncode(this.Model.GameID));

        if (FunMode)
        {
            url.Append("&forMoney=false");
        }
        else
        {
            currency = GetCurrency(UserSession.Currency);

            string token;
            if (UseGmGaming)
            {
                token = GetToken().TokenKey;
            }
            else
                using (GamMatrixClient client = new GamMatrixClient())
                {
                    GTSGetSessionRequest request = new GTSGetSessionRequest()
                    {
                        UserID = UserSession.UserID,
                        ContextDomainID = UserSession.DomainID,
                    };

                    request = client.SingleRequest<GTSGetSessionRequest>(UserSession.DomainID, request);
                    LogGmClientRequest(request.SESSION_ID, request.Token);

                    token = request.Token;
                }
            
            url.AppendFormat("&token={0}", HttpUtility.UrlEncode(token));
        }

        url.AppendFormat("&language={0}&region={1}", language, HttpUtility.UrlEncode(currency + " Global"));

        this.LaunchUrl = url.ToString();
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
    <style type="text/css">
    html, body { width:100%; height:100%; padding:0px; margin:0px; background:#E9E9E9; overflow:hidden; }
    #ifmGame { width:100%; height:100%; border:0px; }
    </style>
</head>
<body>
    <iframe id="ifmGame" allowTransparency="true" frameborder="0" scrolling="no" src="<%= this.LaunchUrl.SafeHtmlEncode() %>"></iframe>
    <%=InjectScriptCode(GTS.CELaunchInjectScriptUrl) %>
</body>
</html>