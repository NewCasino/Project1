using System;
using System.Linq;
using System.Reflection;
using System.Text.RegularExpressions;
using System.Web.Mvc;
using BLToolkit.DataAccess;
using CE.db;
using CE.db.Accessor;
using CE.DomainConfig;
using CE.Utils;
using GamMatrixAPI;

namespace CasinoEngine.Controllers
{
    [SystemAuthorize]
    public class ConfigurationController : Controller
    {
        //
        // GET: /Configuration/
        public ActionResult Index()
        {
            if (DomainManager.CurrentDomainID > 0)
            {
                DomainConfigAccessor dca = DomainConfigAccessor.CreateInstance<DomainConfigAccessor>();
                ceDomainConfigEx domain = dca.GetByDomainID(DomainManager.CurrentDomainID);
                return View(domain);
            }
            return View();
        }

        private ceDomainConfig EnsureDomainConfigExists()
        {
            SqlQuery<ceDomainConfig> query = new SqlQuery<ceDomainConfig>();
            ceDomainConfig config = query.SelectByKey(DomainManager.CurrentDomainID);
            if (config == null)
            {
                var domains = DomainManager.GetDomains();
                var domain = domains.First(d => d.DomainID == DomainManager.CurrentDomainID);
                config = new ceDomainConfig()
                {
                    ID = DomainManager.CurrentDomainID,
                    DomainID = DomainManager.CurrentDomainID,
                    ApiUsername = Regex.Replace( domain.Name, @"[^a-zA-Z0-9]", "_", RegexOptions.Compiled),
                    ApiWhitelistIP = "",
                    TopWinnersDaysBack = 30,
                    TopWinnersMaxRecords = 50,
                    TopWinnersMinAmount = 10.00M,
                    TopWinnersExcludeOtherOperators = false,
                    ScalableThumbnailWidth = 376,
                    ScalableThumbnailHeight = 250,
                    GameLoaderDomain = string.Empty,
                    GameResourceDomain = string.Empty,
                    Ins = DateTime.Now,
                };
                query.Insert(config);
            }
            return config;
        }

        [HttpPost]
        public JsonResult SaveApiCredentials(string apiUsername
            , string apiPassword
            , string apiWhitelistIP
            , string gameListChangedNotificationUrl
            )
        {
            if (!DomainManager.AllowEdit())
            {
                throw new Exception("Data modified is not allowed");
            }
            SqlQuery<ceDomainConfig> query = new SqlQuery<ceDomainConfig>();

            ceDomainConfig config = EnsureDomainConfigExists();
            config.ApiUsername = apiUsername;
            if( !string.IsNullOrWhiteSpace(apiPassword) )
                config.ApiPassword = apiPassword.MD5Hash();
            config.ApiWhitelistIP = apiWhitelistIP;
            config.GameListChangedNotificationUrl = gameListChangedNotificationUrl;
            query.Update(config);

            CacheManager.ClearCache(Constant.DomainCacheKey);

            return this.Json(new { @success = true });
        }


        [HttpPost]
        public JsonResult SaveWcfApiCredentials(string wcfApiUsername, string wcfApiPassword)
        {
            if (!DomainManager.AllowEdit())
            {
                throw new Exception("Data modified is not allowed");
            }
            SqlQuery<ceDomainConfig> query = new SqlQuery<ceDomainConfig>();

            ceDomainConfig config = EnsureDomainConfigExists();
            config.WcfApiUsername = wcfApiUsername;
            config.WcfApiPassword = wcfApiPassword;
            query.Update(config);

            CacheManager.ClearCache(Constant.DomainCacheKey);
            return this.Json(new { @success = true });
        }


