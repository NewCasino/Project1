using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using CM.Content;
using CM.db;
using CM.Sites;

namespace Finance
{
    public sealed class LanguageManager
    {
        public static Language[] GetLanguages(string distinctName)
        {
            var languages = MultilingualMgr.LoadFromFile(distinctName);
            var countryLanguages = MultilingualMgr.LoadCountryLanguages(distinctName);
            var result = new Language[languages.Length];
            for (var i = 0; i < languages.Length; i++)
            {
                result[i] = new Language();
                result[i].LanguageCode = languages[i].LanguageCode;
                result[i].CountryFlagName = languages[i].CountryFlagName;
                result[i].DisplayName = languages[i].DisplayName;

                var item = countryLanguages.FirstOrDefault(c => c.LanguageCode == languages[i].LanguageCode);
                if (item != null)
                {
                    //result[i].IsExclude = item.IsExclude;
                    result[i].CountryIds = item.CountryIds;
                }

                //result[i].Countries = FormatCountryList(distinctName, result[i].IsExclude, result[i].CountryIds);
                result[i].Countries = FormatCountryList(distinctName, false, result[i].CountryIds);
            }

            return result;
        }

        public static void SaveLanguages(string distinctName, Language[] languages)
        {
            var languageinfos = new LanguageInfo[languages.Length];
            var countrylanguageinfos = new CountryLanguageInfo[languages.Length];

            for (var i = 0; i < languages.Length; i++)
            {
                languageinfos[i] = new LanguageInfo();
                languageinfos[i].LanguageCode = languages[i].LanguageCode;
                languageinfos[i].DisplayName = languages[i].DisplayName;
                languageinfos[i].CountryFlagName = languages[i].CountryFlagName;

                countrylanguageinfos[i] = new CountryLanguageInfo();
                countrylanguageinfos[i].LanguageCode = languages[i].LanguageCode;
                //countrylanguageinfos[i].IsExclude = languages[i].IsExclude;
                countrylanguageinfos[i].CountryIds = languages[i].CountryIds;
            }

            CheckCountryLanguages(distinctName, countrylanguageinfos);

            string relativePath = "/.config/languages.setting";
            string name = "Languages";
            cmSite site = SiteManager.GetSiteByDistinctName(distinctName);

            Language[] oldLanguages = GetLanguages(distinctName);
            Revisions.BackupIfNotExists<Language[]>(site, oldLanguages, relativePath, name);

            MultilingualMgr.Save(distinctName, languageinfos);
            MultilingualMgr.SaveCountryLanguages(distinctName, countrylanguageinfos);

            Revisions.Backup<Language[]>(site, languages, relativePath, name);
        }

        private static string FormatCountryList(string distinctName, bool isExclude, string countryIds)
        {
            var ids = new List<int>();
            if (!string.IsNullOrWhiteSpace(countryIds))
            {
                var strs = countryIds.Split(',');
                foreach (var str in strs)
                {
                    int id;
                    if (int.TryParse(str, out id))
                        ids.Add(id);
                }
            }

            List<CountryInfo> countries = CountryManager.GetAllCountries(distinctName);

            StringBuilder text = new StringBuilder();
            if (isExclude)
            {
                if (ids.Count == 0)
                {
                    text.Append("All");
                }
                else
                {
                    text.Append("Exclude ");
                }
            }
            else
            {
                if (ids.Count == 0)
                {
                    text.Append("None");
                }
            }

            foreach (int countryID in ids)
            {
                CountryInfo country = countries.FirstOrDefault(c => c.InternalID == countryID);
                if (country != null)
                    text.AppendFormat(CultureInfo.InvariantCulture, " {0} ,", country.EnglishName);
            }
            if (ids.Count > 0)
                text.Remove(text.Length - 1, 1);

            return text.ToString();
        }

        private static void CheckCountryLanguages(string distinctName, CountryLanguageInfo[] countrylanguages)
        {
            var allCountries = CountryManager.GetAllCountries(distinctName);
            Dictionary<string, IList<int>> dic = new Dictionary<string, IList<int>>();
            foreach (var item in countrylanguages)
            {
                if (string.IsNullOrWhiteSpace(item.CountryIds))
                    continue;

                List<int> lstIds = new List<int>();
                var ids = item.CountryIds.Split(',');
                foreach (var id in ids)
                    lstIds.Add(Convert.ToInt32(id));

                //if (item.IsExclude)
                //    lstIds = allCountries.Where(c => !lstIds.Contains(c.InternalID)).Select(c => c.InternalID).ToList();

                dic.Add(item.LanguageCode, lstIds);
            }

            foreach (var country in allCountries)
            {
                if (dic.Count(d => d.Value.Contains(country.InternalID)) > 1)
                    throw new Exception(string.Format("You can't assign more than one language to the special country '{0}'", country.EnglishName));
            }
        }

    }
}
