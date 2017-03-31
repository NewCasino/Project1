using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Runtime.Serialization.Formatters.Binary;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Caching;
using System.Web.Hosting;
using System.Web.Mvc;
using CM.db;
using CM.Sites;
using GamMatrix.Infrastructure;

namespace CM.Content
{
    [Serializable]
    public sealed class LanguageInfo
    {
        public string LanguageCode { get; set; }
        public string CountryFlagName { get; set; }
        public string DisplayName { get; set; }
    }

    [Serializable]
    public sealed class CountryLanguageInfo
    {
        public string LanguageCode { get; set; }
        //public bool IsExclude { get; set; }
        public string CountryIds { get; set; }
    }

    public static class MultilingualMgr
    {
        private static Regex urlRegex = new Regex(@"^(?<part1>(http(s?)\:\/\/[^\/]+)?)(?<part2>\/.*)", RegexOptions.IgnoreCase | RegexOptions.Compiled | RegexOptions.CultureInvariant);
        public static string RouteUrlWithLanguage(this UrlHelper urlHelper, string routeName, object routeValues, string language = null)
        {
            string langlocal = null;
            if (string.IsNullOrWhiteSpace(language) && HttpContext.Current != null)
                langlocal = HttpContext.Current.GetLanguage();
            if(langlocal != null)
                language = langlocal;
            string url = urlHelper.RouteUrl(routeName, routeValues);
            Match match = urlRegex.Match(url);
            if (match.Success)
                return string.Format("{0}/{1}{2}", match.Groups["part1"].Value, language, match.Groups["part2"].Value);

            return url;
        }

        public static LanguageInfo[] GetSupporttedLanguages(this cmSite site)
        {
            string cacheKey = string.Format("site_languages_{0}", site.DistinctName);
            LanguageInfo[] languages = HttpRuntime.Cache[cacheKey] as LanguageInfo[];
            if (languages == null)
            {
                languages = LoadFromFile(site.DistinctName);

                string path = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/language.setting", site.DistinctName));
                HttpRuntime.Cache.Insert(cacheKey
                    , languages
                    , new CacheDependency(path)
                    );
            }
            return languages;
        }

        public static void Save(string distinctName, LanguageInfo[] languages)
        {
            if (languages == null)
                throw new ArgumentException("Error, parameter [languages] can't be null.");
            string path = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/language.setting", distinctName));
            FileSystemUtility.EnsureDirectoryExist(path);
            BinaryFormatter bf = new BinaryFormatter();

            using (FileStream fs = new FileStream(path, FileMode.OpenOrCreate, FileAccess.Write, FileShare.Delete | FileShare.ReadWrite))
            {
                fs.SetLength(0L);
                bf.Serialize(fs, languages);
                fs.Flush();
                fs.Close();
            }
        }

        public static LanguageInfo[] LoadFromFile(string distinctName)
        {
            string path = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/language.setting", distinctName));
            if (!File.Exists(path))
                return new LanguageInfo[0];

            BinaryFormatter bf = new BinaryFormatter();
            using (FileStream fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Delete | FileShare.ReadWrite))
            {
                return (LanguageInfo[])bf.Deserialize(fs);
            }
        }

        public static LanguageInfo GetCurrentLanguage(this cmSite site)
        {
            LanguageInfo[] supportedLanguages = GetSupporttedLanguages(site);
            Func<string, LanguageInfo> queryByCulture =
                c => supportedLanguages.FirstOrDefault(l => string.Equals(l.LanguageCode, c, StringComparison.InvariantCultureIgnoreCase));
            LanguageInfo currentLanguage = null;

            if (HttpContext.Current != null)
                currentLanguage = queryByCulture(HttpContext.Current.GetLanguage());
            if (currentLanguage == null)
                currentLanguage = queryByCulture(site.DefaultCulture);

            return currentLanguage;
        }

        public static string GetCurrentCulture()
        {
            if (HttpContext.Current != null)
            {
                return HttpContext.Current.GetLanguage().DefaultIfNullOrEmpty(SiteManager.Current.DefaultCulture);
            }
            return "en";
        }

