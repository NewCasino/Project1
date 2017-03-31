<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="CE.Utils" %>
<%@ Import Namespace="GmGamingAPI" %>

<script language="C#" type="text/C#" runat="server">
    public string ResultedAppletHtml { get; internal set; }

    public override string GetLanguage(string lang)
    {
        //  English
        //  German
        //  French
        //  Italian
        //  Spanish
        //  Portuguese
        //  Greek
        //  Chinese Traditional
        //  Chinese Simplified
        //  Korean
        //  Mongolian
        //  Russian
        //  Serbian
        //  Polish

        SupportedLanguages = new List<string> { "en", "de", "fr", "it", "es", "pt", "el", "zh", "ko", "mn", "ru", "sr", "pl" };
        return base.GetLanguage(lang);
    }

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);

        List<NameValue> addParams = new List<NameValue>()
        {
            new NameValue { Name = "UserLanguage", Value = this.Language },
            new NameValue { Name = "GameID", Value = this.Model.GameID },
            new NameValue { Name = "IsLiteHTML5", Value = PlatformHandler.IsMobile.ToString() }
        };

        TokenResponse response = GetToken(addParams);

        if (response.AdditionalParameters.Exists(a => a.Name == "applet"))
            ResultedAppletHtml = response.AdditionalParameters.First(a => a.Name == "applet").Value;
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
    <style type="text/css">
    html, body { width:100%; height:100%; padding:0px; margin:0px; background:#E9E9E9; overflow:hidden; }
    #ifmGame { width:100%; height:100%; border:0px; }
    </style>
</head>
<body>
    <%= ResultedAppletHtml %>
    <% Html.RenderPartial("GoogleAnalytics", this.Domain, new ViewDataDictionary()
           {
               { "Language", this.Language},
               { "IsLoggedIn", this.ViewData["UserSession"] != null },
           }
           ); %>
</body>
</html>