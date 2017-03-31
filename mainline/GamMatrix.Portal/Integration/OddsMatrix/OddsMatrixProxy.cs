using System.Collections.Generic;
using System.Globalization;
using System.Net;
using CM.Content;
using CM.State;
using GmCore;

namespace OddsMatrix
{
    /// <summary>
    /// Summary description for OddsMatrixProxy
    /// </summary>
    public static class OddsMatrixProxy
    {
		public static Dictionary<string, string> GetLanguageMap()
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
                { "sk","sk_SK"},
                { "ar","ar_LB"}
			};
		}

        /// <summary>
        /// Map the GM language code to OM language code
        /// </summary>
        /// <param name="langCode"></param>
        /// <returns></returns>
        public static string MapLanguageCode(string langCode)
        {
            string code = null;
            if (GetLanguageMap().TryGetValue(langCode.ToLower(CultureInfo.InvariantCulture), out code))
            {
                return code;
            }
            return "en_GB";
            //return GetLanguageMap()[langCode.ToLower(CultureInfo.InvariantCulture)] ?? "en_GB";
        }

        /// <summary>
        /// http://sports.betexpress.com/partnerapi1/customerLogout.do?currentSession={0}&username={1}
        /// </summary>
        public static void Logoff()
        {
            try
            {
                if (CustomProfile.Current.IsAuthenticated)
                {
                    string url = Metadata.Get("/Metadata/Settings.OddsMatrix_LogoffUrl");
                    if (!string.IsNullOrWhiteSpace(url) && GamMatrixClient.GetGamingVendors().Exists(v => v.VendorID == GamMatrixAPI.VendorID.OddsMatrix))
                    {
                        url = string.Format(url
                            , CustomProfile.Current.SessionID
                            , CustomProfile.Current.UserName
                            );
                        using (WebClient webClient = new WebClient())
                        {
                            webClient.DownloadString(url);
                        }
                    }
                }
            }
            catch
            {
            }
        }
    }


}