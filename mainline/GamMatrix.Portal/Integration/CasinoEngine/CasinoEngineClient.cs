using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Configuration;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Net;
using System.Threading;
using System.Web;
using System.Web.Hosting;
using System.Xml.Linq;
using System.Threading.Tasks;
using System.Collections;
using System.Web.Caching;
using System.Runtime.Serialization;

using CM.Content;
using CM.db;
using CM.Sites;
using CM.State;
using GamMatrixAPI;

using Newtonsoft.Json;

namespace CasinoEngine
{
    [DataContract]
    [Serializable]
    public sealed class VendorInfo
    {
        [DataMember(Name = "vendorID")]
        public string VendorIDString { get; set; }

        [DataMember(Name = "bonusDeduction")]
        public decimal BonusDeduction { get; set; }

        [DataMember(Name = "restrictedTerritories")]
        public List<string> RestrictedTerritoryCountryCodes { get; set; }

        [IgnoreDataMember]
        public VendorID VendorID
        {
            get
            {
                VendorID vendor;
                if (Enum.TryParse<VendorID>(this.VendorIDString, out vendor))
                    return vendor;

                return VendorID.Unknown;
            }
        }

        [IgnoreDataMember]
        public List<int> RestrictedTerritories { get; internal set; }
    }

    [DataContract]
    [Serializable]
    public sealed class ContentProvider
    {
        [DataMember(Name = "id")]
        public string ID { get; set; }

        [DataMember(Name = "logo")]
        public string Logo { get; set; }
    }

    /// <summary>
    /// Summary description for CasinoEngineFeeds
    /// </summary>
    public static class CasinoEngineClient
    {
        private static Dictionary<string, string> _CE_GAMELIST_HASHCODE = new Dictionary<string, string>();
        private static Dictionary<string, string> _CE_LIVETABLELIST_HASHCODE = new Dictionary<string, string>();
        private static readonly string _CE1_DOMAIN = ConfigurationManager.AppSettings["CasinoEngine1.Domain"];
        private static readonly string _CE2_DOMAIN = ConfigurationManager.AppSettings["CasinoEngine2.Domain"];

        #region private methods
        public static FeedsType GetFeedsType(cmSite site)
        {
            string relativePath = string.Format("~/Views/{0}/.config/ce_feeds_type.setting", site.DistinctName);
            string cacheKey = string.Format("{0}_FeedType", site.DistinctName);
            FeedsType? cached = HttpRuntime.Cache[cacheKey] as FeedsType?;
            /*if (cached != null)
                return cached.Value;*/

            using (BLToolkit.Data.DbManager dbManager = new BLToolkit.Data.DbManager())
            {
                CM.db.Accessor.SiteAccessor da = BLToolkit.DataAccess.DataAccessor.CreateInstance<CM.db.Accessor.SiteAccessor>(dbManager);

                cached = (FeedsType)da.GetFeedType(site.DomainID);

                string filePath = HostingEnvironment.MapPath(relativePath);
                cached = ObjectHelper.BinaryDeserialize<FeedsType>(filePath, cached.Value);

                HttpRuntime.Cache.Insert(cacheKey
                        , cached
                        , new CacheDependency(filePath)
                        , Cache.NoAbsoluteExpiration
                        , Cache.NoSlidingExpiration
                        );

                return cached.Value;
            }

        }

        private static string GetBaseUrl()
        {
            return string.Format(ConfigurationManager.AppSettings["CasinoEngine2.BaseUrl"]);
        }

        private static string GetCasinoGameDomain(cmSite site)
        {
            return GetFeedsType(site) == FeedsType.CE1Feeds ? _CE1_DOMAIN : _CE2_DOMAIN;
        }

        private static string GetGameInfoUrl(cmSite site, string gameID, string language)
        {
            return string.Format(ConfigurationManager.AppSettings["CasinoEngine.GameInfoUrlFormat"]
                , GetCasinoGameDomain(site)
                , HttpUtility.UrlEncode(Metadata.Get(site, "/Metadata/Settings.CasinoEngine_OperatorKey", null))
                , HttpUtility.UrlEncode(gameID)
                , HttpUtility.UrlEncode(language)
                );
        }

        private static string GetFrequentPlayerPointsUrl(cmSite site, string sessionID)
        {
            return string.Format(ConfigurationManager.AppSettings["CasinoEngine.GetFrequentPlayerPoints"]
                , GetCasinoGameDomain(site)
                , HttpUtility.UrlEncode(Metadata.Get(site, "/Metadata/Settings.CasinoEngine_OperatorKey", null))
                , HttpUtility.UrlEncode(Metadata.Get(site, "/Metadata/Settings.CasinoEngine_ApiPassword", null))
                , HttpUtility.UrlEncode(sessionID)
                );
        }

        private static string ClaimFrequentPlayerPointsUrl(cmSite site, string sessionID)
        {
            return string.Format(ConfigurationManager.AppSettings["CasinoEngine.ClaimFrequentPlayerPoints"]
                , GetCasinoGameDomain(site)
                , HttpUtility.UrlEncode(Metadata.Get(site, "/Metadata/Settings.CasinoEngine_OperatorKey", null))
                , HttpUtility.UrlEncode(Metadata.Get(site, "/Metadata/Settings.CasinoEngine_ApiPassword", null))
                , HttpUtility.UrlEncode(sessionID)
                );
        }

        private static string FindCountryCode(int countryId)
        {
            var country = CountryManager.GetAllCountries().FirstOrDefault(c => c.InternalID == countryId);
            if (country != null)
                return country.ISO_3166_Alpha2Code;
            return string.Empty;
        }