        [HttpPost]
        public JsonResult SaveVendors(VendorID[] enabledVendors
            , VendorID[] liveCasinoVendors
            , string cashierUrl
            , string lobbyUrl
            , string accountHistoryUrl
            , string mobileCashierUrl
            , string mobileLobbyUrl
            , string mobileAccountHistoryUrl
            , string domainDefaultCurrencyCode
            , string googleAnalyticsAccount
            , string gameLoaderDomain
            , string gameResourceDomain
            , short newStatusCasinoGameExpirationDays
            , short newStatusLiveCasinoGameExpirationDays
            )
        {
            if (!DomainManager.AllowEdit())
            {
                throw new Exception("Data modified is not allowed");
            }
            CasinoVendorAccessor.SetEnabledVendors(DomainManager.CurrentDomainID
                , Constant.SystemDomainID
                , enabledVendors
                , liveCasinoVendors
                );

            if (enabledVendors != null && enabledVendors.Length > 0)
            {
                SqlQuery<ceDomainConfig> query = new SqlQuery<ceDomainConfig>();

                ceDomainConfig config = EnsureDomainConfigExists();

                config.MobileCashierUrl = mobileCashierUrl;
                config.MobileLobbyUrl = mobileLobbyUrl;
                config.MobileAccountHistoryUrl = mobileAccountHistoryUrl;
                config.CashierUrl = cashierUrl;
                config.LobbyUrl = lobbyUrl;
                config.AccountHistoryUrl = accountHistoryUrl;
                config.DomainDefaultCurrencyCode = domainDefaultCurrencyCode;
                config.GoogleAnalyticsAccount = googleAnalyticsAccount;
                config.GameLoaderDomain = gameLoaderDomain;
                config.GameResourceDomain = gameResourceDomain;
                config.NewStatusCasinoGameExpirationDays = newStatusCasinoGameExpirationDays;
                config.NewStatusLiveCasinoGameExpirationDays = newStatusLiveCasinoGameExpirationDays;

                query.Update(config);
            }

            //CacheManager.ClearCache(Constant.GameListCachePrefix);
            //CacheManager.ClearCache(Constant.JackpotListCachePrefix);
            //CacheManager.ClearCache(Constant.VendorListCachePrefix);
            //CacheManager.ClearCache(Constant.DomainCacheKey);
            return this.Json(new { @success = true });
        }


        [HttpPost]
        public JsonResult SaveDomainConfig(string typeName)
        {
            if (!DomainManager.AllowEdit())
            {
                throw new Exception("Data modified is not allowed");
            }
            Type type = null;
            foreach (Assembly assembly in AppDomain.CurrentDomain.GetAssemblies())
            {
                type = assembly.GetType(typeName);
                if (type != null)
                    break;
            }
            if (type == null)
                throw new CeException("Can not find type [{0}]", typeName);
            DomainConfigAccessor dca = DomainConfigAccessor.CreateInstance<DomainConfigAccessor>();
            FieldInfo[] fields = type.GetFields(BindingFlags.Public | BindingFlags.Static);
            foreach (FieldInfo field in fields)
            {
                ConfigAttribute attr = field.GetCustomAttribute<ConfigAttribute>();
                if (attr == null)
                    continue;

                string itemName = field.GetValue(null) as string;
                string itemValue = Request.Form[itemName];
                string countrySpecificCfg = null;
                if (itemValue == null)
                    continue;

                if (attr.AllowCountrySpecificValue)
                {
                    countrySpecificCfg = Request.Form[string.Format("{0}_CountrySpecificCfg", itemName)];
                }

                dca.SetConfigurationItemValue(DomainManager.CurrentDomainID, itemName, itemValue, countrySpecificCfg);
            }
            ceDomainConfigEx.ClearCfgCache(DomainManager.CurrentDomainID);
            return this.Json(new { @success = true });
        }

        [HttpPost]
        public JsonResult SaveTopWinnersDefaultSetting(int topWinnersDaysBack
            , int topWinnersMaxRecords
            , decimal topWinnersMinAmount
            , bool topWinnersExcludeOtherOperators
            )
        {
            if (!DomainManager.AllowEdit())
            {
                throw new Exception("Data modified is not allowed");
            }
            SqlQuery<ceDomainConfig> query = new SqlQuery<ceDomainConfig>();

            ceDomainConfig config = EnsureDomainConfigExists();
            config.TopWinnersDaysBack = topWinnersDaysBack;
            config.TopWinnersExcludeOtherOperators = topWinnersExcludeOtherOperators;
            config.TopWinnersMaxRecords = topWinnersMaxRecords;
            config.TopWinnersMinAmount = topWinnersMinAmount;
            query.Update(config);

            CacheManager.ClearCache(Constant.TopWinnersCachePrefix);
            CacheManager.ClearCache(Constant.DomainCacheKey);
            return this.Json(new { @success = true });
        }

        [HttpPost]
        public JsonResult SaveRecentWinnersDefaultSetting(int recentWinnersMaxRecords
            , decimal recentWinnersMinAmount
            , bool recentWinnersExcludeOtherOperators
            , bool recentWinnersReturnDistinctUserOnly
            )
        {
            if (!DomainManager.AllowEdit())
            {
                throw new Exception("Data modified is not allowed");
            }
            SqlQuery<ceDomainConfig> query = new SqlQuery<ceDomainConfig>();

            ceDomainConfig config = EnsureDomainConfigExists();
            config.RecentWinnersExcludeOtherOperators = recentWinnersExcludeOtherOperators;
            config.RecentWinnersMaxRecords = recentWinnersMaxRecords;
            config.RecentWinnersMinAmount = recentWinnersMinAmount;
            config.RecentWinnersReturnDistinctUserOnly = recentWinnersReturnDistinctUserOnly;
            query.Update(config);

            CacheManager.ClearCache(Constant.DomainCacheKey);
            return this.Json(new { @success = true });
        }

