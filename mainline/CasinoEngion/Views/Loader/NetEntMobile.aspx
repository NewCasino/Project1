<%@ Page Language="C#" Inherits="CE.Extensions.LoaderViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="GamMatrixAPI" %>

<script language="C#" type="text/C#" runat="server">
/// <summary>
/// http://www.w3.org/WAI/ER/IG/ert/iso639.htm
/// 
/// </summary>
/// <param name="lang"></param>
/// <returns></returns>
/*
AA "Afar"
AB "Abkhazian"
AF "Afrikaans"
AM "Amharic"
AR "Arabic"
AS "Assamese"
AY "Aymara"
AZ "Azerbaijani"
BA "Bashkir"
BE "Byelorussian"
BG "Bulgarian"
BH "Bihari"
BI "Bislama"
BN "Bengali" "Bangla"
BO "Tibetan"
BR "Breton"
CA "Catalan"
CO "Corsican"
CS "Czech"
CY "Welsh"
DA "Danish"
DE "German"
DZ "Bhutani"
EL "Greek"
EN "English" "American"
EO "Esperanto"
ES "Spanish"
ET "Estonian"
EU "Basque"
FA "Persian"
FI "Finnish"
FJ "Fiji"
FO "Faeroese"
FR "French"
FY "Frisian"
GA "Irish"
GD "Gaelic" "Scots Gaelic"
GL "Galician"
GN "Guarani"
GU "Gujarati"
HA "Hausa"
HI "Hindi"
HR "Croatian"
HU "Hungarian"
HY "Armenian"
IA "Interlingua"
IE "Interlingue"
IK "Inupiak"
IN "Indonesian"
IS "Icelandic"
IT "Italian"
IW "Hebrew"
JA "Japanese"
JI "Yiddish"
JW "Javanese"
KA "Georgian"
KK "Kazakh"
KL "Greenlandic"
KM "Cambodian"
KN "Kannada"
KO "Korean"
KS "Kashmiri"
KU "Kurdish"
KY "Kirghiz"
LA "Latin"
LN "Lingala"
LO "Laothian"
LT "Lithuanian"
LV "Latvian" "Lettish"
MG "Malagasy"
MI "Maori"
MK "Macedonian"
ML "Malayalam"
MN "Mongolian"
MO "Moldavian"
MR "Marathi"
MS "Malay"
MT "Maltese"
MY "Burmese"
NA "Nauru"
NE "Nepali"
NL "Dutch"
NO "Norwegian"
OC "Occitan"
OM "Oromo" "Afan"
OR "Oriya"
PA "Punjabi"
PL "Polish"
PS "Pashto" "Pushto"
PT "Portuguese"
QU "Quechua"
RM "Rhaeto-Romance"
RN "Kirundi"
RO "Romanian"
RU "Russian"
RW "Kinyarwanda"
SA "Sanskrit"
SD "Sindhi"
SG "Sangro"
SH "Serbo-Croatian"
SI "Singhalese"
SK "Slovak"
SL "Slovenian"
SM "Samoan"
SN "Shona"
SO "Somali"
SQ "Albanian"
SR "Serbian"
SS "Siswati"
ST "Sesotho"
SU "Sudanese"
SV "Swedish"
SW "Swahili"
TA "Tamil"
TE "Tegulu"
TG "Tajik"
TH "Thai"
TI "Tigrinya"
TK "Turkmen"
TL "Tagalog"
TN "Setswana"
TO "Tonga"
TR "Turkish"
TS "Tsonga"
TT "Tatar"
TW "Twi"
UK "Ukrainian"
UR "Urdu"
UZ "Uzbek"
VI "Vietnamese"
VO "Volapuk"
WO "Wolof"
XH "Xhosa"
YO "Yoruba"
ZH "Chinese"
ZU "Zulu"*/
public override string GetLanguage(string lang)
{
    //ConvertToISO639
    if (string.IsNullOrWhiteSpace(lang))
        return "en";

    switch (lang.Truncate(2).ToLowerInvariant())
    {
        case "he": return "iw";
        case "ka": return "en";
        case "ko": return "en";
        case "ja": return "en";
        case "bg": return "en";
        case "zh": return "en";
        default: return lang.ToLowerInvariant();
    }
}
private string RedirectUrl
{
    get;
    set;
}