        private static string GetGameRecommendedGamesUrl(cmSite site, IEnumerable<string> gameIds, Platform platForm)
        {
            return string.Format(ConfigurationManager.AppSettings["CasinoEngine.GameRecommendedUrlFormat"]
                , GetCasinoGameDomain(site)
                , HttpUtility.UrlEncode(Metadata.Get(site, "/Metadata/Settings.CasinoEngine_OperatorKey", null))
                , HttpUtility.UrlEncode(string.Join(",", gameIds))
                , HttpUtility.UrlEncode(platForm.ToString())
                , HttpUtility.UrlEncode(FindCountryCode(CustomProfile.Current.UserCountryID))
                , HttpUtility.UrlEncode(FindCountryCode(CustomProfile.Current.IpCountryID))
                );
        }

        private static string GetUserRecommendedGamesUrl(cmSite site, Platform platForm)
        {
            return string.Format(ConfigurationManager.AppSettings["CasinoEngine.UserRecommendedUrlFormat"]
               , GetCasinoGameDomain(site)
               , HttpUtility.UrlEncode(Metadata.Get(site, "/Metadata/Settings.CasinoEngine_OperatorKey", null))
               , HttpUtility.UrlEncode(CustomProfile.Current.SessionID)
               , HttpUtility.UrlEncode(platForm.ToString())
               );
        }
        #endregion

        /// <summary>
        /// Returns the enabled LiveCasino vendors
        /// </summary>
        /// <param name="site">the cmSite object</param>
        /// <param name="useCache">true to get from cache</param>
        /// <returns>VendorID[]</returns>
        public static VendorID[] GetEnabledLiveCasinoVendors(cmSite site = null, bool useCache = true)
        {
            if (site == null)
                site = SiteManager.Current;

            if (string.Equals(site.DistinctName, "Shared", StringComparison.InvariantCultureIgnoreCase) ||
                string.Equals(site.DistinctName, "MobileShared", StringComparison.InvariantCultureIgnoreCase))
                return GlobalConstant.AllLiveCasinoVendors;

            var enabledLiveVendors = GetVendors(site, useCache).Select(v => v.VendorID).Intersect(GlobalConstant.AllLiveCasinoVendors);
            return enabledLiveVendors.ToArray();
        }

        /// <summary>
        /// Returns the enabled vendors
        /// </summary>
        /// <param name="site">the cmSite object</param>
        /// <param name="useCache">true to get from cache</param>
        /// <returns>VendorID[]</returns>
        public static VendorID[] GetEnabledVendors(cmSite site = null, bool useCache = true)
        {
            if (site == null)
                site = SiteManager.Current;

            if (string.Equals(site.DistinctName, "Shared", StringComparison.InvariantCultureIgnoreCase) ||
                string.Equals(site.DistinctName, "MobileShared", StringComparison.InvariantCultureIgnoreCase))
                return GlobalConstant.AllVendors;

            return GetVendors(site, useCache).Select(v => v.VendorID).ToArray();
        }

        public static List<VendorInfo> GetVendors(cmSite site = null, bool useCache = true, bool forceUpdate = false)
        {
            if (site == null)
                site = SiteManager.Current;

            string cacheKey = string.Format(CacheKeyFormat.Vendors, site.DomainID);
            List<VendorInfo> cached = HttpRuntime.Cache[cacheKey] as List<VendorInfo>;
            if (cached == null)
            {
                int retry = 0;
                do
                {
                    try
                    {
                        List<CountryInfo> countries = CountryManager.GetAllCountries(site.DistinctName);

                        string path = Path.Combine(HostingEnvironment.MapPath("~/App_Data/")
                                    , ".casino"
                                    , site.DomainID.ToString(CultureInfo.InvariantCulture)
                                    , "vendors.json"
                                    );
                        string json = WinFileIO.ReadWithoutLock(path);
                        if (!string.IsNullOrWhiteSpace(json))
                        {
                            cached = JsonConvert.DeserializeObject<List<VendorInfo>>(json);
                            foreach (VendorInfo vendorInfo in cached)
                            {
                                vendorInfo.RestrictedTerritories = new List<int>();
                                if (vendorInfo.RestrictedTerritoryCountryCodes != null)
                                {
                                    foreach (string territory in vendorInfo.RestrictedTerritoryCountryCodes)
                                    {
                                        CountryInfo country = countries.FirstOrDefault(c => string.Equals(c.ISO_3166_Alpha2Code, territory, StringComparison.InvariantCultureIgnoreCase));
                                        if (country != null)
                                            vendorInfo.RestrictedTerritories.Add(country.InternalID);
                                    }
                                }
                            }
                            SetCache(cacheKey, cached);
                        }
                    }
                    catch (Exception ex)
                    {
                        Logger.Exception(ex);
                    }
                }
                while (cached == null && (++retry) < 3);

                if (cached == null || cached.Count == 0)
                    throw new Exception(string.Format("Vendor is not ready[{0}]", cached == null ? "null" : "0"));
            }

            return cached;
        }