        /// <summary>
        /// http://www.w3.org/WAI/ER/IG/ert/iso639.htm
        /// 
        /// </summary>
        /// <param name="lang"></param>
        /// <returns></returns>
        /*
         * AA "Afar"
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
        public static string ConvertToISO639(string lang)
        {
            if (string.IsNullOrWhiteSpace(lang))
                return "en";

            switch (lang.Truncate(2).ToLowerInvariant())
            {
                case "pt-br": return "br";
                case "he": return "iw";
                default: return lang.ToLowerInvariant();
            }
        }

        public static CountryLanguageInfo[] LoadCountryLanguages(string distinctName)
        {
            //string path = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/country_language.setting", distinctName));
            //if (!File.Exists(path))
            //    return new CountryLanguageInfo[0];

            //var dic = ObjectHelper.XmlDeserialize<Dictionary<string, string>>(path, new Dictionary<string, string>());

            //var countrylanguages = new CountryLanguageInfo[Convert.ToInt32(dic["Total"])];
            //for (var i = 0; i < countrylanguages.Length; i++)
            //{
            //    countrylanguages[i] = new CountryLanguageInfo();
            //    countrylanguages[i].LanguageCode = dic["LanguageCode_" + i.ToString(CultureInfo.InvariantCulture)];
            //    countrylanguages[i].IsExclude = Convert.ToBoolean(dic["IsExclude_" + i.ToString(CultureInfo.InvariantCulture)]);
            //    countrylanguages[i].CountryIds = dic["CountryIds_" + i.ToString(CultureInfo.InvariantCulture)];
            //}
            //return countrylanguages;

            string cacheKey = string.Format(CultureInfo.InvariantCulture
                , "~/Views/{0}/.config/country_language.setting"
                , distinctName
                );
            Dictionary<string, string> rules = HttpRuntime.Cache[cacheKey] as Dictionary<string, string>;
            if (rules == null)
            {
                rules = ObjectHelper.XmlDeserialize<Dictionary<string, string>>(HostingEnvironment.MapPath(cacheKey), null);
                if (rules == null)
                {
                    rules = new Dictionary<string, string>(StringComparer.InvariantCultureIgnoreCase);
                    rules.Add("Total", "0");
                }

                HttpRuntime.Cache.Insert(cacheKey
                    , rules
                    , new CacheDependencyEx(new string[] { cacheKey }, true)
                    , Cache.NoAbsoluteExpiration
                    , Cache.NoSlidingExpiration
                    , CacheItemPriority.NotRemovable
                    , null
                    );
            }

            var countrylanguages = new CountryLanguageInfo[Convert.ToInt32(rules["Total"])];
            for (var i = 0; i < countrylanguages.Length; i++)
            {
                countrylanguages[i] = new CountryLanguageInfo();
                countrylanguages[i].LanguageCode = rules["LanguageCode_" + i.ToString(CultureInfo.InvariantCulture)];
                //countrylanguages[i].IsExclude = Convert.ToBoolean(rules["IsExclude_" + i.ToString(CultureInfo.InvariantCulture)]);
                countrylanguages[i].CountryIds = rules["CountryIds_" + i.ToString(CultureInfo.InvariantCulture)];
            }
            return countrylanguages;
        }

        public static void SaveCountryLanguages(string distinctName, CountryLanguageInfo[] countrylanguages)
        {
            if (countrylanguages == null)
                throw new ArgumentException("Error, parameter [countrylanguages] can't be null.");

            string path = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/country_language.setting", distinctName));

            Dictionary<string, string> rules = new Dictionary<string, string>();
            rules.Add("Total", countrylanguages.Length.ToString(CultureInfo.InvariantCulture));
            for (int i = 0; i < countrylanguages.Length; i++)
            {
                rules.Add("LanguageCode_" + i.ToString(CultureInfo.InvariantCulture), countrylanguages[i].LanguageCode);
                //rules.Add("IsExclude_" + i.ToString(CultureInfo.InvariantCulture), countrylanguages[i].IsExclude.ToString());
                rules.Add("CountryIds_" + i.ToString(CultureInfo.InvariantCulture), countrylanguages[i].CountryIds);
            }

            //ObjectHelper.XmlSerialize<Dictionary<string, string>>(dic, path);

            string cacheKey = string.Format(CultureInfo.InvariantCulture
                , "~/Views/{0}/.config/country_language.setting"
                , distinctName
                );
            HttpRuntime.Cache.Remove(cacheKey);

            string cacheKey2 = string.Format(CultureInfo.InvariantCulture
                , "~/Views/{0}/.config/site_country_languages.setting"
                , distinctName
                );
            HttpRuntime.Cache.Remove(cacheKey2);

            ObjectHelper.XmlSerialize<Dictionary<string, string>>(rules, HostingEnvironment.MapPath(cacheKey));
        }

        public static Dictionary<int, string> LoadCountryLanguages(this cmSite site)
        {
            string cacheKey = string.Format(CultureInfo.InvariantCulture
                , "~/Views/{0}/.config/site_country_languages.setting"
                , site.DistinctName
                );
            Dictionary<int, string> languages = HttpRuntime.Cache[cacheKey] as Dictionary<int, string>;
            if (languages != null)
                return languages;

            languages = new Dictionary<int, string>();
            var countrylanguages = LoadCountryLanguages(site.DistinctName);
            foreach (var countrylanguage in countrylanguages)
            {
                var strs = countrylanguage.CountryIds.Split(',');
                foreach (var str in strs)
                {
                    int countryId;
                    if (int.TryParse(str, out countryId))
                    {
                        if (languages.ContainsKey(countryId))
                            continue;

                        languages.Add(countryId, countrylanguage.LanguageCode);
                    }
                }
            }
            HttpRuntime.Cache.Insert(cacheKey
                , languages
                , new CacheDependencyEx(new string[] { cacheKey }, true)
                , Cache.NoAbsoluteExpiration
                , Cache.NoSlidingExpiration
                , CacheItemPriority.NotRemovable
                , null
                );

            return languages;
        }

    }
}
