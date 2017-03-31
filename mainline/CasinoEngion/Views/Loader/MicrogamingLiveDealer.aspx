<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmGamingAPI" %>

<script language="C#" type="text/C#" runat="server">
    private string CreateMicrogamingToken()
    {
        if (UseGmGaming)
        {
            List<NameValue> addParams = new List<NameValue>()
            {
                new NameValue { Name = "GameCode", Value = this.Model.GameCode }
            };

            return GetToken(addParams).TokenKey;
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

    public override string GetLanguage(string lang)
    {
        if (string.IsNullOrEmpty(lang))
            return "en";

        switch (lang.ToLowerInvariant())
        {
            case "es":
            case "tr":
            case "da":
            case "de":
            case "ru":
            case "ko":
                lang = lang.ToLowerInvariant();
                break;
            default:
                lang = "en";
                break;
        }
        return lang;
    }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        LaunchUrl = string.Format(Domain.GetCountrySpecificCfg(Microgaming.LiveCasinoLobbyURL, UserSession.UserCountryCode, UserSession.IpCountryCode)
            , Language
            , CreateMicrogamingToken()
            , HttpUtility.UrlEncode(this.Model.GameID)
            );
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
    html, body { width:100%; height:100%; padding:0px; margin:0px; background:#E9E9E9; overflow:hidden; }
    #ifmGame { width:100%; height:100%; border:0px; }
    </style>
</head>
<body>
    <iframe id="ifmGame" allowTransparency="true" frameborder="0" scrolling="no" src="<%= this.LaunchUrl.SafeHtmlEncode() %>"></iframe>
    <% Html.RenderPartial("GoogleAnalytics", this.Domain, new ViewDataDictionary()
           {
               { "Language", this.Language},
               { "IsLoggedIn", this.ViewData["UserSession"] != null },
           }
           ); %>
    <%=InjectScriptCode(Microgaming.CELaunchInjectScriptUrl) %>
</body>
</html>