        /// <summary>
        /// Get all the live casino tables for current operator
        /// </summary>
        /// <param name="site"></param>
        /// <param name="useCache"></param>
        /// <returns></returns>
        public static Dictionary<string, LiveCasinoTable> GetLiveCasinoTables(cmSite site = null, bool useCache = true, bool forceUpdate = false)
        {
            if (site == null)
                site = SiteManager.Current;

            string cacheKey = string.Format(CacheKeyFormat.Tables, site.DomainID);
            Dictionary<string, LiveCasinoTable> cached = HttpRuntime.Cache[cacheKey] as Dictionary<string, LiveCasinoTable>;
            if (cached == null)
            {
                int retry = 0;
                do
                {
                    try
                    {
                        string path = Path.Combine(HostingEnvironment.MapPath("~/App_Data/")
                                    , ".casino"
                                    , site.DomainID.ToString(CultureInfo.InvariantCulture)
                                    , "tables.json"
                                    );
                        string json = WinFileIO.ReadWithoutLock(path);
                        if (!string.IsNullOrWhiteSpace(json))
                        {
                            cached = JsonConvert.DeserializeObject<Dictionary<string, LiveCasinoTable>>(json);
                            SetCache(cacheKey, cached);
                        }
                    }
                    catch
                    {

                    }
                }
                while (cached == null && (++retry) < 3);

                if (cached == null || cached.Count == 0)
                    throw new Exception(string.Format("Live casino table is not ready[{0}]", cached == null ? "null" : "0"));
            }

            return cached;
        }// GetLiveCasinoTables

        /// <summary>
        /// Get all the games for current operator
        /// </summary>
        /// <param name="site"></param>
        /// <param name="useCache"></param>
        /// <returns></returns>
        public static Dictionary<string, Game> GetGames(cmSite site = null, bool useCache = true, bool forceUpdate = false)
        {
            if (site == null)
                site = SiteManager.Current;

            string cacheKey = string.Format(CacheKeyFormat.Games, site.DomainID);
            Dictionary<string, Game> cached = HttpRuntime.Cache[cacheKey] as Dictionary<string, Game>;
            if (cached == null)
            {
                int retry = 0;
                do
                {
                    try
                    {
                        string path = Path.Combine(HostingEnvironment.MapPath("~/App_Data/")
                                    , ".casino"
                                    , site.DomainID.ToString(CultureInfo.InvariantCulture)
                                    , "games.json"
                                    );
                        string json = WinFileIO.ReadWithoutLock(path);
                        if (!string.IsNullOrWhiteSpace(json))
                        {
                            cached = JsonConvert.DeserializeObject<Dictionary<string, Game>>(json);
                            SetCache(cacheKey, cached);
                        }
                    }
                    catch
                    {
                        
                    }
                }
                while (cached == null && (++retry) < 3);

                if (cached == null || cached.Count == 0)
                    throw new Exception(string.Format("Casino game is not ready[{0}]", cached == null ? "null" : "0"));
            }

            return cached;
        }// GetGames


        /// <summary>
        /// Get all jackpots
        /// </summary>
        /// <param name="site"></param>
        /// <param name="useCache"></param>
        /// <returns></returns>
        public static List<JackpotInfo> GetJackpots(cmSite site = null, bool useCache = true, bool forceUpdate = false)
        {
            if (site == null)
                site = SiteManager.Current;

            string cacheKey = string.Format(CacheKeyFormat.Jackpots, site.DomainID);
            List<JackpotInfo> cached = HttpRuntime.Cache[cacheKey] as List<JackpotInfo>;
            if (cached == null)
            {
                int retry = 0;
                do
                {
                    try
                    {
                        string path = Path.Combine(HostingEnvironment.MapPath("~/App_Data/")
                                    , ".casino"
                                    , site.DomainID.ToString(CultureInfo.InvariantCulture)
                                    , "jackpots.json"
                                    );
                        string json = WinFileIO.ReadWithoutLock(path);
                        if (!string.IsNullOrWhiteSpace(json))
                        {
                            List<JackpotInfo> jackpots = JsonConvert.DeserializeObject<List<JackpotInfo>>(json);
                            Dictionary<string, Game> games = CasinoEngineClient.GetGames(site);
                            cached = new List<JackpotInfo>();

                            foreach (JackpotInfo jackpot in jackpots)
                            {
                                jackpot.Games = new List<Game>();
                                if (jackpot.GameIDs != null && jackpot.GameIDs.Count > 0)
                                {
                                    foreach (string gameID in jackpot.GameIDs)
                                    {
                                        Game game;
                                        if (games.TryGetValue(gameID, out game))
                                            jackpot.Games.Add(game);
                                    }

                                    if (jackpot.Games.Any())
                                        cached.Add(jackpot);
                                }
                            }
                            SetCache(cacheKey, cached);
                        }
                    }
                    catch
                    {

                    }
                }
                while (cached == null && (++retry) < 3);

                if (cached == null || cached.Count == 0)
                    throw new Exception(string.Format("Jackpot is not ready[{0}]", cached == null ? "null" : "0"));
            }

            return ObjectHelper.DeepClone<List<JackpotInfo>>(cached);
        }// GetJackpots


        /// <summary>
        /// Get the top winners
        /// </summary>
        /// <param name="site"></param>
        /// <param name="useCache"></param>
        /// <returns></returns>
        public static List<WinnerInfo> GetTopWinners(cmSite site, bool isMobile, bool useCache = true, bool forceUpdate = false)
        {
            if (site == null)
                site = SiteManager.Current;

            string format = isMobile ? CacheKeyFormat.MobileTopWinners : CacheKeyFormat.DesktopTopWinners;
            string cacheKey = string.Format(format, site.DomainID);
            List<WinnerInfo> cached = HttpRuntime.Cache[cacheKey] as List<WinnerInfo>;
            if (cached == null)
            {
                int retry = 0;
                do
                {
                    try
                    {
                        string path = Path.Combine(HostingEnvironment.MapPath("~/App_Data/")
                                    , ".casino"
                                    , site.DomainID.ToString(CultureInfo.InvariantCulture)
                                    , isMobile ? "top-winners-mobile.json" : "top-winners-desktop.json"
                                    );
                        string json = WinFileIO.ReadWithoutLock(path);
                        if (!string.IsNullOrWhiteSpace(json))
                        {
                            cached = JsonConvert.DeserializeObject<List<WinnerInfo>>(json);
                            Dictionary<string, Game> games = CasinoEngineClient.GetGames(site);

                            foreach (WinnerInfo winner in cached)
                            {
                                if (!string.IsNullOrWhiteSpace(winner.GameID))
                                {
                                    Game game;
                                    if (games.TryGetValue(winner.GameID, out game))
                                        winner.Game = game;
                                }
                            }
                            SetCache(cacheKey, cached);
                        }
                    }
                    catch
                    {

                    }
                }
                while (cached == null && (++retry) < 3);

                if (cached == null || cached.Count == 0)
                    throw new Exception(string.Format("Top winner is not ready[{0}]", cached == null ? "null" : "0"));
            }

            return ObjectHelper.DeepClone<List<WinnerInfo>>(cached);
        }