        //[HttpPost]
        //public JsonResult SaveLastPlayedGamesDefaultSetting(int lastPlayedGamesMaxRecords
        //    , bool lastPlayedGamesIsDuplicated
        //    , int lastPlayedGamesLastDayNum 
        //    )
        //{
        //    SqlQuery<ceDomainConfig> query = new SqlQuery<ceDomainConfig>();

        //    ceDomainConfig config = EnsureDomainConfigExists();
        //    config.LastPlayedGamesMaxRecords = lastPlayedGamesMaxRecords;
        //    config.LastPlayedGamesIsDuplicated = lastPlayedGamesIsDuplicated;
        //    config.LastPlayedGamesLastDayNum = lastPlayedGamesLastDayNum; 
        //    query.Update(config);

        //    CacheManager.ClearCache(Constant.DomainCacheKey);
        //    return this.Json(new { @success = true });
        //}

        [HttpPost]
        public JsonResult SavePlayerCasinoConfigurationDefaultSetting(
            int lastPlayedGamesMaxRecords
            , bool lastPlayedGamesIsDuplicated
            , int lastPlayedGamesLastDayNum 
            ,
            int mostPlayedGamesLastDayNum
            , int mostPlayedGamesMinRoundCounts ,
            bool playerBiggestWinGamesIsDuplicated
            , int playerBiggestWinGamesLastDayNum
            , decimal playerBiggestWinGamesMinWinEURAmounts 
            )
        {
            if (!DomainManager.AllowEdit())
            {
                throw new Exception("Data modified is not allowed");
            }
            SqlQuery<ceDomainConfig> query = new SqlQuery<ceDomainConfig>();

            ceDomainConfig config = EnsureDomainConfigExists();
            config.LastPlayedGamesMaxRecords = lastPlayedGamesMaxRecords;
            config.LastPlayedGamesIsDuplicated = lastPlayedGamesIsDuplicated;
            config.LastPlayedGamesLastDayNum = lastPlayedGamesLastDayNum; 
            config.MostPlayedGamesLastDayNum = mostPlayedGamesLastDayNum;
            config.MostPlayedGamesMinRoundCounts = mostPlayedGamesMinRoundCounts;
            config.PlayerBiggestWinGamesIsDuplicated = playerBiggestWinGamesIsDuplicated;
            config.PlayerBiggestWinGamesLastDayNum = playerBiggestWinGamesLastDayNum;
            config.PlayerBiggestWinGamesMinWinEURAmounts = playerBiggestWinGamesMinWinEURAmounts;
            query.Update(config);

            CacheManager.ClearCache(Constant.DomainCacheKey);
            return this.Json(new { @success = true });
        }

        //[HttpPost]
        //public JsonResult SaveMostPopularGamesDefaultSetting(int mostPopularGamesLastDayNum
        //    , bool mostPopularGamesIsGameRounds 
        //    )
        //{
        //    SqlQuery<ceDomainConfig> query = new SqlQuery<ceDomainConfig>();

        //    ceDomainConfig config = EnsureDomainConfigExists();
        //    config.MostPopularGamesLastDayNum = mostPopularGamesLastDayNum;
        //    config.MostPopularGamesIsGameRounds = mostPopularGamesIsGameRounds;
        //    query.Update(config);

        //    CacheManager.ClearCache(Constant.DomainCacheKey);
        //    return this.Json(new { @success = true });
        //}

        //[HttpPost]
        //public JsonResult SavePlayerBiggestWinGamesDefaultSetting(bool playerBiggestWinGamesIsDuplicated
        //    , int playerBiggestWinGamesLastDayNum
        //    , decimal playerBiggestWinGamesMinWinEURAmounts 
        //    )
        //{
        //    SqlQuery<ceDomainConfig> query = new SqlQuery<ceDomainConfig>();

        //    ceDomainConfig config = EnsureDomainConfigExists();
        //    config.PlayerBiggestWinGamesIsDuplicated = playerBiggestWinGamesIsDuplicated;
        //    config.PlayerBiggestWinGamesLastDayNum = playerBiggestWinGamesLastDayNum;
        //    config.PlayerBiggestWinGamesMinWinEURAmounts = playerBiggestWinGamesMinWinEURAmounts;
        //    query.Update(config);

        //    CacheManager.ClearCache(Constant.DomainCacheKey);
        //    return this.Json(new { @success = true });
        //}

