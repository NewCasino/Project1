using System;
using System.Collections.Generic;
using System.Web;
using BLToolkit.DataAccess;
using BLToolkit.Mapping;
using CE.db.Accessor;
using Newtonsoft.Json;

namespace CE.db
{
    /// <summary>
    ///  ceDomainConfig table
    /// </summary>
    [Serializable]
    public class ceDomainConfig
    {
        [PrimaryKey]
        public long ID { get; set; }

        public long DomainID { get; set; }

        [DefaultValue("NEWID()")]
        public string ApiUsername { get; set; }

        public string ApiPassword { get; set; }

        public string ApiWhitelistIP { get; set; }

        public string GameListChangedNotificationUrl { get; set; }

        public string WcfApiUsername { get; set; }

        public string WcfApiPassword { get; set; }

        public string MobileCashierUrl { get; set; }

        public string MobileLobbyUrl { get; set; }

        public string MobileAccountHistoryUrl { get; set; }

        public string AccountHistoryUrl { get; set; }

        public string CashierUrl { get; set; }

        public string LobbyUrl { get; set; }

        public string DomainDefaultCurrencyCode { get; set; }

        public string GoogleAnalyticsAccount { get; set; }

        public string GameLoaderDomain { get; set; }

        public string GameResourceDomain { get; set; }

        [DefaultValue("30")]
        public int NewStatusCasinoGameExpirationDays { get; set; }

        [DefaultValue("30")]
        public int NewStatusLiveCasinoGameExpirationDays { get; set; }


        [DefaultValue("7")]
        public int TopWinnersDaysBack { get; set; }

        [DefaultValue("50")]
        public int TopWinnersMaxRecords { get; set; }

        public decimal TopWinnersMinAmount { get; set; }

        public bool TopWinnersExcludeOtherOperators { get; set; }

        public string RecentWinnersFilteredVendorIDs { get; set; }

        public string RecentWinnersFilteredGameCodes { get; set; }

        // true = include, false = exclusion
        [DefaultValue("0")]
        public bool RecentWinnersCountryFilterMode { get; set; }

        public string RecentWinnersCountryCodes { get; set; }

        [DefaultValue("10.0")]
        public decimal RecentWinnersMinAmount { get; set; }

        [DefaultValue("50")]
        public int RecentWinnersMaxRecords { get; set; }

        [DefaultValue("1")]
        public bool RecentWinnersExcludeOtherOperators { get; set; }

        [DefaultValue("1")]
        public bool RecentWinnersReturnDistinctUserOnly { get; set; }

        [DefaultValue("0")]
        public bool PopularityExcludeOtherOperators { get; set; }

        [DefaultValue("0")]
        public PopularityCalculationMethod PopularityCalculationMethod { get; set; }

        [DefaultValue("60")]
        public int PopularityDaysBack { get; set; }

        [DefaultValue("1")]
        public bool PopularityNotByCountry { get; set; }

        public string PopularityConfigurationByCountry { get; set; }

        [DefaultValue("0")]
        public bool EnableScalableThumbnail { get; set; }

        [DefaultValue("376")]
        public int ScalableThumbnailWidth { get; set; }

        [DefaultValue("250")]
        public int ScalableThumbnailHeight { get; set; }

        public string SupportEmailAddress { get; set; }

        [DefaultValue("GETDATE()")]
        public DateTime Ins { get; set; }

        public string MetadataUrl { get; set; }

        public int TemplateID { get; set; }

        [DefaultValue("0")]
        public bool LastPlayedGamesIsDuplicated { get; set; }
        [DefaultValue("40")]
        public int LastPlayedGamesMaxRecords { get; set; }
        [DefaultValue("30")]
        public int LastPlayedGamesLastDayNum { get; set; }

        [DefaultValue("30")]
        public int MostPlayedGamesLastDayNum { get; set; }
        [DefaultValue("100")]
        public int MostPlayedGamesMinRoundCounts { get; set; }
        