        public static List<WinnerInfo> GetRecentWinners(cmSite site, bool isMobile, bool useCache = true, bool forceUpdate = false)
        {
            if (site == null)
                site = SiteManager.Current;

            string format = isMobile ? CacheKeyFormat.MobileRecentWinners : CacheKeyFormat.DesktopRecentWinners;
            string cacheKey = string.Format(format, site.DomainID);
            List<WinnerInfo> cached = HttpRuntime.Cache[cacheKey] as List<WinnerInfo>;
            if (cached == null)
            {
                int retry = 0;
                do
                {
                    try
                    {
                        string path = Path.Combine(HostingEnvironment.MapPath("~/App_Data/")
                                    , ".casino"
                                    , site.DomainID.ToString(CultureInfo.InvariantCulture)
                                    , isMobile ? "recent-winners-mobile.json" : "recent-winners-desktop.json"
                                    );
                        string json = WinFileIO.ReadWithoutLock(path);
                        if (!string.IsNullOrWhiteSpace(json))
                        {
                            cached = JsonConvert.DeserializeObject<List<WinnerInfo>>(json);
                            Dictionary<string, Game> games = CasinoEngineClient.GetGames(site);

                            foreach (WinnerInfo winner in cached)
                            {
                                if (!string.IsNullOrWhiteSpace(winner.GameID))
                                {
                                    Game game;
                                    if (games.TryGetValue(winner.GameID, out game))
                                        winner.Game = game;
                                }
                            }
                            SetCache(cacheKey, cached);
                        }
                    }
                    catch
                    {

                    }
                }
                while (cached == null && (++retry) < 3);

                if (cached == null || cached.Count == 0)
                    throw new Exception(string.Format("Recent winner is not ready[{0}]", cached == null ? "null" : "0"));
            }

            return ObjectHelper.DeepClone<List<WinnerInfo>>(cached);
        }

        public static XDocument GetGameInfo(cmSite site, string gameID, string language, bool useCache = true)
        {
            if (site == null)
                site = SiteManager.Current;

            string filepath = Path.Combine(HostingEnvironment.MapPath("~/App_Data/")
                , site.DistinctName
                , string.Format(CultureInfo.InvariantCulture, "CasinoEngineClient.GetGameInfo.{0}.{1}.xml", gameID, language)
                );

            Func<XDocument> func = () =>
            {
                try
                {
                    if (GetFeedsType(site) == FeedsType.CE2JsonFeeds)
                    {
                        EveryMatrix.Casino.CasinoEngineClient client = new EveryMatrix.Casino.CasinoEngineClient(new EveryMatrix.Casino.CasinoEngineClientOption()
                        {
                            BaseUri = GetBaseUrl(),
                        });

                        string apiUsername = Metadata.Get(site, "/Metadata/Settings.CasinoEngine_OperatorKey", null);
                        List<EveryMatrix.Casino.GameTopic> gameTopics = client.GetGameInfo(apiUsername, gameID, language);
                        if (gameTopics == null)
                            gameTopics = new List<EveryMatrix.Casino.GameTopic>();

                        XDocument xDoc = new XDocument();

                        XElement root = new XElement("xmlData");
                        root.Add(new XElement("result", "Success"));
                        root.Add(new XElement("errorMessage", null));
                        root.Add(new XElement("hashCode", null));

                        XElement topics = new XElement("topics");
                        foreach (EveryMatrix.Casino.GameTopic gameTopic in gameTopics)
                        {
                            XElement topic = new XElement("topic");

                            topic.Add(new XElement("id", gameTopic.ID));
                            topic.Add(new XElement("description", gameTopic.Description));

                            XElement articles = new XElement("articles");
                            foreach (EveryMatrix.Casino.GameArticle gameArticle in gameTopic.Articles)
                            {
                                //XElement article = new XElement("article");
                                articles.Add(new XElement("id", gameArticle.ID));
                                articles.Add(new XElement("title", gameArticle.Title));
                                articles.Add(new XElement("content", gameArticle.Content));
                                //articles.Add(article);
                                break;
                            }
                            topic.Add(articles);
                            topics.Add(topic);
                        }
                        root.Add(topics);
                        xDoc.Add(root);

                        //System.Diagnostics.Debug.WriteLine(xDoc.ToString());

                        string dir = Path.GetDirectoryName(filepath);
                        if (!Directory.Exists(dir))
                            Directory.CreateDirectory(dir);
                        xDoc.Save(filepath);
                        return xDoc;
                    }
                    else
                    {
                        string url = GetGameInfoUrl(site, gameID, language);
                        XDocument xDoc = XDocument.Load(url);

                        if (!string.Equals(xDoc.Root.GetElementValue("result"), "Success", StringComparison.InvariantCultureIgnoreCase))
                            throw new Exception(xDoc.Root.GetElementValue("errorMessage"));

                        string dir = Path.GetDirectoryName(filepath);
                        if (!Directory.Exists(dir))
                            Directory.CreateDirectory(dir);
                        xDoc.Save(filepath);
                        return xDoc;
                    }
                }
                catch (Exception ex)
                {
                    Logger.Exception(ex);
                    return null;
                }
            };

            XDocument cached = null;
            if (!DelayUpdateCache<XDocument>.TryGetValue(filepath, out cached, func, 60 * 30))
            {
                try
                {
                    using (StreamReader sr = new StreamReader(filepath))
                    {
                        return XDocument.Load(sr);
                    }
                }
                catch
                {
                }
            }

            if (cached == null)
                cached = func();

            return cached;
        }

