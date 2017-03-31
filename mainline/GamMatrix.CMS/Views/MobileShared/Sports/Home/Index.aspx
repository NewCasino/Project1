<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="OddsMatrix" %>
<script type="text/C#" runat="server">
    protected override void OnInit(EventArgs e)
    {
        Response.Redirect(GetUrl());
        base.OnInit(e);
    }

    private string GetUrl()
    {
StringBuilder sb = new StringBuilder(Settings.OddsMatrix_HomePage);

string pageUrl = Request.QueryString["pageURL"];
if (string.IsNullOrWhiteSpace(pageUrl))
{
pageUrl = string.Empty;
}
else
{
if (pageUrl.IndexOf("/") != 0)
pageUrl = string.Format("/{0}", pageUrl);
}

int queryIndex = sb.ToString().IndexOf('?');
        if (queryIndex > 0)
sb.Insert(queryIndex, pageUrl).Append('&');
        else
sb.Append(pageUrl).Append('?');

        sb.AppendFormat(CultureInfo.InvariantCulture, "lang={0}"
            , HttpUtility.UrlEncode(MapLanguageCode(HttpContext.Current.GetLanguage()))
        );

        sb.AppendFormat(CultureInfo.InvariantCulture, "&currentSession={0}"
            , HttpUtility.UrlEncode(Profile.SessionID)
            );
        foreach (string key in Request.QueryString.AllKeys)
        {
            if (string.Equals(key, "_sid", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(key, "pageName", StringComparison.OrdinalIgnoreCase) ||
string.Equals(key, "pageURL", StringComparison.OrdinalIgnoreCase))
                continue;

            sb.AppendFormat(CultureInfo.InvariantCulture, "&{0}={1}", HttpUtility.UrlEncode(key), HttpUtility.UrlEncode(Request.QueryString[key]));
        }

        return sb.ToString();
    }
    private static Dictionary<string, string> GetLanguageMap()
{
return new Dictionary<string, string>()
{
{ "en", "en_GB" },
                { "en-au","en_AU"},
                { "en-nz","en_NZ"},
                { "en-ca","en_CA"},
{ "da", "da_DK" },
{ "de", "de_DE" },
{ "sv", "sv_SE" },
{ "fr", "fr_FR" },
{ "es", "es_ES" },
                { "et", "et_EE" },
{ "pt", "pt_PT" },
{ "zh-cn", "zh_CN" },
{ "zh-tw", "yu_CN" },
{ "gr", "gr_GR" },
{ "nl", "nl_NL" },
{ "it", "it_IT" },
{ "ro", "ro_RO" },
{ "he", "he_IL" },
{ "sr", "sr_YU" },
{ "cs", "cz_CZ" },
{ "no", "no_NO" },
{ "pl", "pl_PL" },
{ "ru", "ru_RU" },
{ "fi", "fi_FI" },
{ "tr", "tr_TR" },
{ "ka", "ka_GE" },
{ "bg", "bg_BG" },
{ "hr", "hr_HR"},
{ "el", "gr_GR"},
{ "lt", "lt_LT"},
{ "th", "th_TH"},
{ "ja", "ja_JP"},
                { "ko", "ko_EN"},
                { "pt-br", "pt_BR"},
                { "hu","hu_HU"},
                { "vi","vi_VN"},
                { "sk","sk_SK"}
};
}
     private static string MapLanguageCode(string langCode)
        {
            string code = null;
            if (GetLanguageMap().TryGetValue(langCode.ToLower(CultureInfo.InvariantCulture), out code))
            {
                return code;
            }
            return "en_GB";
            //return GetLanguageMap()[langCode.ToLower(CultureInfo.InvariantCulture)] ?? "en_GB";
        }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">


</asp:Content>