        //[DefaultValue("30")]
        //public int MostPopularGamesLastDayNum { get; set; }
        //[DefaultValue("0")]
        //public bool MostPopularGamesIsGameRounds { get; set; }

        [DefaultValue("0")]
        public bool PlayerBiggestWinGamesIsDuplicated { get; set; }
        [DefaultValue("30")]
        public int PlayerBiggestWinGamesLastDayNum { get; set; }
        [DefaultValue("0")]
        public decimal PlayerBiggestWinGamesMinWinEURAmounts { get; set; }

        public string RecommendationExcludeGames { get; set; }

        [DefaultValue("50")]
        public int RecommendationMaxPlayerRecords { get; set; }

        [DefaultValue("50")]
        public int RecommendationMaxGameRecords { get; set; }

        private const string CACHE_KEY_PREFIX = "CE.db.ceDomainConfigEx.GetCfgCache.";
        private Dictionary<string, ceDomainConfigItem> GetCfgCache(long domainID)
        {
            string cacheKey = string.Format("{0}{1}", CACHE_KEY_PREFIX, this.DomainID);
            Dictionary<string, ceDomainConfigItem> items = HttpRuntime.Cache[cacheKey] as Dictionary<string, ceDomainConfigItem>;
            if (items == null)
            {
                DomainConfigAccessor dca = DomainConfigAccessor.CreateInstance<DomainConfigAccessor>();
                items = dca.GetConfigurationItemsByDomainID(domainID);
                CacheManager.AddCache(cacheKey, items);
            }
            return items;
        }

        /// <summary>
        /// Clear config cache
        /// </summary>
        /// <param name="domainID"></param>
        public static void ClearCfgCache(long domainID)
        {
            string prefixCacheKey = string.Format("{0}{1}", CACHE_KEY_PREFIX, domainID);
            CacheManager.ClearCache(prefixCacheKey);
        }

        /// <summary>
        /// Query the configuration item value
        /// </summary>
        /// <param name="domain"></param>
        /// <param name="itemName"></param>
        /// <returns></returns>
        public string GetCfg(string itemName)
        {
            Dictionary<string, ceDomainConfigItem> items = GetCfgCache(this.DomainID);
            ceDomainConfigItem item;
            if (items.TryGetValue(itemName, out item))
                return item.ItemValue;

            return string.Empty;
        }

        public string GetCountrySpecificCfg(string itemName, params string[] countryCodes)
        {
            Dictionary<string, ceDomainConfigItem> items = GetCfgCache(this.DomainID);
            ceDomainConfigItem item;
            if (items.TryGetValue(itemName, out item))
            {
                if (countryCodes != null && !string.IsNullOrWhiteSpace(item.CountrySpecificCfg))
                {
                    try
                    {
                        Dictionary<string, string> dic = JsonConvert.DeserializeObject<Dictionary<string, string>>(item.CountrySpecificCfg);
                        foreach (string countryCode in countryCodes)
                        {
                            string value;
                            if (dic.TryGetValue(countryCode, out value))
                                return value;
                        }
                    }
                    catch
                    {
                    }
                }
                return item.ItemValue;
            }

            return string.Empty;
        }

        public Dictionary<string, PopularityConfigurationByCountry> GetPopularityConfigurationByCountry()
        {
            try
            {
                if (string.IsNullOrWhiteSpace(this.PopularityConfigurationByCountry))
                    return new Dictionary<string, PopularityConfigurationByCountry>();

                return Newtonsoft.Json.JsonConvert.DeserializeObject<Dictionary<string, PopularityConfigurationByCountry>>(this.PopularityConfigurationByCountry);
            }
            catch
            {
                return new Dictionary<string, PopularityConfigurationByCountry>();
            }
        }
    }


    public enum PopularityCalculationMethod : int
    {
        ByTimes,
        ByTurnover,
    }

}