        public static void GetFrequentPlayerPointsAsync(Action<bool, string, CasinoFPPClaimRec> callback)
        {
            if (GetFeedsType(SiteManager.Current) == FeedsType.CE2JsonFeeds)
            {
                string apiUsername = Metadata.Get(SiteManager.Current, "/Metadata/Settings.CasinoEngine_OperatorKey", null);
                string apiPassword = Metadata.Get(SiteManager.Current, "/Metadata/Settings.CasinoEngine_ApiPassword", null);
                string sessionID = CustomProfile.Current.SessionID;
                Task.Run(async () =>
                {
                    try
                    {
                        EveryMatrix.Casino.CasinoEngineClient client = new EveryMatrix.Casino.CasinoEngineClient(new EveryMatrix.Casino.CasinoEngineClientOption()
                        {
                            BaseUri = GetBaseUrl(),
                        });

                        EveryMatrix.Casino.FrequentPlayerPoints fpp = await client.GetFrequentPlayerPointsAsync(apiUsername, apiPassword, sessionID);
                        CasinoFPPClaimRec rec = new CasinoFPPClaimRec();
                        rec.CfgConvertionMinClaimPoints = fpp.ConvertionMinClaimPoints;
                        rec.CfgConvertionAmount = fpp.ConvertionAmount;
                        rec.CfgConvertionPoints = fpp.ConvertionPoints;
                        rec.CfgConvertionCurrency = fpp.ConvertionCurrency;
                        rec.CfgConvertionType = fpp.ConvertionType;
                        rec.Points = fpp.Points;
                        if (callback == null)
                            return;

                        callback(true, null, rec);
                    }
                    catch (Exception ex)
                    {
                        callback(false, ex.Message, null);
                    }

                }).Wait();

                return;
            }

            SynchronizationContext context = AsyncOperationManager.SynchronizationContext;
            try
            {
                AsyncOperationManager.SynchronizationContext = new SynchronizationContext();

                string url = GetFrequentPlayerPointsUrl(SiteManager.Current, CustomProfile.Current.SessionID);

                WebClient client = new WebClient();
                client.DownloadStringCompleted += new DownloadStringCompletedEventHandler(OnGetFrequentPlayerPointsCompleted);
                client.DownloadStringAsync(new Uri(url), callback);
            }
            finally
            {
                AsyncOperationManager.SynchronizationContext = context;
            }
        }


        private static void OnGetFrequentPlayerPointsCompleted(object sender, DownloadStringCompletedEventArgs e)
        {
            WebClient client = sender as WebClient;
            if (client != null)
                client.Dispose();
            Action<bool, string, CasinoFPPClaimRec> callback = e.UserState as Action<bool, string, CasinoFPPClaimRec>;
            if (callback == null)
                return;


            if (e.Error == null && !e.Cancelled && !string.IsNullOrEmpty(e.Result))
            {
                try
                {
                    XDocument xDoc = XDocument.Parse(e.Result);
                    if (!string.Equals(xDoc.Root.GetElementValue("result"), "Success", StringComparison.InvariantCultureIgnoreCase))
                    {
                        callback(false, xDoc.Root.GetElementValue("errorMessage"), null);
                        return;
                    }

                    XElement elem = xDoc.Root.Element("getFrequentPlayerPoints");
                    CasinoFPPClaimRec rec = new CasinoFPPClaimRec();

                    rec.CfgConvertionMinClaimPoints = decimal.Parse(elem.GetElementValue("convertionMinClaimPoints", "0"), CultureInfo.InvariantCulture);
                    rec.CfgConvertionAmount = decimal.Parse(elem.GetElementValue("convertionAmount", "0"), CultureInfo.InvariantCulture);
                    rec.CfgConvertionPoints = decimal.Parse(elem.GetElementValue("convertionPoints", "0"), CultureInfo.InvariantCulture);
                    rec.CfgConvertionCurrency = elem.GetElementValue("convertionCurrency");
                    rec.CfgConvertionType = long.Parse(elem.GetElementValue("convertionType", "1"), CultureInfo.InvariantCulture);
                    rec.Points = decimal.Parse(elem.GetElementValue("points", "0"), CultureInfo.InvariantCulture);

                    callback(true, null, rec);
                }
                catch (Exception ex)
                {
                    Logger.Exception(ex);
                    try
                    {
                        callback(false, ex.Message, null);
                    }
                    catch
                    {
                    }
                }
            }


        }