        [HttpPost]
        public JsonResult SavePopularitySetting(bool popularityExcludeOtherOperators
            , PopularityCalculationMethod popularityCalculationMethod
            , int popularityDaysBack
            , bool popularityNotByCountry
            , string popularityConfigurationByCountry
            )
        {
            if (!DomainManager.AllowEdit())
            {
                throw new Exception("Data modified is not allowed");
            }
            SqlQuery<ceDomainConfig> query = new SqlQuery<ceDomainConfig>();

            ceDomainConfig config = EnsureDomainConfigExists();
            config.PopularityExcludeOtherOperators = popularityExcludeOtherOperators;
            config.PopularityCalculationMethod = popularityCalculationMethod;
            config.PopularityDaysBack = popularityDaysBack;
            config.PopularityNotByCountry = popularityNotByCountry;
            config.PopularityConfigurationByCountry = popularityConfigurationByCountry;
            query.Update(config);

            CacheManager.ClearCache(Constant.DomainCacheKey);
            return this.Json(new { @success = true });
        }

        [HttpPost]
        public JsonResult SaveScalableThumbnailSetting(bool enableScalableThumbnail
            , int scalableThumbnailWidth
            , int scalableThumbnailHeight
            )
        {
            if (!DomainManager.AllowEdit())
            {
                throw new Exception("Data modified is not allowed");
            }
            SqlQuery<ceDomainConfig> query = new SqlQuery<ceDomainConfig>();

            ceDomainConfig config = EnsureDomainConfigExists();
            config.EnableScalableThumbnail = enableScalableThumbnail;
            config.ScalableThumbnailWidth = scalableThumbnailWidth;
            config.ScalableThumbnailHeight = scalableThumbnailHeight;
            query.Update(config);

            CE.BackendThread.ScalableThumbnailProcessor.Begin();
            CacheManager.ClearCache(Constant.DomainCacheKey);
            return this.Json(new { @success = true });
        }

        [HttpPost]
        public JsonResult SaveRecommendationConfig(string recommendationExcludeGames
            ,int recommendationMaxPlayerRecords
            , int recommendationMaxGameRecords)
        {
            if (!DomainManager.AllowEdit())
            {
                throw new Exception("Data modified is not allowed");
            }
            SqlQuery<ceDomainConfig> query = new SqlQuery<ceDomainConfig>();

            ceDomainConfig config = EnsureDomainConfigExists();
            config.RecommendationExcludeGames = recommendationExcludeGames;
            config.RecommendationMaxPlayerRecords = recommendationMaxPlayerRecords;
            config.RecommendationMaxGameRecords = recommendationMaxGameRecords;
            query.Update(config);

            CE.BackendThread.ScalableThumbnailProcessor.Begin();
            CacheManager.ClearCache(Constant.DomainCacheKey);
            return this.Json(new { @success = true });
        }


        public JsonResult GetDataItems(string type)
        {
            DataDictionaryAccessor dda = DataDictionaryAccessor.CreateInstance<DataDictionaryAccessor>();
            var items = dda.GetByType(type);

            return this.Json(new { @success = true, @items = items }, JsonRequestBehavior.AllowGet);
        }

        public JsonResult AddDataItem(string type, string text)
        {
            if (!DomainManager.AllowEdit())
            {
                throw new Exception("Data modified is not allowed");
            }
            SqlQuery<ceDataItem> query = new SqlQuery<ceDataItem>();

            if (!string.IsNullOrWhiteSpace(text))
            {
                ceDataItem dataItem = new ceDataItem();
                dataItem.DomainID = 0;
                dataItem.Text = text.Trim();
                dataItem.Ins = DateTime.Now;
                dataItem.Type = type;
                dataItem.DataValue = Regex.Replace(text, @"[^\w]", string.Empty, RegexOptions.Compiled).ToUpperInvariant();
                query.Insert(dataItem);
            }

            return this.Json(new { @success = true }, JsonRequestBehavior.AllowGet);
        }

        public JsonResult RemoveDataItem(string type, long id)
        {
            if (!DomainManager.AllowEdit())
            {
                throw new Exception("Data modified is not allowed");
            }
            DataDictionaryAccessor dda = DataDictionaryAccessor.CreateInstance<DataDictionaryAccessor>();
            var item = dda.GetById(id);

            SqlQuery<ceDataItem> query = new SqlQuery<ceDataItem>();
            query.DeleteByKey(id);

            ChangeLogAccessor cla = ChangeLogAccessor.CreateInstance<ChangeLogAccessor>();
            cla.BackupChangeLog(CurrentUserSession.UserSessionID, CurrentUserSession.UserID, "CeDataDictionary", id, DateTime.Now, "DELETE", Newtonsoft.Json.JsonConvert.SerializeObject(item), null);

            return this.Json(new { @success = true }, JsonRequestBehavior.AllowGet);
        }
    }
}