public string CreateNetEntSessionID()
{
    if (UseGmGaming)
    {
        return GetToken().TokenKey;
    }
    
    using (GamMatrixClient client = new GamMatrixClient())
    {
        NetEntAPIRequest request;
        string cacheKey = string.Format("_casino_netent_mobile_session_id_{0}", UserSession.Guid);

        // use the cached session if still valid
        string sessionID = HttpRuntime.Cache[cacheKey] as string;
        if (!string.IsNullOrWhiteSpace(sessionID))
        {
            request = new NetEntAPIRequest()
            {
                IsUserSessionAlive = true,
                IsUserSessionAliveSessionID = sessionID,
                Channel = "mobg",
            };
            request = client.SingleRequest<NetEntAPIRequest>(UserSession.DomainID, request);
            LogGmClientRequest(request.SESSION_ID, request.IsUserSessionAliveResponse.ToString(), "IsUserSessionAlive");
            if (request.IsUserSessionAliveResponse)
                return sessionID;
        }

        // generate a new session id
        request = new NetEntAPIRequest()
        {
            UserID = UserSession.UserID,
            Channel = "mobg",
            LoginUserDetailedByChannel = true,  
        };
        request = client.SingleRequest<NetEntAPIRequest>(UserSession.DomainID, request);
        LogGmClientRequest(request.SESSION_ID, request.LoginUserDetailedResponse, "sID");
        sessionID = request.LoginUserDetailedResponse;

        HttpRuntime.Cache[cacheKey] = sessionID;
        return sessionID;
    }
}

protected override void OnInit(EventArgs e)
{
    base.OnInit(e);

    Random rand = new Random();
    string sessionID = string.Format( "DEMO-{0:000}-EUR", rand.Next() % 1000);
    if (UserSession != null && !FunMode)
        sessionID = CreateNetEntSessionID();
    
    string returnUrl = string.Format( "{0}/Loader/Return/{1}/NetEnt/"
        ,  ConfigurationManager.AppSettings["ApiUrl"].TrimEnd('/')
        , Domain.DomainID
        );

    string url = Domain.GetCfg(NetEnt.MobileGameURL);
    // https://oddsmatrix-static.casinomodule.com/games/{0}/game/{0}.xhtml?gameId={1}&amp;lang={2}&amp;historyURL=/{2}/&amp;sessId={3}&amp;lobbyURL={4}&amp;operatorId=oddsmatrix&amp;server=https%3A%2F%2Foddsmatrix-game.casinomodule.com%2F
    url = string.Format(url
        , Regex.Replace(this.Model.GameID, @"(_sw)$", string.Empty, RegexOptions.IgnoreCase)
        , this.Model.GameID
        , this.Language
        , sessionID
        , HttpUtility.UrlEncode( returnUrl )
        );

    this.RedirectUrl = url;
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
    </style>
</head>
<body>
    <% Html.RenderPartial("GoogleAnalytics", this.Domain, new ViewDataDictionary()
           {
               { "Language", this.Language},
               { "IsLoggedIn", this.ViewData["UserSession"] != null },
           }
           ); %>

    <script type="text/javascript">
        function __redirect() {
            try {
                self.location.replace('<%= this.RedirectUrl.SafeJavascriptStringEncode() %>');
            }
            catch (e) {
                self.location = '<%= this.RedirectUrl.SafeJavascriptStringEncode() %>';
            }
        }
        setTimeout(3000, __redirect);
    </script>
    <%=InjectScriptCode(NetEnt.CELaunchInjectScriptUrl) %>
</body>
</html>