        public static void ClaimFrequentPlayerPointsAsync(Action<bool, string, CasinoFPPClaimRec> callback)
        {
            if (GetFeedsType(SiteManager.Current) == FeedsType.CE2JsonFeeds)
            {
                string apiUsername = Metadata.Get(SiteManager.Current, "/Metadata/Settings.CasinoEngine_OperatorKey", null);
                string apiPassword = Metadata.Get(SiteManager.Current, "/Metadata/Settings.CasinoEngine_ApiPassword", null);
                string sessionID = CustomProfile.Current.SessionID;
                Task.Run(async () =>
                {
                    try
                    {
                        EveryMatrix.Casino.CasinoEngineClient client = new EveryMatrix.Casino.CasinoEngineClient(new EveryMatrix.Casino.CasinoEngineClientOption()
                        {
                            BaseUri = GetBaseUrl(),
                        });

                        EveryMatrix.Casino.ClaimedFrequentPlayerPoints fpp = await client.ClaimFrequentPlayerPointsAsync(apiUsername, apiPassword, sessionID);

                        CasinoFPPClaimRec rec = new CasinoFPPClaimRec();

                        rec.CfgConvertionMinClaimPoints = fpp.ConvertionMinClaimPoints;
                        rec.CfgConvertionAmount = fpp.ConvertionAmount;
                        rec.CfgConvertionPoints = fpp.ConvertionPoints;
                        rec.CfgConvertionCurrency = fpp.ConvertionCurrency;
                        rec.CfgConvertionType = fpp.ConvertionType;
                        rec.Converted = fpp.Converted;
                        rec.Remainder = fpp.Remainder;
                        rec.RewardAmount = fpp.RewardAmount;
                        rec.RewardCurrency = fpp.RewardCurrency;

                        callback(true, null, rec);
                    }
                    catch (Exception ex)
                    {
                        callback(false, ex.Message, null);
                    }

                }).Wait();

                return;
            }

            SynchronizationContext context = AsyncOperationManager.SynchronizationContext;
            try
            {
                AsyncOperationManager.SynchronizationContext = new SynchronizationContext();

                string url = ClaimFrequentPlayerPointsUrl(SiteManager.Current, CustomProfile.Current.SessionID);

                WebClient client = new WebClient();
                client.DownloadStringCompleted += new DownloadStringCompletedEventHandler(OnClaimFrequentPlayerPointsCompleted);
                client.DownloadStringAsync(new Uri(url), callback);
            }
            finally
            {
                AsyncOperationManager.SynchronizationContext = context;
            }
        }


        private static void OnClaimFrequentPlayerPointsCompleted(object sender, DownloadStringCompletedEventArgs e)
        {
            WebClient client = sender as WebClient;
            if (client != null)
                client.Dispose();
            Action<bool, string, CasinoFPPClaimRec> callback = e.UserState as Action<bool, string, CasinoFPPClaimRec>;
            if (callback == null)
                return;

            if (e.Error == null && !e.Cancelled && !string.IsNullOrEmpty(e.Result))
            {
                try
                {
                    XDocument xDoc = XDocument.Parse(e.Result);
                    if (!string.Equals(xDoc.Root.GetElementValue("result"), "Success", StringComparison.InvariantCultureIgnoreCase))
                    {
                        callback(false, xDoc.Root.GetElementValue("errorMessage"), null);
                        return;
                    }

                    XElement elem = xDoc.Root.Element("claimFrequentPlayerPoints");
                    CasinoFPPClaimRec rec = new CasinoFPPClaimRec();

                    rec.CfgConvertionMinClaimPoints = decimal.Parse(elem.GetElementValue("convertionMinClaimPoints", "0"), CultureInfo.InvariantCulture);
                    rec.CfgConvertionAmount = decimal.Parse(elem.GetElementValue("convertionAmount", "0"), CultureInfo.InvariantCulture);
                    rec.CfgConvertionPoints = decimal.Parse(elem.GetElementValue("convertionPoints", "0"), CultureInfo.InvariantCulture);
                    rec.CfgConvertionCurrency = elem.GetElementValue("convertionCurrency");
                    rec.CfgConvertionType = long.Parse(elem.GetElementValue("convertionType", "1"), CultureInfo.InvariantCulture);
                    rec.Converted = decimal.Parse(elem.GetElementValue("converted", "0"), CultureInfo.InvariantCulture);
                    rec.Remainder = decimal.Parse(elem.GetElementValue("remainder", "0"), CultureInfo.InvariantCulture);
                    rec.RewardAmount = decimal.Parse(elem.GetElementValue("rewardAmount", "0"), CultureInfo.InvariantCulture);
                    rec.RewardCurrency = elem.GetElementValue("rewardCurrency");

                    callback(true, null, rec);
                }
                catch (Exception ex)
                {
                    Logger.Exception(ex);
                }
            }
        }


        public static List<ContentProvider> GetContentProviders(cmSite site = null, bool useCache = true, bool forceUpdate = false)
        {
            if (site == null)
                site = SiteManager.Current;

            string cacheKey = string.Format(CacheKeyFormat.ContentProviders, site.DomainID);
            List<ContentProvider> cached = HttpRuntime.Cache[cacheKey] as List<ContentProvider>;
            if (cached == null)
            {
                try
                {
                    string path = Path.Combine(HostingEnvironment.MapPath("~/App_Data/")
                                , ".casino"
                                , site.DomainID.ToString(CultureInfo.InvariantCulture)
                                , "content-providers.json"
                                );
                    string json = WinFileIO.ReadWithoutLock(path);
                    if (!string.IsNullOrWhiteSpace(json))
                    {
                        cached = JsonConvert.DeserializeObject<List<ContentProvider>>(json);
                        SetCache(cacheKey, cached);
                    }
                }
                catch
                {
                    cached = new List<ContentProvider>();
                }
            }

            return cached;
        }


