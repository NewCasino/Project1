<%@ Page Language="C#" Inherits="System.Web.Mvc.ViewPage<CE.db.ceCasinoGameBaseEx>" %>
<%@ Import Namespace="CE.db" %>
<%@ Import Namespace="CE.DomainConfig" %>
<%@ Import Namespace="GamMatrixAPI" %>
<script language="C#" type="text/C#" runat="server">
    private string GetISO639LanguageCode()
    {
        string lang = ViewData["Language"] as string;
        if (string.IsNullOrWhiteSpace(lang))
            return "en";

        string resultLang = lang.Truncate(2).ToLowerInvariant();

        if (resultLang == "he")
        {
            resultLang = "iw";
        }


        string[] supportedLangsArray =
        {
            "br",
            "bg",
            "hr",
            "cs",
            "da",
            "nl",
            "en",
            "et",
            "fi",
            "fr",
            "de",
            "el",
            "iw",
            "hu",
            "it",
            "no",
            "pl",
            "pt",
            "ro",
            "ru",
            "cn",
            "sk",
            "es",
            "sv",
            "tr"
        };

        List<string> supportedList = new List<string>(supportedLangsArray);

        if (!supportedList.Contains(resultLang))
        {
            resultLang = "en";
        }
        return resultLang;
    }

    protected override void OnInit(EventArgs e)
    {
        ceDomainConfigEx domain = this.ViewData["Domain"] as ceDomainConfigEx;
        using (GamMatrixClient client = new GamMatrixClient())
        {
            NetEntAPIRequest request = new NetEntAPIRequest()
            {
                GetGameInfo = true,
                GetGameInfoGameID = this.Model.GameID,
                GetGameInfoLanguage = GetISO639LanguageCode()
            };
            request = client.SingleRequest<NetEntAPIRequest>(domain.DomainID, request);

            Dictionary<string, string> dic = new Dictionary<string, string>();
            for (int i = 0; i < request.GetGameInfoResponse.Count - 1; i += 2)
            {
                dic.Add(request.GetGameInfoResponse[i], request.GetGameInfoResponse[i + 1]);
            }

            string url = string.Format("{0}{1}"
                , domain.GetCfg(NetEnt.GameRulesBaseURL)
                , HttpUtility.UrlDecode(dic["helpfile"])
                );
            Response.Redirect(url);
        }
        base.OnInit(e);
    }
</script>