        public static List<Game> GetUserRecommendedGames(Platform platForm, cmSite site = null, bool useCache = true)
        {
            if (site == null)
                site = SiteManager.Current;

            string sessionID = CustomProfile.Current.SessionID;
            string filepath = Path.Combine(HostingEnvironment.MapPath("~/App_Data/")
                , site.DistinctName
                , string.Format("CasinoEngineClient.GetUserRecommendedGames.{0}.{1}.dat", CustomProfile.Current.UserID, platForm.ToString())
                );
            Func<List<Game>> func = () =>
            {
                try
                {
                    List<Game> games = new List<Game>();

                    if (GetFeedsType(site) == FeedsType.CE2JsonFeeds)
                    {
                        EveryMatrix.Casino.CasinoEngineClient client = new EveryMatrix.Casino.CasinoEngineClient(new EveryMatrix.Casino.CasinoEngineClientOption()
                        {
                            BaseUri = GetBaseUrl(),
                        });

                        string apiUsername = Metadata.Get(site, "/Metadata/Settings.CasinoEngine_OperatorKey", null);

                        List<EveryMatrix.Casino.RecommendedGame> recommendedGames = client.GetRecommendedGamesByUser(apiUsername, sessionID, platForm.ToString(), true);
                        var allGames = GetGames(site);
                        foreach (EveryMatrix.Casino.RecommendedGame recommendedGame in recommendedGames)
                        {
                            Game game;
                            if (allGames.TryGetValue(recommendedGame.ID.ToString(CultureInfo.InvariantCulture), out game))
                            {
                                games.Add(game);
                            }
                        }
                    }
                    else
                    {
                        XDocument xDoc = XDocument.Load(GetUserRecommendedGamesUrl(site, platForm));
                        IEnumerable<XElement> elements = xDoc.Root.Element("games").Elements("game");
                        var allGames = GetGames(site);
                        foreach (var element in elements)
                        {
                            if (element.Element("id") != null)
                            {
                                var gameId = element.Element("id").Value;
                                Game game;
                                if (allGames.TryGetValue(gameId, out game))
                                {
                                    games.Add(game);
                                }
                                else
                                {
                                    game = allGames.Values.FirstOrDefault(g => g.ID.Equals(gameId, StringComparison.InvariantCultureIgnoreCase));
                                    if (game != null)
                                        games.Add(game);

                                }
                            }
                        }
                    }

                    return games;
                }
                catch (Exception ex)
                {
                    Logger.Exception(ex);
                    return new List<Game>();
                }
            };

            List<Game> cached;
            if (!DelayUpdateCache<List<Game>>.TryGetValue(filepath, out cached, func, 30 * 60))
            {
                cached = func();
            }
            //if (cached.Count == 0)
            //    throw new Exception("Use rRecommended Games is not ready!");

            return cached;
        }

        public static List<Game> GetGameRecommendedGames(Platform platForm, IEnumerable<string> gameIDs, cmSite site = null, bool useCache = true)
        {
            if (site == null)
                site = SiteManager.Current;

            string filepath = Path.Combine(HostingEnvironment.MapPath("~/App_Data/")
                , site.DistinctName
                , string.Format("CasinoEngineClient.GetGameRecommendedGames.{0}.{1}.{2}.{3}.dat"
                    , string.Join(",", gameIDs)
                    , platForm.ToString()
                    , CustomProfile.Current.UserCountryID
                    , CustomProfile.Current.IpCountryID)
                );

            string userCountryCode = null;
            string ipCountryCode = null;
            List<CountryInfo> countries = CountryManager.GetAllCountries(site.DistinctName);
            CountryInfo country = countries.FirstOrDefault(c => c.InternalID == CustomProfile.Current.UserCountryID);
            if (country != null)
                userCountryCode = country.ISO_3166_Alpha2Code;
            country = countries.FirstOrDefault(c => c.InternalID == CustomProfile.Current.IpCountryID);
            if (country != null)
                ipCountryCode = country.ISO_3166_Alpha2Code;
            if (userCountryCode == null)
                userCountryCode = ipCountryCode;

            Func<List<Game>> func = () =>
            {
                try
                {
                    List<Game> games = new List<Game>();

                    if (GetFeedsType(site) == FeedsType.CE2JsonFeeds)
                    {
                        EveryMatrix.Casino.CasinoEngineClient client = new EveryMatrix.Casino.CasinoEngineClient(new EveryMatrix.Casino.CasinoEngineClientOption()
                        {
                            BaseUri = GetBaseUrl(),
                        });

                        string apiUsername = Metadata.Get(site, "/Metadata/Settings.CasinoEngine_OperatorKey", null);

                        List<EveryMatrix.Casino.RecommendedGame> recommendedGames = client.GetRecommendedGamesByGame(apiUsername, gameIDs.ToArray(), platForm.ToString(), userCountryCode, ipCountryCode, true);
                        var allGames = GetGames(site);
                        foreach (EveryMatrix.Casino.RecommendedGame recommendedGame in recommendedGames)
                        {
                            Game game;
                            if (allGames.TryGetValue(recommendedGame.ID.ToString(CultureInfo.InvariantCulture), out game))
                            {
                                games.Add(game);
                            }
                        }
                    }
                    else
                    {
                        XDocument xDoc = XDocument.Load(GetGameRecommendedGamesUrl(site, gameIDs, platForm));
                        IEnumerable<XElement> elements = xDoc.Root.Element("games").Elements("game");
                        var allGames = GetGames(site);
                        foreach (var element in elements)
                        {
                            if (element.Element("id") != null)
                            {
                                var gameId = element.Element("id").Value;
                                Game game;
                                if (allGames.TryGetValue(gameId, out game))
                                {
                                    games.Add(game);
                                }
                                else
                                {
                                    game = allGames.Values.FirstOrDefault(g => g.ID.Equals(gameId, StringComparison.InvariantCultureIgnoreCase));
                                    if (game != null)
                                        games.Add(game);

                                }
                            }
                        }
                    }

                    return games;
                }
                catch (Exception ex)
                {
                    Logger.Exception(ex);
                    return new List<Game>();
                }
            };

            List<Game> cached;
            if (!DelayUpdateCache<List<Game>>.TryGetValue(filepath, out cached, func, 30 * 60))
            {
                cached = func();
            }
            //if (cached.Count == 0)
            //    throw new Exception("Use rRecommended Games is not ready!");

            return cached;
        }

        public static List<Game> GetPopularityGamesInCountry(Platform platForm, int countryID, cmSite site = null, bool useCache = true)
        {
            if (site == null)
                site = SiteManager.Current;

            string cacheKey = string.Format(CacheKeyFormat.GamePopularities, site.DomainID);
            List<GamePopularity> cached = HttpRuntime.Cache[cacheKey] as List<GamePopularity>;
            if (cached == null)
            {
                try
                {
                    string path = Path.Combine(HostingEnvironment.MapPath("~/App_Data/")
                                , ".casino"
                                , site.DomainID.ToString(CultureInfo.InvariantCulture)
                                , "game-popularities.json"
                                );
                    string json = WinFileIO.ReadWithoutLock(path);
                    if (!string.IsNullOrWhiteSpace(json))
                    {
                        cached = JsonConvert.DeserializeObject<List<GamePopularity>>(json);
                        SetCache(cacheKey, cached);
                    }
                }
                catch
                {
                    cached = new List<GamePopularity>();
                }
            }

            List<Game> games = new List<Game>();
            if (cached.Count == 0)
                return games;

            var allGames = GetGames(site);

            foreach (var gp in cached)
            {
                if (gp.IsAvaliable(platForm, FindCountryCode(countryID)))
                {
                    Game game;
                    if (allGames.TryGetValue(gp.GameID, out game))
                    {
                        games.Add(game);
                    }
                    else
                    {
                        game = allGames.Values.FirstOrDefault(g => g.ID.Equals(gp.GameID, StringComparison.InvariantCultureIgnoreCase));
                        if (game != null)
                            games.Add(game);
                    }
                }
            }
            return games;
        }

        #region clear cache
        public static void ClearGamesCache(int siteID)
        {
            cmSite site = SiteManager.GetSites().First(s => s.ID == siteID);
            string baseDir = Path.Combine(HostingEnvironment.MapPath("~/App_Data/")
                , site.DistinctName
                );

            if (!Directory.Exists(baseDir))
                return;

            //string[] files = Directory.GetFiles(baseDir, "CasinoEngineClient.*", SearchOption.TopDirectoryOnly);
            //foreach (string file in files)
            //{
            //    HttpRuntime.Cache.Remove(file);
            //}

            List<string> keys = new List<string>();
            string prefix = Path.Combine(baseDir, "CasinoEngineClient.");
            IDictionaryEnumerator enumerator = HttpRuntime.Cache.GetEnumerator();
            while (enumerator.MoveNext())
            {
                string key = (string)enumerator.Key;
                object value = enumerator.Value;
                if (key.StartsWith(prefix))
                    keys.Add(key);
            }

            foreach (string key in keys)
                HttpRuntime.Cache.Remove(key);

            CasinoEngineClient.GetVendors(site, forceUpdate: true);
            CasinoEngineClient.GetContentProviders(site, forceUpdate: true);
            CasinoEngineClient.GetGames(site, forceUpdate: true);
            CasinoEngineClient.GetLiveCasinoTables(site, forceUpdate: true);
            CasinoEngineClient.GetJackpots(site, forceUpdate: true);
            CasinoEngineClient.GetTopWinners(site, true, forceUpdate: true);
            CasinoEngineClient.GetTopWinners(site, false, forceUpdate: true);
            CasinoEngineClient.GetRecentWinners(site, true, forceUpdate: true);
            CasinoEngineClient.GetRecentWinners(site, false, forceUpdate: true);
            CasinoEngineClient.ClearGameInfoCache(site);
        }

        public static void ClearGameMgrCache(int siteID)
        {
            foreach (DictionaryEntry entry in HttpRuntime.Cache)
            {
                string key = entry.Key as string;
                if (key.StartsWith("GameMgr.", StringComparison.InvariantCultureIgnoreCase))
                {
                    HttpRuntime.Cache.Remove(key);
                }
            }
        }

        public static void ClearJackpotsCache(int siteID)
        {
            foreach (DictionaryEntry entry in HttpRuntime.Cache)
            {
                string key = entry.Key as string;
                if (key.StartsWith("GameMgr.GetOriginalJackpots", StringComparison.InvariantCultureIgnoreCase))
                {
                    HttpRuntime.Cache.Remove(key);
                }
            }
        }

        public static void ClearLiveCasinoTablesCache(int siteID)
        {
            foreach (DictionaryEntry entry in HttpRuntime.Cache)
            {
                string key = entry.Key as string;
                if (key.StartsWith("GameMgr.GetLiveCasinoTables", StringComparison.InvariantCultureIgnoreCase))
                {
                    HttpRuntime.Cache.Remove(key);
                }
            }
        }

        public static void ClearGameInfoCache(cmSite site)
        {
            if (site == null)
                site = SiteManager.Current;

            string filepath = Path.Combine(HostingEnvironment.MapPath("~/App_Data/")
                , site.DistinctName
                , "CasinoEngineClient.GetGameInfo."
                );
            DelayUpdateCache<XDocument>.SetExpiredByPrefix(filepath);
        }
        #endregion

        static void SetCache(string key, object value)
        {
            HttpRuntime.Cache.Insert(key
                , value
                , null
                , Cache.NoAbsoluteExpiration
                , Cache.NoSlidingExpiration
                , CacheItemPriority.NotRemovable
                , null
                );
        }


    }
}